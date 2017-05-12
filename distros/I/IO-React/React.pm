
require 5.6.0;
package IO::React;
use strict;
use Carp;
use IO::File;

## Module Version
our $VERSION = 1.03;


### Constructor

sub new ($) {
  my ($class, $handle) = @_;
  return bless {
    Handle   => $handle,
    Display  => 1,
    Wait     => undef,
    Timeout  => sub { },
    EOF      => sub { },
  }, $class;
}


### Methods

# Set the wait interval
sub set_wait ($) {
  my ($self, $wait) = @_;
  croak "non-numeric wait value: $wait"
      if ( defined $wait and $wait !~ /^\d+$/ );
  $self->{Wait} = $wait;
}

# Set the timeout behaviour
sub set_timeout ($) {
  my ($self, $timeout) = @_;
  croak "non-numeric timeout callback: $timeout"
      if ( defined $timeout and "$timeout" !~ /^CODE/ );
  $self->{Timeout} = $timeout ? $timeout : sub { };
}

# Set the eof behaviour
sub set_eof ($) {
  my ($self, $eof) = @_;
  croak "non-numeric eof callback: $eof"
      if ( defined $eof and "$eof" !~ /^CODE/ );
  $self->{EOF} = $eof ? $eof : sub { };
}

# Control the display
sub set_display ($) {
  my ($self, $display) = @_;
  $self->{Display} = $display ? 1 : 0;
}

# Write to the handle
sub write ($$) {
  my ($self, $data) = @_;
  my $handle = $self->{Handle};
  return syswrite($handle, $data, length($data));
}

# React to output matching given patterns
sub react ($) {
  my ($self, @p) = @_;
  my %p = @p;
  my $handle = $self->{Handle};

  # Options
  my $wait    = ( exists $p{WAIT} )    ? $p{WAIT}    : $self->{Wait};
  my $timeout = ( exists $p{TIMEOUT} ) ? $p{TIMEOUT} : $self->{Timeout};
  my $eof     = ( exists $p{EOF} )     ? $p{EOF}     : $self->{EOF};
  delete $p{WAIT};
  delete $p{TIMEOUT};
  delete $p{EOF};
  croak "non-numeric wait value: $wait"
      if ( defined $wait and $wait !~ /^\d+$/ );

  my $start    = time;
  my $timeleft = $wait;
  my $text     = '';
  my $buf      = '';
  my $rin      = '';
  vec($rin, $handle->fileno, 1) = 1; # Bit vector of handles to select

 ReadData:
  my $nfound = select(my $rout=$rin, undef, undef, $timeleft);
  croak "select failed: $!" if ( $nfound < 0 );
  if ( $nfound == 0 ) {
    # Timeout can set a new time limit
    $timeleft = $timeout->();
    croak "TIMEOUT function returned non-numeric value: $timeleft"
	if ( defined $timeleft and $timeleft !~ /^\d+$/ );
    goto ReadData if defined $timeleft;
    return;
  }

  my $nread = sysread($handle, $buf, 1024);
  croak "sysread failed: $!" if ( $nread < 0 );
  if ( $nread == 0 ) {
    # End of file
    $eof->();
    return;
  }

  print $buf if $self->{Display};

  $text .= $buf;		# Accumuate text for matching

  # Check all the patterns
  foreach ( keys %p ) {
    if ( $text =~ /$_/m ) {
      my $f = $p{$_};
      $f->($handle, $text);
      return 1;
    }
  }

  # If there is no timeout, just go back to waiting
  goto ReadData unless defined $timeleft;

  # Otherwise, adjust timer for the time that has passed
  $timeleft = $wait - ( time - $start );
  $timeleft = 0 if ( $timeleft < 0 ); # Must not be negative
  goto ReadData;
}

1;

__END__

=head1 NAME

IO::React - Interaction with an IO::Handle

=head1 SYNOPSIS

  use IO::React;

  my $r = new IO::React($fh);

  $r->set_wait(30);	# Seconds
  $r->set_timeout(sub { ... });
  $r->set_eof(sub { ... });
  $r->set_display(1);	# Boolean

  $r->write("...", ...);

  $r->react('WAIT'     => sub { ... },
	    'TIMEOUT'  => sub { ... },
	    'EOF'      => sub { ... },
	    'pattern1' => sub { ... },
	    'pattern2' => sub { ... },
	    ...);

=head1 DESCRIPTION

C<IO::React> provides an expect-like interface for interacting with
whatever may be connected to a handle. The main routine is the
C<react> method, which calls subroutines based on matching patterns
provided as arguments.

There are four methods for controlling the default behaviour of an
C<IO::React> object.

The C<set_wait> method controls the default waiting period for
C<react> to read data that matches one of the patterns it is looking
for.

The C<set_timeout> method sets a subroutine to be called when the
waiting period for C<react> expires. If the timeout subroutine returns
a defined value, that value will be used as a new waiting period.

The C<set_eof> method sets a subroutine to be called when C<react>
reaches the end of file on the handle it is reading from.

The C<set_display> method controls whether or not C<react> prints the
data it reads to the default output handle.

Because C<IO::React> uses the C<select> perl function, it is not safe
to use buffered io routines on the handle it is processing. For
convienience, C<IO::React> provides the <write> method to call
C<syswrite> appropriately on the handle.

=head1 EXAMPLES

=head2 Getting a directory listing via telnet

This is a sample program that would login to a system using B<telnet>
and run B<ls>.

  use IO::React;
  use Proc::Spawn;

  my $Prompt   = "\\\$";
  my $Account  = "XXX";
  my $Password = "XXX";

  my ($pid, $fh) = spawn_pty("telnet localhost");

  my $react = new IO::React($fh);
  $react->set_display(1);
  $react->set_wait(10);

  # React to login prompt
  $react->react(
    WAIT      => 30,
    'ogin:'   => sub { $react->write("$Account\n") },
    'refused' => sub { print "Server not responding\n"; exit 1 }
  ) || die "React Failed";

  # React to password prompt
  $react->react(
    'word:'  => sub { $react->write("$Password\n") }
  ) || die "React Failed";

  # React to failure or shell prompt
  $react->react(
    'incorrect' => sub { print "\nWrong Account/Password\n"; exit 1 },
    $Prompt     => sub { $react->write("ls\n") },
  );

  # React to shell prompt
  $react->react(
    WAIT    => 60,
    $Prompt => sub { $react->write("exit\n"); },
  );

=head1 AUTHOR

John Redford, John.Redford@fmr.com

=head1 SEE ALSO

IO::Handle, Proc::Spawn

=cut
