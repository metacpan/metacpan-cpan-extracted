# $Id: IOMultiplexKQueue.pm 116 2005-12-22 04:25:28Z in2 $
package IO::Multiplex::KQueue;

=head1 NAME

IO::Multiplex::KQueue - IO::Multiplex by kqueue(2)

=head1 SYNOPSIS

  use IO::Multiplex::KQueue;

  my $mux = new IO::Multiplex::KQueue;
  $mux->add($fh1);
  $mux->add(\*FH2);
  $mux->set_callback_object(...);
  $mux->listen($server_socket);
  $mux->loop;

  sub mux_input {
    ...
  }


=head1 DESCRIPTION

C<IO::Multiplex::KQueue> is kqueue(2) IO::Multiplex implementation with
compatible interface to C<IO::Multiplex> (version 1.08).
Please refer C<IO::Multiplex> for details.

Just install C<IO::KQueue> and replace C<IO::Multiplex> with
C<IO::Multiplex::KQueue> in your source code.

=head1 EXAMPLES

=head2 Orignal Source

    use IO::Socket;
    use IO::Multiplex;

    # Create a multiplex object
    my $mux  = new IO::Multiplex;

=head2 Using IO::Multiplex::KQueue

    use IO::Socket;
    use IO::Multiplex::KQueue;

    # Create a multiplex object
    my $mux  = new IO::Multiplex::KQueue;
    # done! no futher modification!

=cut

use strict;
use POSIX qw(errno_h BUFSIZ);
use vars qw($VERSION);
use Socket;
use FileHandle qw(autoflush);
use IO::Handle;
use Fcntl;
use Carp qw(carp);
use IO::KQueue;

$VERSION = '0.02';

BEGIN {
    eval {
        # Can optionally use Hi Res timers if available
        require Time::HiRes;
        Time::HiRes->import ('time');
    }
};

# This is what you want.  Trust me.
$SIG{PIPE} = 'IGNORE';

sub new
{
    my $package = shift;
    my $self = bless { _kq          => IO::KQueue->new(),
                       _fhs         => {},
                       _handles     => {},
                       _timerkeys   => {},
                       _timers      => [],
                       _listen      => {}  } => $package;
    return $self;
}

sub listen
{
    my $self = shift;
    my $fh   = shift;

    $self->add($fh);
    $self->{_fhs}{"$fh"}{listen} = 1;
}

sub add
{
    my $self = shift;
    my $fh   = shift;

    return if $self->{_fhs}{"$fh"};

    nonblock($fh);
    autoflush($fh, 1);
    $self->{_fhs}{"$fh"}{udp_true} =
        (SOCK_DGRAM == unpack("i", scalar getsockopt($fh,Socket::SOL_SOCKET(),Socket::SO_TYPE())));
    $self->{_fhs}{"$fh"}{inbuffer} = '';
    $self->{_fhs}{"$fh"}{outbuffer} = '';
    $self->{_fhs}{"$fh"}{fileno} = fileno($fh);
    $self->{_handles}{"$fh"} = $fh;
    #fd_set($self->{_readers}, $fh, 1);
    $self->EV_SET($fh, EVFILT_READ, EV_ADD, 0, 5, [$fh, EVFILT_READ]);
    tie *$fh, "IO::Multiplex::KQueue::Handle", $self, $fh;
    return $fh;
}

sub remove
{
    my $self = shift;
    my $fh   = shift;
    #fd_set($self->{_writers}, $fh, 0);
    #fd_set($self->{_readers}, $fh, 0);
    eval {
	# according to kqueue(2): Events which are attached to file
	# descriptors are automatically deleted on the last close of
	# the descriptor. (different behavior between select(2) and kqueue(2))
	# removing a fd which is already closed will cause "set kevent
        # failed: No such file or directory"
	$self->EV_SET($fh, EVFILT_READ, EV_DELETE);
	$self->EV_SET($fh, EVFILT_WRITE, EV_DELETE);
    };
    delete $self->{_fhs}{"$fh"};
    delete $self->{_handles}{"$fh"};
    $self->_removeTimer($fh);
    untie *$fh;
}

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

sub kill_output
{
    my $self = shift;
    my $fh   = shift;
    return unless $fh && exists($self->{_fhs}{"$fh"});

    $self->{_fhs}{"$fh"}{outbuffer} = '';
    $self->EV_SET($fh, EVFILT_WRITE, EV_DELETE);
}

sub outbuffer
{
    my $self = shift;
    my $fh   = shift;
    return unless $fh && exists($self->{_fhs}{"$fh"});

    if (@_) {
        $self->{_fhs}{"$fh"}{outbuffer} = $_[0] if @_;
        #fd_set($self->{_writers}, $fh, 0) if !$_[0];
	$self->EV_SET($fh, EVFILT_WRITE, EV_ADD, 0, 0, [$fh, EVFILT_WRITE]);
    }

    return $self->{_fhs}{"$fh"}{outbuffer};
}

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

sub loop
{
    my $self = shift;
    my $heartbeat = shift;
    $self->{_endloop} = 0;

    warn "heartbeat is not supported in IO::Multiplex::KQueue"
	if( $heartbeat );
    while (!$self->{_endloop} && keys %{$self->{_fhs}}) {
        my $rv;
        my $data;
        my $rdready;
        my $wrready;
        my $timeout = undef;
	my @results = undef;
        if (@{$self->{_timers}}) {
            $timeout = $self->{_timers}[0][1] - time;
        }

	@results = $self->{_kq}->kevent($timeout);

        unless(@results) {
            if ($! == EINTR || $! == EAGAIN) {
                next;
	    } elsif( @{$self->{_timers}} ){
		$self->_checkTimeouts();
		next;
	    } else {
		warn "kevent exists without event!?";
		next;
            }
        }

	foreach my $kevent (@results) {
	    my($fh, $action) = @{$kevent->[KQ_UDATA]};
            # Avoid creating a permanent empty hash ref for "$fh"
            # by attempting to access its {object} element
            # if it has already been closed.
            next unless exists $self->{_fhs}{"$fh"};

            # Get the callback object.
            my $obj = $self->{_fhs}{"$fh"}{object} ||
                $self->{_object};

            # Is this descriptor ready for reading?
	    if( $action == EVFILT_READ ){
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
			    warn "IO::Multiplex::KQueue read error: $!"
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
                        #fd_set($self->{_readers}, $fh, 0);
			$self->EV_SET($fh, EVFILT_READ, EV_DELETE);
                        $obj->mux_eof($self, $fh,
                                      \$self->{_fhs}{"$fh"}{inbuffer})
                            if $obj && $obj->can("mux_eof");

                        if (exists $self->{_fhs}{"$fh"}) {
                            delete $self->{_fhs}{"$fh"}{inbuffer};
                            # The mux_eof handler could have responded
                            # with a shutdown for writing.
                            $self->close($fh)
                                unless exists $self->{_fhs}{"$fh"} &&
                                    exists $self->{_fhs}{"$fh"}{outbuffer};
                        }
                        next;
                    }
                }
            }  # end if readable
            next unless exists $self->{_fhs}{"$fh"};

	    if( $action == EVFILT_WRITE ){
                unless ($self->{_fhs}{"$fh"}{outbuffer}) {
                    #fd_set($self->{_writers}, $fh, 0);
		    $self->EV_SET($fh, EVFILT_WRITE, EV_DELETE);
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
                unless ($self->{_fhs}{"$fh"}{outbuffer}) {
                    # Mark us as not writable if there's nothing more to
                    # write
                    #fd_set($self->{_writers}, $fh, 0);
		    $self->EV_SET($fh, EVFILT_WRITE, EV_DELETE);
                    $obj->mux_outbuffer_empty($self, $fh)
                        if ($obj && $obj->can("mux_outbuffer_empty"));

                    if ($self->{_fhs}{"$fh"}{shutdown}) {
                        # If we've been marked for shutdown after write
                        # do it.
                        shutdown($fh, 1);
                        delete $self->{_fhs}{"$fh"}{outbuffer};
                        unless (exists $self->{_fhs}{"$fh"}{inbuffer}) {
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

sub endloop
{
    my $self = shift;
    $self->{_endloop} = 1;
}

sub udp_peer {
  my $self = shift;
  my $fh = shift;
  return $self->{_fhs}{"$fh"}{udp_peer};
}

sub is_udp {
  my $self = shift;
  my $fh = shift;
  return $self->{_fhs}{"$fh"}{udp_true};
}

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
    #fd_set($self->{_writers}, $fh, 1);
    $self->EV_SET($fh, EVFILT_WRITE, EV_ADD, 0, 0, [$fh, EVFILT_WRITE]);
    return length($data);
}

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
        if ($self->{_fhs}{"$fh"}{outbuffer}) {
            $self->{_fhs}{"$fh"}{shutdown} = 1;
        } else {
            shutdown($fh, 1);
            delete $self->{_fhs}{"$fh"}{outbuffer};
        }
    }
    # Delete the descriptor if it's totally gone.
    unless (exists $self->{_fhs}{"$fh"}{inbuffer} ||
            exists $self->{_fhs}{"$fh"}{outbuffer}) {
        $self->close($fh);
    }
}

sub close
{
    my $self = shift;
    my $fh = shift;
    return unless exists $self->{_fhs}{"$fh"};

    my $obj = $self->{_fhs}{"$fh"}{object} || $self->{_object};
    warn "closeing with read buffer" if $self->{_fhs}{"$fh"}{inbuffer};
    warn "closeing with write buffer" if $self->{_fhs}{"$fh"}{outbuffer};

    #fd_set($self->{_readers}, $fh, 0);
    #fd_set($self->{_writers}, $fh, 0);
    #in kqueue(2):
    # Events which are attached to file descriptors are
    # automatically deleted on the last close of the descriptor.

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
{
    my $fh = shift;
    my $flags = fcntl($fh, F_GETFL, 0)
        or die "fcntl F_GETFL: $!\n";
    fcntl($fh, F_SETFL, $flags | O_NONBLOCK)
        or die "fcntl F_SETFL $!\n";
}

sub EV_SET
{
    my $self = shift;
    my $fh = shift;
    $self->{_kq}->EV_SET($self->{_fhs}{"$fh"}{fileno}, @_);
}

# We tie handles into this package to handle write buffering.

package IO::Multiplex::KQueue::Handle;

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

1;

__END__

=head1 BUGS

C<heartbeat> is not supported in IO::Multiplex::KQueue.

You may get several "read error: Operation timed out" warings.

=head1 NOTE

IO::KQueue 0.29 has a bug to handle timeout. please install
http://www.in2home.org/download/IO-KQueue-0.30.tar.gz or you
will fail t/110_ntest.t.

=head1 SEE ALSO

IO::Multiplex, IO::KQueue, kqueue(2).

=head1 AUTHOR

=head2 IO::Multiplex

Copyright 1999 Bruce J Keeler <bruce@gridpoint.com>

Copyright 2001-2003 Rob Brown <bbb@cpan.org>

=head2 IO::Multiplex::KQueue

Copyright 2005 Kai-Hsiang Chuang <in2@in2home.org>

Released under the terms of the Artistic License.

=cut
