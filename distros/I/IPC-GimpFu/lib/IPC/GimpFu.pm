package IPC::GimpFu;

use 5.006;
use strict;
use warnings;

use Carp;
use Cwd;
use IO::Socket::IP;
use Proc::Daemon;
use Proc::Killall;

=head1 NAME

IPC::GimpFu - interface to Gimp's script-fu server

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This module makes it possible to communicate with Gimp's script-fu
server, and also to start/stop it on the local machine.

    use IPC::GimpFu;

    # Fine control on a local instance:
    my $gimp = IPC::GimpFu->new();
    $gimp->local_start();
    $gimp->run("some command");
    $gimp->local_stop();

    # Start locally if needed, keep running once we're done:
    my $gimp = IPC::GimpFu->new({ autostart => 1 });
    $gimp->run({ file => "gimp-source.scm" });
    $gimp->run("some command");

    # Use a remote server:
    my $gimp = IPC::GimpFu->new({ server => "other-server", port => "other-port" });
    $gimp->run("something else");

=cut

=head1 SUBROUTINES/METHODS

=head2 new

Create a new object, using an anonymous hash. The following can be set
this way: autostart, server, and port; autostart is only valid if
server is localhost; default settings are:

    autostart => 0
    server => 'localhost'
    port => '10008'

=cut

sub new {
  my $class = shift;
  my $params = shift;
  # Default params:
  my $self = {
    autostart => 0,
    server => 'localhost',
    port => '10008',
  };
  # Override if needed:
  foreach my $key (keys %$self) {
    $self->{$key} = $params->{$key}
      if $params->{$key};
  }
  # Can only autostart on localhost:
  if (not _is_localhost($self->{server}) and $self->{autostart}) {
    carp "autostart and non-localhost server (" . $self->{server} . ") are incompatible";
    return undef;
  }
  bless($self, $class);
  return $self;
}

=head2 start

Start the server, if configured on localhost.

=cut

sub start {
  my $self = shift;

  # Make sure it makes sense to try starting the server:
  if (not _is_localhost($self->{server})) {
    carp "attempting to start on a non-localhost server (" . $self->{server} . ")";
    return 0;
  }

  # FIXME: Implement checking whether there's already somebody on this port?

  # FIXME: Implement some checks on port's validity?
  my $port = $self->{port};
  # Original command-line:
  #   gimp --verbose -i -b '(plug-in-script-fu-server RUN-NONINTERACTIVE 10008 "some file")'
  my $cmd = "gimp --verbose -i -b '(plug-in-script-fu-server RUN-NONINTERACTIVE $port \"/dev/null\")'";
  my $daemon = Proc::Daemon->new(
    work_dir => getcwd,
    exec_command => $cmd,
  );

  if (not $daemon) {
    carp "Proc::Daemon->new failed: $!";
    return 0;
  }

  my $pid = $daemon->Init()
    or carp "Proc::Daemon->Init failed: $!";
  return $pid;
}

=head2 stop

Stop the server, if configured on localhost.

=cut

sub stop {
  my $self = shift;

  # Make sure it makes sense to try starting the server:
  if (not _is_localhost($self->{server})) {
    carp "attempting to stop on a non-localhost server (" . $self->{server} . ")";
    return 0;
  }

  # Forget about the connection previously opened:
  $self->{sock} = undef;

  # Hopefully there shouldn't be anyone left after that:
  my $gimp     = killall('KILL', 'gimp');
  my $scriptfu = killall('KILL', 'script-fu');
  return $gimp+$scriptfu;
}

=head2 run

Run a given command on the specified server, connecting on the fly if
needed. Can be passed a command, or a hash with a file key:

    $gimp->run("some command");
    $gimp->run({ file => 'foo.scm' });

=cut

sub run {
  my $self = shift;
  my $params = shift;

  if (ref($params) eq 'HASH' && $params->{file}) {
    my $file = $params->{file};
    #print STDERR "file: $file\n";
    if (! -f $file) {
      carp "unable to find $file";
      return 0;
    }

    ## Slurp and strip comments/newlines:
    open my $source_fh, '<', $file
      or die "Unable to open source file $file";
    my $source_code;
    while (<$source_fh>) {
      # Kill comments:
      s{^\s*;.*}{};
      $source_code .= ' ' . $_;
    }
    # Kill newlines, and minimize spaces:
    $source_code =~ s/\n/ /msg;
    $source_code =~ s/\s+/ /msg;
    close $source_fh
      or die "Unable to close source file $file";

    # Finally run:
    return $self->_run_cmd($source_code);
  }
  elsif (not ref($params)) {
    my $source = $params;
    if (not $source) {
      carp "no command was passed, returning";
      return 0;
    }
    #print STDERR "source: $source\n";
    return $self->_run_cmd($source);
  }
  else {
    carp "run(): unexpected parameter, check documentation";
    return 0;
  }
}

=for comment _run_cmd
Helper called from run(), dealing with a command passed as a string.

=cut

sub _run_cmd {
  my $self = shift;
  my $cmd = shift;

  # Only open a socket if there's none open already:
  if (! $self->{sock}) {
    # FIXME: 10 and '1 second' shouldn't be hardcoded below:
    my $max_attempts = $self->{autostart} ? 10 : 1;
    my $sleep = 1;
    my $sock;
    my $ready = 0;
    for my $attempt (0..$max_attempts-1) {
      # Regular connection attempt first:
      #print STDERR "trying connection to: " . $self->{server} . ':' . $self->{port} . "\n";
      if ($sock = IO::Socket::IP->new(
        PeerHost => $self->{server},
        PeerPort => $self->{port},
        Type     => SOCK_STREAM,
      )) {
        #print STDERR "connection ok on attempt #$attempt\n";
        $self->{sock} = $sock;
        last;
      }
      else {
        if ($self->{autostart} && $attempt == 0) {
          #print STDERR "attempting start\n";
          $self->start();
        }
        # Wait in all non-last-attempt cases:
        #print STDERR "maybe sleeping\n";
        sleep $sleep
          if $attempt < $max_attempts-1;
      }
    }
  }

  # By now there's hopefully a socket open:
  if ($self->{sock}) {
    return _gimp_send_command($self->{sock}, $cmd);
  }
  else {
    die sprintf "Failed to connect to %s:%d\n", $self->{server}, $self->{port};
  }
}

sub _gimp_ensure_proper_connection {
  my ($sock) = @_;
  # Connection-level:
  $sock->connected
    or die "No proper connection on the socket";

  # This should be quick and free from side-effects
  # Other ideas include:
  #  - gimp-image-list
  #  - gimp-getpid
  _gimp_send_command($sock, '(gimp-version)');
}

sub _gimp_send_command {
  my ($sock, $command) = @_;
#  print "Sending command: $command\n";

  # Upstream doc about the format:
  #   http://docs.gimp.org/en/gimp-filters-script-fu.html
  #
  # Query of length L:
  #   0   0x47            Magic byte ('G')
  #   1   L div 256       High byte of L
  #   2   L mod 256       Low byte of L
  #
  # Response of length L:
  #   0   0x47            Magic byte ('G')
  #   1   error code      0 on success, 1 on error
  #   2   L div 256       High byte of L
  #   3   L mod 256       Low byte of L
  #
  # Beware of the response!
  #   https://bugzilla.gnome.org/583778

  # Prepare query and send:
  # FIXME: Should error out if $command is too long
  my $magic1 = 'G';
  my $len1   = length($command) & 0xffff;
  my $high1  = ($len1 & 0xff00) >> 8;
  my $low1   = ($len1 & 0x00ff);
  my $header = pack('A1C1C1', $magic1, $high1, $low1);
  $sock->send($header);
  $sock->send($command);

  # Read 4 bytes to get error code and response's length, then the response itself:
  # FIXME: Check the second magic is right?
  $sock->read($header, 4);
  my ($magic2, $error, $high2, $low2) = unpack('A1C1C1C1', $header);
  my $len2 = $high2 << 8 | $low2;
  $sock->read(my $response, $len2);

  return $response;
}

=for comment _is_localhost($server)
Tiny helper helping decide whether the specified server is localhost.

=cut
sub _is_localhost {
  my $server = shift;
  return scalar(grep { $_ eq $server } qw(localhost 127.0.0.1));
}

=head1 AUTHOR

Cyril Brulebois, C<< <kibi at debian.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-gimpfu at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-GimpFu>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::GimpFu


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC-GimpFu>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPC-GimpFu>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPC-GimpFu>

=item * Search CPAN

L<http://search.cpan.org/dist/IPC-GimpFu/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Cyril Brulebois.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of IPC::GimpFu
