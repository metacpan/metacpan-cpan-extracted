package IO::Pager;
our $VERSION = "1.01"; #Untouched since 1.00

use 5.008; #At least, for decent perlio, and other modernisms
use strict;
use base qw( Tie::Handle );
use Env qw( PAGER );
use File::Spec;
use PerlIO;
use Symbol;

use overload '+' => "PID", bool=> "PID";

our $SIGPIPE;
my $oldPAGER = $PAGER;

sub find_pager {
  # Return the name (or path) of a pager that IO::Pager can use
  my $io_pager;

  #Permit explicit use of pure perl pager
  local $_ = 'IO::Pager::less';
  return $_ if $_[0] eq $_ or $PAGER eq $_;

  # Use File::Which if available (strongly recommended)
  my $which = eval { require File::Which };

  # Look for pager in PAGER first
  if ($PAGER) {
    # Strip arguments e.g. 'less --quiet'
    my ($pager, @options) = (split ' ', $PAGER);
    $pager = _check_pagers([$pager], $which);
    $io_pager = join ' ', ($pager, @options) if defined $pager;
  }

  # Then search pager amongst usual suspects
  if (not defined $io_pager) {
    my @pagers = ('/etc/alternatives/pager',
		  '/usr/local/bin/less', '/usr/bin/less', '/usr/bin/more');
    $io_pager = _check_pagers(\@pagers, $which) 
  }

  # Then check PATH for other pagers
  if ( (not defined $io_pager) && $which ) {
    my @pagers = ('less', 'most', 'w3m', 'lv', 'pg', 'more');
    $io_pager = _check_pagers(\@pagers, $which );
  }

  # If all else fails, default to more (actually IO::Pager::less first)
  $io_pager ||= 'more';

  return $io_pager;
}

sub _check_pagers {
  my ($pagers, $which) = @_;
  # Return the first pager in the list that is usable. For each given pager, 
  # given a pager name, try to finds its full path with File::Which if possible.
  # Given a pager path, verify that it exists.
  my $io_pager = undef;
  for my $pager (@$pagers) {
    # Get full path
    my $loc;
    if ( $which && (not File::Spec->file_name_is_absolute($pager)) ) {
      $loc = File::Which::which($pager);
    } else {
      $loc = $pager;
    }
    # Test that full path is valid (some platforms don't do -x so we use -e)
    if ( defined($loc) && (-e $loc) ) {
      $io_pager = $loc;
      last;
    }
  }
  return $io_pager;
}

#Should have this as first block for clarity, but not with its use of a sub :-/
BEGIN { # Set the $ENV{PAGER} to something reasonable
  $PAGER = find_pager();
  
  if( ($PAGER =~ 'more' and $oldPAGER ne 'more') or
       $PAGER eq 'IO::Pager::less' ){
    my $io_pager = $PAGER;
    eval "use IO::Pager::less";
    $PAGER = $io_pager if $@ or not defined $PAGER;
  }
}


#Factory
sub open(*;$@) { # FH, [MODE], [CLASS]
  my $args = {procedural=>1};
  $args->{mode} = splice(@_, 1, 1) if scalar(@_) == 3;
  $args->{subclass} = pop if scalar(@_) == 2;
  &new(undef, @_, $args);
}

#Alternate entrance: drop class but leave FH, subclass
sub new(*;$@) { # FH, [MODE], [CLASS]
  shift;

  my %args;
  if( ref($_[-1]) eq 'HASH' ){
    %args = %{pop()};
    #warn "REMAINDER? (@_)", scalar @_;
    push(@_, $args{procedural});
  }
  elsif( defined($_[1]) ){
    $args{mode} = splice(@_, 1, 1) if $_[1] =~ /^:/;
    $args{subclass} = pop if exists($_[1]);
  }

  #Leave filehandle in @_ for pass by reference to allow gensym
  $args{subclass} ||= 'IO::Pager::Unbuffered';
  $args{subclass} =~ s/^(?!IO::Pager::)/IO::Pager::/;
  eval "require $args{subclass}" or die "Could not load $args{subclass}: $@\n";
  my $token = $args{subclass}->new(@_);

  if( defined($args{mode}) ){
    $args{mode} =~ s/^\|-//;
    $token->BINMODE($args{mode});
  }
  return $token;
}


sub _init{ # CLASS, [FH] ## Note reversal of order due to CLASS from new()
  #Assign by reference if empty scalar given as filehandle
  $_[1] = gensym() if !defined($_[1]);

  no strict 'refs';
  $_[1] ||= *{select()};

  # Are we on a TTY? STDOUT & STDERR are separately bound
  if ( defined( my $FHn = fileno($_[1]) ) ) {
    if ( $FHn == fileno(STDOUT) ) {
      die '!TTY' unless -t $_[1];
    }
    if ( $FHn == fileno(STDERR) ) {
      die '!TTY' unless -t $_[1];
    }
  }

  #XXX This allows us to have multiple pseudo-STDOUT
  #return 0 unless -t STDOUT;

  return ($_[0], $_[1]);
}


# Methods required for implementing a tied filehandle class

sub TIEHANDLE {
  my ($class, $tied_fh) = @_;
  unless ( $PAGER ){
    die "The PAGER environment variable is not defined, you may need to set it manually.";
  }
  my($real_fh, $child, $dupe_fh);
# XXX What about localized GLOBs?!
#  if( $tied_fh =~ /\*(?:\w+::)?STD(?:OUT|ERR)$/ ){
#      open($dupe_fh, '>&', $tied_fh) or warn "Unable to dupe $tied_fh";
#  }
  if ( $child = CORE::open($real_fh, '|-', $PAGER) ){
    my @oLayers = PerlIO::get_layers($tied_fh, details=>1, output=>1);
    my $layers = '';
    for(my $i=0;$i<$#oLayers;$i+=3){
      #An extra base layer requires more keystrokes to exit
      next if $oLayers[$i] =~ /unix|stdio/ && !defined($oLayers[+1]);

      $layers .= ":$oLayers[$i]";
      $layers .=  '(' . ($oLayers[$i+1]) . ')' if defined($oLayers[$i+1]);
    }
    CORE::binmode($real_fh, $layers);
  }
  else{
    die "Could not pipe to PAGER ('$PAGER'): $!\n";
  }
  return bless {
                'real_fh' => $real_fh,
#		'dupe_fh' => $dupe_fh,
		'tied_fh' => "$tied_fh", #Avoid self-reference leak
                'child'   => $child,
		'pager'   => $PAGER,
               }, $class;
}


sub BINMODE {
  my ($self, $layer) = @_;
  if( $layer =~ /^:LOG\((>{0,2})(.*)\)$/ ){
    CORE::open($self->{LOG}, $1||'>', $2||"$$.log") or die $!;
  }
  else{
    CORE::binmode($self->{real_fh}, $layer||':raw');
  }
}

sub WNOHANG();
sub EOF {
  my $self = shift;

  unless( defined($SIGPIPE) ){
    eval 'use POSIX ":sys_wait_h";';
    $SIGPIPE = 0;
  }

  $SIG{PIPE} = sub { $SIGPIPE = 1 unless $ENV{IP_EOF};
		     CORE::close($self->{real_fh});
		     waitpid($self->{child}, WNOHANG);
		     CORE::open($self->{real_fh}, '>&1');

		     close($self->{LOG});
		   };
  return $SIGPIPE;
}


sub PRINT {
  my ($self, @args) = @_;
  CORE::print {$self->{LOG}} @args if exists($self->{LOG});
  CORE::print {$self->{real_fh}} @args or die "Could not print to PAGER: $!\n";
}

sub PRINTF {
  my ($self, $format, @args) = @_;
  $self->PRINT(sprintf($format, @args));
}

sub say {
  my ($self, @args) = @_;
  $args[-1] .= "\n";
  $self->PRINT(@args);
}

sub WRITE {
  my ($self, $scalar, $length, $offset) = @_;
  $self->PRINT(substr($scalar, $offset||0, $length));
}


sub TELL {
  #Buffered classes provide their own, and others may use this in another way
  return undef;
}


sub FILENO {
  CORE::fileno($_[0]->{real_fh});
}

sub CLOSE {
  my ($self) = @_;
  CORE::close($self->{real_fh});
#  untie($self->{tied_fh});
#  *{$self->{tied_fh}} = *{$self->{dupe_fh}};
}

*DESTROY = \&CLOSE;


#Non-IO methods
sub PID{
  my ($self) = @_;
  return $self->{child};
}


#Provide lowercase aliases for accessors
foreach my $method ( qw(BINMODE CLOSE EOF PRINT PRINTF TELL WRITE PID) ){
  no strict 'refs';
  *{lc($method)} = \&{$method};
}


1;

__END__
=pod

=head1 NAME

IO::Pager - Select a pager and pipe text to it if destination is a TTY

=head1 SYNOPSIS

  # Select an appropriate pager and set the PAGER environment variable
  use IO::Pager;

  # TIMTOWTDI Object-oriented
  {
    # open()                           # Use all the defaults.
    my $object = new IO::Pager;

    # open FILEHANDLE                  # Unbuffered is default subclass
    my $object = new IO::Pager *STDOUT;

    # open FILEHANDLE,EXPR             # Specify subclass
    my $object = new IO::Pager *STDOUT,  'Unbuffered';

    # Direct subclass instantiation    # FH is optional
    use IO::Pager::Unbuffered;
    my $object = new IO::Pager::Unbuffered  *STDOUT;


    $object->print("OO shiny...\n") while 1;
    print "Some other text sent to STODUT, perhaps from a foreign routine."

    # $object passes out of scope and filehandle is automagically closed
  }

  # TIMTOWTDI Procedural
  {
    # open FILEHANDLE                    # Unbuffered is default subclass
    my $token = IO::Pager::open *STDOUT;

    # open FILEHANDLE,EXPR               # Specify subclass
    my $token = IO::Pager::open *STDOUT,  'Unbuffered';

    # open FILEHANDLE,MODE,EXPR          # En lieu of a separate binmode()
    my $token = IO::Pager::open *STDOUT, '|-:utf8', 'Unbuffered';


    print <<"  HEREDOC" ;
    ...
    A bunch of text later
    HEREDOC

    # $token passes out of scope and filehandle is automagically closed
  }

  {
    # You can also use scalar filehandles...
    my $token = IO::Pager::open(my $FH) or warn($!); XXX
    print $FH "No globs or barewords for us thanks!\n" while 1;
  }


=head1 DESCRIPTION

IO::Pager can be used to locate an available pager and set the I<PAGER>
environment variable (see L</NOTES>). It is also a factory for creating
I/O objects such as L<IO::Pager::Buffered> and L<IO::Pager::Unbuffered>.

IO::Pager subclasses are designed to programmatically decide whether
or not to pipe a filehandle's output to a program specified in I<PAGER>.
Subclasses may implement only the IO handle methods desired and inherit
the remainder of those outlined below from IO::Pager. For anything else,
YMMV. See the appropriate subclass for implementation specific details.

=head1 METHODS

=head2 new( FILEHANDLE, [MODE], [SUBCLASS] )

Almost identical to open, except that you will get an L<IO::Handle>
back if there's no TTY to allow for IO::Pager-agnostic programming.

=head2 open( FILEHANDLE, [MODE], [SUBCLASS] )

Instantiate a new IO::Pager, which will paginate output sent to
FILEHANDLE if interacting with a TTY.

Save the return value to check for errors, use as an object,
or for implict close of OO handles when the variable passes out of scope.

=over

=item FILEHANDLE

You may provide a glob or scalar.

Defaults to currently select()-ed F<FILEHANDLE>.

=item SUBCLASS

Specifies which variety of IO::Pager to create.
This accepts fully qualified packages I<IO::Pager::Buffered>,
or simply the third portion of the package name I<Buffered> for brevity.

Defaults to L<IO::Pager::Unbuffered>.

Returns false and sets I<$!> on failure, same as perl's C<open>.

=back

=head2 PID

Call this method on the token returned by C<open> to get the process
identifier for the child process i.e; pager; if you need to perform
some long term process management e.g; perl's C<waitpid>

You can also access the PID by numifying the instantiation token like so:

  my $child = $token+0;

=head2 close( FILEHANDLE )

Explicitly close the filehandle, this stops any redirection of output
on FILEHANDLE that may have been warranted.

I<This does not default to the current filehandle>.

Alternatively, you may rely upon the implicit close of lexical handles
as they pass out of scope e.g;

  {
     IO::Pager::open local *RIBBIT;
     print RIBBIT "No toad sexing allowed";
     ...
  }
  #The filehandle is closed to additional output

  {
     my $token = new IO::Pager::Buffered;
     $token->print("I like trains");
     ...
  }
  #The string "I like trains" is flushed to the pager, and the handle closed

=head2 binmode( FILEHANDLE, [LAYER] )

Used to set the I/O layer a.k.a. discipline of a filehandle,
such as C<':utf8'> for UTF-8 encoding.

=head3 :LOG([>>FILE])

IO::Pager implements a pseudo-IO-layer for capturing output and sending it
to a file, similar to L<tee(1)>. Although it is limited to one file, this
feature is pure-perl and adds no dependencies.

You may indicate what file to store in parentheses, otherwise the default is
C<$$.log>. You may also use an implicit (no indicator) or explicit (I<E<gt>>)
indicator to overwrite an existing file, or an explicit (I<E<gt>E<gt>>) for
appending to a log file. For example:

    binmode(*STDOUT, ':LOG(clobber.log)');
    ...
    $STDOUT->binmode(':LOG(>>noclobber.log)');

For full tee-style support, use L<PerlIO::Util> like so:

    binmode(*STDOUT, ":tee(TH)");
    #OR
    $STDOUT->binmode(':tee(TH)');

=head2 eof( FILEHANDLE )

Used in the eval-until-eof idiom below, I<IO::Pager> will handle broken pipes
from deceased children for you in one of two ways. If I<$ENV{IP_EOF}> is
false then program flow will pass out of the loop on I<SIGPIPE>, this is the
default. If the variable is true, then the program continues running with
output for the previously paged filehandle directed to the I<STDOUT> stream;
more accurately, the filehandle is reopened to file descriptor 1.

  use IO::Pager::Page; #or whichever you prefer;
  ...
  eval{
    say "Producing prodigious portions of product";
    ...
  } until( eof(*STDOUT) );
  print "Cleaning up after our child before terminating."

If using eof() with L<less>, especially when IP_EOF is set, you may want to
use the I<--no-init> option by setting I<$ENV{IP_EOF}='X'> to prevent the
paged output from being erased when the pager exits.

=head2 fileno( FILEHANDLE )

Return the filehandle number of the write-only pipe to the pager.

=head2 print( FILEHANDLE LIST )

print() to the filehandle.

=head2 printf( FILEHANDLE FORMAT, LIST )

printf() to the filehandle.

=head2 syswrite( FILEHANDLE, SCALAR, [LENGTH], [OFFSET] )

syswrite() to the filehandle.

=head1 ENVIRONMENT

=over

=item IP_EOF

Controls IO:Pager behavior when C<eof> is used.

=item PAGER

The location of the default pager.

=item PATH

If the location in PAGER is not absolute, PATH may be searched.

See L</NOTES> for more information.

=back

=head1 FILES

IO::Pager may fall back to these binaries in order if I<PAGER> is not
executable.

=over

=item /etc/alternatives/pager

=item /usr/local/bin/less

=item /usr/bin/less

=item L<IO::Pager::Perl> as C<tp> via L<IO::Pager::less>

=item /usr/bin/more

=back

See L</NOTES> for more information.

=head1 NOTES

The algorithm for determining which pager to use is as follows:

=over

=item 1. Defer to I<PAGER>

If the I<PAGER> environment variable is set, use the pager it identifies,
unless this pager is not available.

=item 2. Usual suspects

Try the standard, hardcoded paths in L</FILES>.

=item 3. File::Which

If File::Which is available, use the first pager possible amongst
C<less>, C<most>, C<w3m>, C<lv>, C<pg> and L<more>.

=item 4. Term::Pager via IO::Pager::Perl

=cut

If instantiating an IO::Pager object and Term::Pager version 1.5 or greater is
available, L<IO::Pager::Perl> will be used.

=pod
You may also set $ENV{PAGER} to
Term::Pager to select this extensible, pure perl pager for display.

=item 5. more

Set I<PAGER> to C<more>, and cross our fingers.

=back

Steps 1, 3 and 5 rely upon the I<PATH> environment variable.

=head1 CAVEATS

You probably want to do something with SIGPIPE eg;

  eval {
    local $SIG{PIPE} = sub { die };
    local $STDOUT = IO::Pager::open(*STDOUT);

    while (1) {
      # Do something
    }
  }

  # Do something else

=head1 SEE ALSO

L<IO::Pager::Buffered>, L<IO::Pager::Unbuffered>, L<I::Pager::Perl>,
L<IO::Pager::Page>, L<IO::Page>, L<Meta::Tool::Less>

=head1 AUTHOR

Jerrad Pierce <jpierce@cpan.org>

Florent Angly <florent.angly@gmail.com>

This module was inspired by Monte Mitzelfelt's IO::Page 0.02

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2019 Jerrad Pierce

=over

=item * Thou shalt not claim ownership of unmodified materials.

=item * Thou shalt not claim whole ownership of modified materials.

=item * Thou shalt grant the indemnity of the provider of materials.

=item * Thou shalt use and dispense freely without other restrictions.

=back

Or, if you prefer:

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
