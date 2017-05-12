package IO::Multiplex;

use strict;
use warnings;

our $VERSION = '1.16';

=head1 NAME

IO::Multiplex - Manage IO on many file handles

=head1 SYNOPSIS

  use IO::Multiplex;

  my $mux = new IO::Multiplex;
  $mux->add($fh1);
  $mux->add(\*FH2);
  $mux->set_callback_object(...);
  $mux->listen($server_socket);
  $mux->loop;

  sub mux_input { ... }

C<IO::Multiplex> is designed to take the effort out of managing
multiple file handles. It is essentially a really fancy front end to
the C<select> system call. In addition to maintaining the C<select>
loop, it buffers all input and output to/from the file handles.  It
can also accept incoming connections on one or more listen sockets.

=head1 DESCRIPTION

It is object oriented in design, and will notify you of significant events
by calling methods on an object that you supply.  If you are not using
objects, you can simply supply C<__PACKAGE__> instead of an object reference.

You may have one callback object registered for each file handle, or
one global one.  Possibly both -- the per-file handle callback object
will be used instead of the global one.

Each file handle may also have a timer associated with it.  A callback
function is called when the timer expires.

=head2 Handling input on descriptors

When input arrives on a file handle, the C<mux_input> method is called
on the appropriate callback object.  This method is passed three
arguments (in addition to the object reference itself of course):

=over 4

=item 1

a reference to the mux,

=item 2

A reference to the file handle, and

=item 3

a reference to the input buffer for the file handle.

=back

The method should remove the data that it has consumed from the
reference supplied.  It may leave unconsumed data in the input buffer.

=head2 Handling output to descriptors

If C<IO::Multiplex> did not handle output to the file handles as well
as input from them, then there is a chance that the program could
block while attempting to write.  If you let the multiplexer buffer
the output, it will write the data only when the file handle is
capable of receiveing it.

The basic method for handing output to the multiplexer is the C<write>
method, which simply takes a file descriptor and the data to be
written, like this:

    $mux->write($fh, "Some data");

For convenience, when the file handle is C<add>ed to the multiplexer, it
is tied to a special class which intercepts all attempts to write to the
file handle.  Thus, you can use print and printf to send output to the
handle in a normal manner:

    printf $fh "%s%d%X", $foo, $bar, $baz

Unfortunately, Perl support for tied file handles is incomplete, and
functions such as C<send> cannot be supported.

Also, file handle object methods such as the C<send> method of
C<IO::Socket> cannot be intercepted.

=head1 EXAMPLES

=head2 Simple Example

This is a simple telnet-like program, which demonstrates the concepts
covered so far.  It does not really work too well against a telnet
server, but it does OK against the sample server presented further down.

    use IO::Socket;
    use IO::Multiplex;

    # Create a multiplex object
    my $mux  = new IO::Multiplex;
    # Connect to the host/port specified on the command line,
    # or localhost:23
    my $sock = new IO::Socket::INET(Proto    => 'tcp',
                                    PeerAddr => shift || 'localhost',
                                    PeerPort => shift || 23)
        or die "socket: $@";

    # add the relevant file handles to the mux
    $mux->add($sock);
    $mux->add(\*STDIN);
    # We want to buffer output to the terminal.  This prevents the program
    # from blocking if the user hits CTRL-S for example.
    $mux->add(\*STDOUT);

    # We're not object oriented, so just request callbacks to the
    # current package
    $mux->set_callback_object(__PACKAGE__);

    # Enter the main mux loop.
    $mux->loop;

    # mux_input is called when input is available on one of
    # the descriptors.
    sub mux_input {
        my $package = shift;
        my $mux     = shift;
        my $fh      = shift;
        my $input   = shift;

        # Figure out whence the input came, and send it on to the
        # other place.
        if ($fh == $sock) {
            print STDOUT $$input;
        } else {
            print $sock $$input;
        }
        # Remove the input from the input buffer.
        $$input = '';
    }

    # This gets called if the other end closes the connection.
    sub mux_close {
        print STDERR "Connection Closed\n";
        exit;
    }

=head2 A server example

Servers are just as simple to write.  We just register a listen socket
with the multiplex object C<listen> method.  It will automatically
accept connections on it and add them to its list of active file handles.

This example is a simple chat server.

    use IO::Socket;
    use IO::Multiplex;

    my $mux  = new IO::Multiplex;

    # Create a listening socket
    my $sock = new IO::Socket::INET(Proto     => 'tcp',
                                    LocalPort => shift || 2300,
                                    Listen    => 4)
        or die "socket: $@";

    # We use the listen method instead of the add method.
    $mux->listen($sock);

    $mux->set_callback_object(__PACKAGE__);
    $mux->loop;

    sub mux_input {
        my $package = shift;
        my $mux     = shift;
        my $fh      = shift;
        my $input   = shift;

        # The handles method returns a list of references to handles which
        # we have registered, except for listen sockets.
        foreach $c ($mux->handles) {
            print $c $$input;
        }
        $$input = '';
    }

=head2 A more complex server example

Let us take a look at the beginnings of a multi-user game server.  We will
have a Player object for each player.

    # Paste the above example in here, up to but not including the
    # mux_input subroutine.

    # mux_connection is called when a new connection is accepted.
    sub mux_connection {
        my $package = shift;
        my $mux     = shift;
        my $fh      = shift;

        # Construct a new player object
        Player->new($mux, $fh);
    }

    package Player;

    my %players = ();

    sub new {
        my $package = shift;
        my $self    = bless { mux  => shift,
                              fh   => shift } => $package;

        # Register the new player object as the callback specifically for
        # this file handle.

        $self->{mux}->set_callback_object($self, $self->{fh});
        print $self->{fh}
            "Greetings, Professor.  Would you like to play a game?\n";

        # Register this player object in the main list of players
        $players{$self} = $self;
        $mux->set_timeout($self->{fh}, 1);
    }

    sub players { return values %players; }

    sub mux_input {
        my $self = shift;
        shift; shift;         # These two args are boring
        my $input = shift;    # Scalar reference to the input

        # Process each line in the input, leaving partial lines
        # in the input buffer
        while ($$input =~ s/^(.*?)\n//) {
            $self->process_command($1);
        }
    }

    sub mux_close {
       my $self = shift;

       # Player disconnected;
       # [Notify other players or something...]
       delete $players{$self};
    }
    # This gets called every second to update player info, etc...
    sub mux_timeout {
        my $self = shift;
        my $mux  = shift;

        $self->heartbeat;
        $mux->set_timeout($self->{fh}, 1);
    }

=head1 METHODS

=cut

use POSIX qw(errno_h BUFSIZ);
use Socket;
use FileHandle qw(autoflush);
use IO::Handle;
use Fcntl;
use Carp qw(carp);
use constant IsWin => ($^O eq 'MSWin32');


BEGIN {
    eval {
        # Can optionally use Hi Res timers if available
        require Time::HiRes;
        Time::HiRes->import('time');
    };
}

# This is what you want.  Trust me.
$SIG{PIPE} = 'IGNORE';

{   no warnings;
    if(IsWin) { *EWOULDBLOCK = sub() {10035} }
}

=head2 new

Construct a new C<IO::Multiplex> object.

    $mux = new IO::Multiplex;

=cut

sub new
{
    my $package = shift;
    my $self = bless { _readers     => '',
                       _writers     => '',
                       _fhs         => {},
                       _handles     => {},
                       _timerkeys   => {},
                       _timers      => [],
                       _listen      => {}  } => $package;
    return $self;
}

=head2 listen

Add a socket to be listened on.  The socket should have had the
C<bind> and C<listen> system calls already applied to it.  The C<IO::Socket>
module will do this for you.

    $socket = new IO::Socket::INET(Listen => ..., LocalAddr => ...);
    $mux->listen($socket);

Connections will be automatically accepted and C<add>ed to the multiplex
object.  C<The mux_connection> callback method will also be called.

=cut

sub listen
{
    my $self = shift;
    my $fh   = shift;

    $self->add($fh);
    $self->{_fhs}{"$fh"}{listen} = 1;
    $fh;
}

=head2 add

Add a file handle to the multiplexer.

    $mux->add($fh);

As a side effect, this sets non-blocking mode on the handle, and disables
STDIO buffering.  It also ties it to intercept output to the handle.

=cut

sub add
{
    my $self = shift;
    my $fh   = shift;

    return if $self->{_fhs}{"$fh"};

    nonblock($fh);
    autoflush($fh, 1);
    fd_set($self->{_readers}, $fh, 1);

    my $sockopt = getsockopt $fh, SOL_SOCKET, SO_TYPE;
    $self->{_fhs}{"$fh"}{udp_true} = 1
        if defined $sockopt && SOCK_DGRAM == unpack "i", $sockopt;

    $self->{_fhs}{"$fh"}{inbuffer} = '';
    $self->{_fhs}{"$fh"}{outbuffer} = '';
    $self->{_fhs}{"$fh"}{fileno} = fileno($fh);
    $self->{_handles}{"$fh"} = $fh;
    tie *$fh, "IO::Multiplex::Handle", $self, $fh;
    return $fh;
}

=head2 remove

Removes a file handle from the multiplexer.  This also unties the
handle.  It does not currently turn STDIO buffering back on, or turn
off non-blocking mode.

    $mux->remove($fh);

=cut

sub remove
{
    my $self = shift;
    my $fh   = shift;
    fd_set($self->{_writers}, $fh, 0);
    fd_set($self->{_readers}, $fh, 0);
    delete $self->{_fhs}{"$fh"};
    delete $self->{_handles}{"$fh"};
    $self->_removeTimer($fh);
    untie *$fh;
    return 1;
}

=head2 set_callback_object

Set the object on which callbacks are made.  If you are not using objects,
you can specify the name of the package into which the method calls are
to be made.

If a file handle is supplied, the callback object is specific for that
handle:

    $mux->set_callback_object($object, $fh);

Otherwise, it is considered a default callback object, and is used when
events occur on a file handle that does not have its own callback object.

    $mux->set_callback_object(__PACKAGE__);

The previously registered object (if any) is returned.

See also the CALLBACK INTERFACE section.

=cut

sub set_callback_object
{
    my $self = shift;
    my $obj  = shift;
    my $fh   = shift;
    return if $fh && !exists($self->{_fhs}{"$fh"});

    my $old  = $fh ? $self->{_fhs}{"$fh"}{object} : $self->{_object};

    $fh ? $self->{_fhs}{"$fh"}{object} : $self->{_object} = $obj;
    return $old;
}

=head2 kill_output

Remove any pending output on a file descriptor.

    $mux->kill_output($fh);

=cut

sub kill_output
{
    my $self = shift;
    my $fh   = shift;
    return unless $fh && exists($self->{_fhs}{"$fh"});

    $self->{_fhs}{"$fh"}{outbuffer} = '';
    fd_set($self->{_writers}, $fh, 0);
}

=head2 outbuffer

Return or set the output buffer for a descriptor

    $output = $mux->outbuffer($fh);
    $mux->outbuffer($fh, $output);

=cut

sub outbuffer
{
    my $self = shift;
    my $fh   = shift;
    return unless $fh && exists($self->{_fhs}{"$fh"});

    if (@_) {
        $self->{_fhs}{"$fh"}{outbuffer} = $_[0] if @_;
        fd_set($self->{_writers}, $fh, 0) if !$_[0];
    }

    $self->{_fhs}{"$fh"}{outbuffer};
}

=head2 inbuffer

Return or set the input buffer for a descriptor

    $input = $mux->inbuffer($fh);
    $mux->inbuffer($fh, $input);

=cut

sub inbuffer
{
    my $self = shift;
    my $fh   = shift;
    return unless $fh && exists($self->{_fhs}{"$fh"});

    if (@_) {
        $self->{_fhs}{"$fh"}{inbuffer} = $_[0] if @_;
    }

    return $self->{_fhs}{"$fh"}{inbuffer};
}

=head2 set_timeout

Set the timer for a file handle.  The timeout value is a certain number of
seconds in the future, after which the C<mux_timeout> callback is called.

If the C<Time::HiRes> module is installed, the timers may be specified in
fractions of a second.

Timers are not reset automatically.

    $mux->set_timeout($fh, 23.6);

Use C<$mux-E<gt>set_timeout($fh, undef)> to cancel a timer.

=cut

sub set_timeout
{
    my $self     = shift;
    my $fh       = shift;
    my $timeout  = shift;
    return unless $fh && exists($self->{_fhs}{"$fh"});

    if (defined $timeout) {
        $self->_addTimer($fh, $timeout + time);
    } else {
        $self->_removeTimer($fh);
    }
}

=head2 handles

Returns a list of handles that the C<IO::Multiplex> object knows about,
excluding listen sockets.

    @handles = $mux->handles;

=cut

sub handles
{
    my $self = shift;

    return grep(!$self->{_fhs}{"$_"}{listen}, values %{$self->{_handles}});
}

sub _addTimer {
    my $self = shift;
    my $fh   = shift;
    my $time = shift;

    # Set a key so that we can quickly tell if a given $fh has
    # a timer set
    $self->{_timerkeys}{"$fh"} = 1;

    # Store the timeout in an array, and resort it
    @{$self->{_timers}} = sort { $a->[1] <=> $b->[1] } (@{$self->{_timers}}, [ $fh, $time ] );
}

sub _removeTimer {
    my $self = shift;
    my $fh   = shift;

    # Return quickly if no timer is set
    return unless exists $self->{_timerkeys}{"$fh"};

    # Remove the timeout from the sorted array
    @{$self->{_timers}} = grep { $_->[0] ne $fh } @{$self->{_timers}};

    # Get rid of the key
    delete $self->{_timerkeys}{"$fh"};
}


=head2 loop

Enter the main loop and start processing IO events.

    $mux->loop;

=cut

sub loop
{
    my $self = shift;
    my $heartbeat = shift;
    $self->{_endloop} = 0;

    while (!$self->{_endloop} && keys %{$self->{_fhs}}) {
        my $rv;
        my $data;
        my $rdready = "";
        my $wrready = "";
        my $timeout = undef;

        foreach my $fh (values %{$self->{_handles}}) {
            fd_set($rdready, $fh, 1) if
                ref($fh) =~ /SSL/ &&
                $fh->can("pending") &&
                $fh->pending;
        }

        if (!length $rdready) {
            if (@{$self->{_timers}}) {
                $timeout = $self->{_timers}[0][1] - time;
            }

            my $numready = select($rdready=$self->{_readers},
                                  $wrready=$self->{_writers},
                                  undef,
                                  $timeout);

            unless(defined($numready)) {
                if ($! == EINTR || $! == EAGAIN) {
                    next;
                } else {
                    last;
                }
            }
        }

        &{ $heartbeat } ($rdready, $wrready) if $heartbeat;

        foreach my $k (keys %{$self->{_handles}}) {
            my $fh = $self->{_handles}->{$k} or next;

            # Avoid creating a permanent empty hash ref for "$fh"
            # by attempting to access its {object} element
            # if it has already been closed.
            next unless exists $self->{_fhs}{"$fh"};

            # It is not easy to replace $self->{_fhs}{"$fh"} with a
            # variable, because some mux_* routines may remove it as
            # side-effect.

            # Get the callback object.
            my $obj = $self->{_fhs}{"$fh"}{object} ||
                $self->{_object};

            # Is this descriptor ready for reading?
            if (fd_isset($rdready, $fh))
            {
                if ($self->{_fhs}{"$fh"}{listen}) {
                    # It's a server socket, so a new connection is
                    # waiting to be accepted
                    my $client = $fh->accept;
                    next unless ($client);
                    $self->add($client);
                    $obj->mux_connection($self, $client)
                        if $obj && $obj->can("mux_connection");
                } else {
                    if ($self->is_udp($fh)) {
                        $rv = recv($fh, $data, BUFSIZ, 0);
                        if (defined $rv) {
                            # Remember where the last UDP packet came from
                            $self->{_fhs}{"$fh"}{udp_peer} = $rv;
                        }
                    } else {
                        $rv = &POSIX::read(fileno($fh), $data, BUFSIZ);
                    }

                    if (defined($rv) && length($data)) {
                        # Append the data to the client's receive buffer,
                        # and call process_input to see if anything needs to
                        # be done.
                        $self->{_fhs}{"$fh"}{inbuffer} .= $data;
                        $obj->mux_input($self, $fh,
                                        \$self->{_fhs}{"$fh"}{inbuffer})
                            if $obj && $obj->can("mux_input");
                    } else {
                        unless (defined $rv) {
                            next if
                                $! == EINTR ||
                                $! == EAGAIN ||
                                $! == EWOULDBLOCK;
			    warn "IO::Multiplex read error: $!"
                                if $! != ECONNRESET;
                        }
                        # There's an error, or we received EOF.  If
                        # there's pending data to be written, we leave
                        # the connection open so it can be sent.  If
                        # the other end is closed for writing, the
                        # send will error and we close down there.
                        # Either way, we remove it from _readers as
                        # we're no longer interested in reading from
                        # it.
                        fd_set($self->{_readers}, $fh, 0);
                        $obj->mux_eof($self, $fh,
                                      \$self->{_fhs}{"$fh"}{inbuffer})
                            if $obj && $obj->can("mux_eof");

                        if (exists $self->{_fhs}{"$fh"}) {
                            $self->{_fhs}{"$fh"}{inbuffer} = '';
                            # The mux_eof handler could have responded
                            # with a shutdown for writing.
                            $self->close($fh)
                                unless exists $self->{_fhs}{"$fh"}
                                    && length $self->{_fhs}{"$fh"}{outbuffer};
                        }
                        next;
                    }
                }
            }  # end if readable
            next unless exists $self->{_fhs}{"$fh"};

            if (fd_isset($wrready, $fh)) {
                unless (length $self->{_fhs}{"$fh"}{outbuffer}) {
                    fd_set($self->{_writers}, $fh, 0);
                    $obj->mux_outbuffer_empty($self, $fh)
                        if ($obj && $obj->can("mux_outbuffer_empty"));
                    next;
                }
                $rv = &POSIX::write(fileno($fh),
                                    $self->{_fhs}{"$fh"}{outbuffer},
                                    length($self->{_fhs}{"$fh"}{outbuffer}));
                unless (defined($rv)) {
                    # We got an error writing to it.  If it's
                    # EWOULDBLOCK (shouldn't happen if select told us
                    # we can write) or EAGAIN, or EINTR we don't worry
                    # about it.  otherwise, close it down.
                    unless ($! == EWOULDBLOCK ||
                            $! == EINTR ||
                            $! == EAGAIN) {
                        if ($! == EPIPE) {
                            $obj->mux_epipe($self, $fh)
                                if $obj && $obj->can("mux_epipe");
                        } else {
                            warn "IO::Multiplex: write error: $!\n";
                        }
                        $self->close($fh);
                    }
                    next;
                }
                substr($self->{_fhs}{"$fh"}{outbuffer}, 0, $rv) = '';
                unless (length $self->{_fhs}{"$fh"}{outbuffer}) {
                    # Mark us as not writable if there's nothing more to
                    # write
                    fd_set($self->{_writers}, $fh, 0);
                    $obj->mux_outbuffer_empty($self, $fh)
                        if ($obj && $obj->can("mux_outbuffer_empty"));

                    if (   $self->{_fhs}{"$fh"}
                        && $self->{_fhs}{"$fh"}{shutdown}) {
                        # If we've been marked for shutdown after write
                        # do it.
                        shutdown($fh, 1);
                        $self->{_fhs}{"$fh"}{outbuffer} = '';
                        unless (length $self->{_fhs}{"$fh"}{inbuffer}) {
                            # We'd previously been shutdown for reading
                            # also, so close out completely
                            $self->close($fh);
                            next;
                        }
                    }
                }
            }  # End if writeable

            next unless exists $self->{_fhs}{"$fh"};

        }  # End foreach $fh (...)

        $self->_checkTimeouts() if @{$self->{_timers}};

    } # End while(loop)
}

sub _checkTimeouts {
    my $self = shift;

    # Get the current time
    my $time = time;

    # Copy all of the timers that should go off into
    # a temporary array. This allows us to modify the
    # real array as we process the timers, without
    # interfering with the loop.

    my @timers = ();
    foreach my $timer (@{$self->{_timers}}) {
        # If the timer is in the future, we can stop
        last if $timer->[1] > $time;
        push @timers, $timer;
    }

    foreach my $timer (@timers) {
        my $fh = $timer->[0];
        $self->_removeTimer($fh);

        next unless exists $self->{_fhs}{"$fh"};

        my $obj = $self->{_fhs}{"$fh"}{object} || $self->{_object};
        $obj->mux_timeout($self, $fh) if $obj && $obj->can("mux_timeout");
    }
}


=head2 endloop

Prematurly terminate the loop.  The loop will automatically terminate
when there are no remaining descriptors to be watched.

    $mux->endloop;

=cut

sub endloop
{
    my $self = shift;
    $self->{_endloop} = 1;
}

=head2 udp_peer

Get peer endpoint of where the last udp packet originated.

    $saddr = $mux->udp_peer($fh);

=cut

sub udp_peer {
  my $self = shift;
  my $fh = shift;
  return $self->{_fhs}{"$fh"}{udp_peer};
}

=head2 is_udp

Sometimes UDP packets require special attention.
This method will tell if a file handle is of type UDP.

    $is_udp = $mux->is_udp($fh);

=cut

sub is_udp {
  my $self = shift;
  my $fh = shift;
  return $self->{_fhs}{"$fh"}{udp_true};
}

=head2 write

Send output to a file handle.

    $mux->write($fh, "'ere I am, JH!\n");

=cut

sub write
{
    my $self = shift;
    my $fh   = shift;
    my $data = shift;
    return unless $fh && exists($self->{_fhs}{"$fh"});

    if ($self->{_fhs}{"$fh"}{shutdown}) {
        $! = EPIPE;
        return undef;
    }
    if ($self->is_udp($fh)) {
        if (my $udp_peer = $self->udp_peer($fh)) {
            # Send the packet back to the last peer that said something
            return send($fh, $data, 0, $udp_peer);
        } else {
            # No udp_peer yet?
            # This better be a connect()ed UDP socket
            # or else this will fail with ENOTCONN
            return send($fh, $data, 0);
        }
    }
    $self->{_fhs}{"$fh"}{outbuffer} .= $data;
    fd_set($self->{_writers}, $fh, 1);
    return length($data);
}

=head2 shutdown

Shut down a socket for reading or writing or both.  See the C<shutdown>
Perl documentation for further details.

If the shutdown is for reading, it happens immediately.  However,
shutdowns for writing are delayed until any pending output has been
successfully written to the socket.

    $mux->shutdown($socket, 1);

=cut

sub shutdown
{
    my $self = shift;
    my $fh = shift;
    my $which = shift;
    return unless $fh && exists($self->{_fhs}{"$fh"});

    if ($which == 0 || $which == 2) {
        # Shutdown for reading.  We can do this now.
        shutdown($fh, 0);
        # The mux_eof hook must be run from the main loop to consume
        # the rest of the inbuffer if there is anything left.
        # It will also remove $fh from _readers.
    }

    if ($which == 1 || $which == 2) {
        # Shutdown for writing.  Only do this now if there is no pending
        # data.
        if(length $self->{_fhs}{"$fh"}{outbuffer}) {
            $self->{_fhs}{"$fh"}{shutdown} = 1;
        } else {
            shutdown($fh, 1);
            $self->{_fhs}{"$fh"}{outbuffer} = '';
        }
    }
    # Delete the descriptor if it's totally gone.
    unless (length $self->{_fhs}{"$fh"}{inbuffer} ||
            length $self->{_fhs}{"$fh"}{outbuffer}) {
        $self->close($fh);
    }
}

=head2 close

Close a handle.  Always use this method to close a handle that is being
watched by the multiplexer.

    $mux->close($fh);

=cut

sub close
{
    my $self = shift;
    my $fh = shift;
    return unless exists $self->{_fhs}{"$fh"};

    my $obj = $self->{_fhs}{"$fh"}{object} || $self->{_object};
    warn "closing with read buffer"  if length $self->{_fhs}{"$fh"}{inbuffer};
    warn "closing with write buffer" if length $self->{_fhs}{"$fh"}{outbuffer};

    fd_set($self->{_readers}, $fh, 0);
    fd_set($self->{_writers}, $fh, 0);

    delete $self->{_fhs}{"$fh"};
    delete $self->{_handles}{"$fh"};
    untie *$fh;
    close $fh;
    $obj->mux_close($self, $fh) if $obj && $obj->can("mux_close");
}

# We set non-blocking mode on all descriptors.  If we don't, then send
# might block if the data is larger than the kernel can accept all at once,
# even though select told us we can write.  With non-blocking mode, we
# get a partial write in those circumstances, which is what we want.

sub nonblock
{   my $fh = shift;

    if(IsWin)
    {   ioctl($fh, 0x8004667e, pack("L!", 1));
    }
    else
    {   my $flags = fcntl($fh, F_GETFL, 0)
            or die "fcntl F_GETFL: $!\n";
        fcntl($fh, F_SETFL, $flags | O_NONBLOCK)
            or die "fcntl F_SETFL $!\n";
    }
}

sub fd_set
{
     vec($_[0], fileno($_[1]), 1) = $_[2];
}

sub fd_isset
{
    return vec($_[0], fileno($_[1]), 1);
}

# We tie handles into this package to handle write buffering.

package IO::Multiplex::Handle;

use strict;
use Tie::Handle;
use Carp;
use vars qw(@ISA);
@ISA = qw(Tie::Handle);

sub FILENO
{
    my $self = shift;
    return ($self->{_mux}->{_fhs}->{"$self->{_fh}"}->{fileno});
}


sub TIEHANDLE
{
    my $package = shift;
    my $mux = shift;
    my $fh  = shift;

    my $self = bless { _mux   => $mux,
                       _fh    => $fh } => $package;
    return $self;
}

sub WRITE
{
    my $self = shift;
    my ($msg, $len, $offset) = @_;
    $offset ||= 0;
    return $self->{_mux}->write($self->{_fh}, substr($msg, $offset, $len));
}

sub CLOSE
{
    my $self = shift;
    return $self->{_mux}->shutdown($self->{_fh}, 2);
}

sub READ
{
    carp "Do not read from a muxed file handle";
}

sub READLINE
{
    carp "Do not read from a muxed file handle";
}

sub FETCH
{
    return "Fnord";
}

sub UNTIE {}

1;

__END__

=head1 CALLBACK INTERFACE

Callback objects should support the following interface.  You do not have
to provide all of these methods, just provide the ones you are interested in.

All methods receive a reference to the callback object (or package) as
their first argument, in the traditional object oriented
way. References to the C<IO::Multiplex> object and the relevant file
handle are also provided.  This will be assumed in the method
descriptions.

=head2 mux_input

Called when input is ready on a descriptor.  It is passed a reference to
the input buffer.  It should remove any input that it has consumed, and
leave any partially received data in the buffer.

    sub mux_input {
        my $self = shift;
        my $mux  = shift;
        my $fh   = shift;
        my $data = shift;

        # Process each line in the input, leaving partial lines
        # in the input buffer
        while ($$data =~ s/^(.*?\n)//) {
            $self->process_command($1);
        }
    }

=head2 mux_eof

This is called when an end-of-file condition is present on the descriptor.
This is does not nessecarily mean that the descriptor has been closed, as
the other end of a socket could have used C<shutdown> to close just half
of the socket, leaving us free to write data back down the still open
half.  Like mux_input, it is also passed a reference to the input buffer.
It should consume the entire buffer or else it will just be lost.

In this example, we send a final reply to the other end of the socket,
and then shut it down for writing.  Since it is also shut down for reading
(implicly by the EOF condition), it will be closed once the output has
been sent, after which the mux_close callback will be called.

    sub mux_eof {
        my $self = shift;
        my $mux  = shift;
        my $fh   = shift;

        print $fh "Well, goodbye then!\n";
        $mux->shutdown($fh, 1);
    }

=head2 mux_close

Called when a handle has been completely closed.  At the time that
C<mux_close> is called, the handle will have been removed from the
multiplexer, and untied.

=head2 mux_outbuffer_empty

Called after all pending output has been written to the file descriptor.

=head2 mux_connection

Called upon a new connection being accepted on a listen socket.

=head2 mux_timeout

Called when a timer expires.

=head1 AUTHOR

Copyright 1999 Bruce J Keeler <bruce@gridpoint.com>

Copyright 2001-2008 Rob Brown <bbb@cpan.org>

Released under the same terms as Perl itself.

$Id: Multiplex.pm,v 1.45 2015/04/09 21:27:54 rob Exp $

=cut
