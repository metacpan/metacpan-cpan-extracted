package IO::EventMux;
use strict;
use warnings;
use Carp qw(carp cluck croak);
# TODO: Look into adding queuing support to IO::EventMux:

# TODO: Add Timeout option to $mux->add and $mux->connect
#
#   # Try to connect within 10 sec
#   my $fh = $mux->connect("tcp://127.0.0.1:22", Timeout => 10); 
#   while(my $event = $mux->mux) {
#      if($event->{fh} eq $fh and $event->{type} eq 'connected') {
#           print "connected to 127.0.0.1:22 with $event->{fh}\n";
#      
#      } elsif($event->{fh} eq $fh and $event->{type} eq 'error') {
#           print "did not connect to 127.0.0.1:22 because of error: $event->{fh}";
#
#      } elsif($event->{fh} eq $fh and $event->{type} eq 'timeout') {
#           print "did not connect to 127.0.0.1:22 because of timeout";
#      }
#   }

# TODO: Add session identifier option to $mux->add for handling udp protocols 
#       where session information is hidden in a packet and not the fh.
#   
#   # Using fh and sender as identifier 
#   my $mux->add($fh, Meta => { ... }, MetaHandler => sub {
#      return $fh.$_[2]; # @_ = ($fh, $packet_data, $sender);
#   });
#
#   # Using fh and packet data as identifier 
#   my $mux->add($fh, Meta => { ... }, MetaHandler => sub {
#      return $fh.unpack("N", $_[1]); # @_ = ($fh, $packet_data, $sender);
#   });
#  
#   # Using fh as identifier, default 
#   my $mux->add($fh, Meta => { ... }, MetaHandler => sub {
#      return $_[0]; # @_ = ($fh, $packet_data, $sender);
#   });
#
#   while(my $event = $mux->mux) {
#       my $meta = $mux->meta($event->{id});
#   }
#


our $VERSION = '2.02';

=head1 NAME

IO::EventMux - Multiplexer for sockets, pipes and any other types of
filehandles that you can set O_NONBLOCK on and does buffering for the user.

=head1 SYNOPSIS

  use IO::EventMux;

  my $mux = IO::EventMux->new();

  $mux->add($my_fh);

  while (1) {
    my $event = $mux->mux();

    # ... do something with $event->{type} and $event->{fh}
  }

=head1 DESCRIPTION

This module provides multiplexing for any set of sockets, pipes, or whatever
you can set O_NONBLOCK on.  It can be useful for both server and client
processes, but it works best when the application's main loop is centered
around its C<mux()> method.

The file handles it can work with are either perl's own typeglobs or IO::Handle
objects (preferred).

=head1 METHODS

=cut

use IO::Select;
use IO::Socket;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Socket;
use Errno qw(EPROTO ECONNREFUSED ETIMEDOUT EMSGSIZE ECONNREFUSED EHOSTUNREACH 
             ENETUNREACH EACCES EAGAIN ENOTCONN ECONNRESET EWOULDBLOCK);
use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);
use POSIX qw(strerror);

use Scalar::Util qw(blessed);

# Define EPOLL constants as this needs to be done at compile time
use constant EPOLLIN       => 1;
use constant EPOLLOUT      => 4;
use constant EPOLLERR      => 8;
use constant EPOLLHUP      => 16;
use constant EPOLL_CTL_ADD => 1;
use constant EPOLL_CTL_DEL => 2;
use constant EPOLL_CTL_MOD => 3;

# Make nice fallback for socket_errors usage
eval "use IO::EventMux::Socket::MsgHdr qw(socket_errors);"; ## no critic
if($@) {
    *IO::EventMux::socket_errors = sub {
        die "You need to install IO::EventMux::Socket::MsgHdr"
            ." to use the Errors options";
    };
}

use constant {
    SOL_IP             => 0,
    IP_RECVERR         => 11,
};

# List of allowed options for add()
my %allowed_add_opts = map { $_ => 1 } qw(
    ManualRead ManualWrite ManualAccept
    ReadSize Buffered Type Errors
    Meta MetaHandler
);

=head2 B<new([%options])>

Constructs an IO::EventMux object.

The optional parameters for the handle will be taken from the IO::EventMux
object if not given here:

=cut

=head3 EventLoop

Defines what mechanism to use for the event loop, currently only two build in
are available; L<IO::Epoll> and L<IO::Select>. IO::Select being the default.

  my $mux = new IO::EventMux(EventLoop => [$mechanism, $args]);

IO::Epoll example for holding 1024 file handles:

  my $mux = new IO::EventMux(EventLoop => ["IO::Epoll", 1024]);

It's also possible to define your own, this is done by creating a hash that
implements the following structure:

  my $mux = new IO::EventMux(EventLoop => {
      Add => sub { 
        my($self, $list, $fh) = @_;
        ...
      },
      Wait => sub {
        my($self, $timeout) = @_;
        ...
        return {
            can_read => [$fh, ...],
            can_write => [$fh, ...],
        };
        
      },
      Remove => sub {
        my($self, $list, $fh) = @_;
        ...
      },
      Handles => sub {
        my($self) = @_;
        ...
      },
  });

=cut

sub new {
    my ($class, %opts) = @_;

    #$opts{EventLoop} = ['IO::Epoll', 1024];

    my %eventloopvars;
    if(my $eventloop = $opts{EventLoop}) {
        # FIXME: Make test for IO::Epoll
        if(ref $eventloop eq 'HASH') {
            *_eventloop_wait = \$eventloop->{Wait};
            *_eventloop_add = \$eventloop->{Add};
            *_eventloop_remove = \$eventloop->{Remove};
            *handles = \$eventloop->{Handles};
            %eventloopvars = %{$eventloop->{Vars}};
       
        } elsif(ref $eventloop eq 'ARRAY') {
            my ($type, @args) = @{$eventloop};

            if($type eq 'IO::Epoll') {
                require IO::Epoll;
                *epoll_create = *IO::Epoll::epoll_create;
                *epoll_ctl = *IO::Epoll::epoll_ctl;
                *epoll_wait = *IO::Epoll::epoll_wait;
                
                *_eventloop_wait = *_eventloop_wait_epoll;
                *_eventloop_add = *_eventloop_add_epoll;
                *_eventloop_remove = *_eventloop_remove_epoll;
                *handles = *_eventloop_handles_epoll;

                %eventloopvars = (    
                    epollfd =>  epoll_create($args[0]),
                    fds => {},
                ); 
            
            } elsif($type eq 'IO::Select') {
                goto EVENTLOOP_IO_SOCKET;
            
            } else {
                croak "Unsupport Eventloop type: $type";
            }
        
        } else {
            croak "EventLoop variriable needs to Array or Hash";
        }

    } else { #EVENTLOOP_IO_SOCKET:
        *_eventloop_wait = *_eventloop_wait_select;
        *_eventloop_add = *_eventloop_add_select;
        *_eventloop_remove = *_eventloop_remove_select;
        *handles = *_eventloop_handles_select;
        %eventloopvars = (    
            readfh        => IO::Select->new(),
            writefh       => IO::Select->new(),
        ); 
    }

    return bless {
        %eventloopvars,

        # GLOBAL
        auto_accept   => 1,
        auto_write    => 1,
        auto_read     => 1,
        auto_close    => 1,
        errors        => 0,
        read_size     => 65536,
        
        fhs           => { },
        sessions      => { },
        listenfh      => { },
        
        events        => [ ],
        actionq       => [ ],
        
        # FH only
        return_last   => 0,
        type          => 'stream',
        class         => 'socket',

    }, $class;
}

=head2 B<mux([$timeout])>

This method will block until ether an event occurs on one of the file handles
or the $timeout (floating point seconds) expires.  If the $timeout argument is
not present, it waits forever.  If $timeout is 0, it returns immediately.

The return value is always a hash, which always has the key 'type', indicating
what kind it is.  It will also usually carry the 'fh' key, indicating what file
handle the event happened on.

The 'type' key can have the following values:

=over

=item timeout

Nothing happened and timeout occurred.

=item error

An error occurred in connection with the file handle, such as 
"connection refused", etc.

=item accepted

A new client connected to a listening socket and the connection was accepted by
EventMux. The listening socket file handle is in the 'parent_fh' key. If the 
file handle is a unix domain socket the credentials of the user connection will be available in the keys; 'pid', 'uid' and 'gid'. 

=item ready 

A file handle is ready to be written to, this can be use full when working with
nonblocking connects so you know when the remote connection accepted the
connection.

=item accepting

A new client is trying to connect to a listening socket, but the user code must
call accept manually.  This only happens when the ManualAccept option is
set.

=item read

A socket has incoming data.  If the socket's Buffered option is set, this
will be what the buffering rule define.

The data is contained in the 'data' key of the event hash.  If recv() 
returned a sender address, it is contained in the 'sender' key and must be 
manually unpacked according to the socket domain, e.g. with 
C<Socket::unpack_sockaddr_in()>.

=item read_last

A socket last data before it was closed did not match the buffering rules, as defined by the IO::Buffered type given. he read_last type contains the result of a call to C<read_last()> on the chosen buffer type.

The default is not to return read_last and if no buffer is set read will contain this information.

=item sent

A socket has sent all the data in it's queue with the send call. This however
does not indicate that the data has reached the other end, normally only that
the data has reached the local buffer of the kernel.

=item closing

A file handle was detected to be have been closed by the other end or the file 
handle was set to be closed by the user. So EventMux stooped listening for 
events on this file handle. Event data like 'Meta' is still accessible.

The 'missing' key indicates the amount of data or packets left in the user 
space buffer when the file handle was closed. This does not indicate the amount
of data received by the other end, only that the user space buffer left. 

=item closed

A socket/pipe was disconnected/closed, the file descriptor, all internal 
references, and data store with the file handle was removed.

=item can_write

The ManualWrite option is set for the file handle, and C<select()> has
indicated that the handle can be written to.

=item can_read

The ManualRead option is set for the file handle, and C<select()> has
indicated that the handle can be read from.

=back

=cut

sub mux {
    my ($self,$timeout) = @_;
    my $event;

    croak "timeout can not be negativ: $timeout"
        if defined $timeout and $timeout < 0;

    until ($event = shift @{$self->{events}}) {
        # actions to execute?
        if (my $action = shift @{$self->{actionq}}) {
            $action->($self);
        } else {
            $self->_get_event($timeout);
        }
    }
    
    return $event;
}

sub _get_event {
    my ($self, $timeout) = @_;
   
    # TODO: with EPOLL we get fh errors as events, EPOLLERR 
    #       use this to be smarter about how we handle them
    my $select = _eventloop_wait($self, $timeout);
    if(!$select) {
        $self->push_event({ type => 'timeout' });
        return;
    }

    # buffers to flush?, can_write is set.
    for my $fh (@{$select->{can_write}}) {
        my $cfg = $self->{fhs}{$fh};

        if(exists $cfg->{ready} and $cfg->{ready} == 0) {
            $cfg->{ready} = 1;

            if($cfg->{class} eq 'socket') {
                my $perror = getsockopt($fh, SOL_SOCKET, SO_ERROR);
                if(defined $perror) {
                    my $error = unpack("i", $perror);
                    if($error == 0) {
                        $self->push_event({ type => 'ready', fh => $fh });
                    } else {
                        $self->push_event({ type => 'error', fh => $fh, 
                            error => strerror($error),
                        });
                    }
                }
            
            } else {            
                $self->push_event({ type => 'ready', fh => $fh });
            }

        } elsif ($self->{fhs}{$fh}{auto_write}) {
            if ($cfg->{type} eq "dgram") {
                $self->_send_dgram($fh);
            } else {
                $self->_send_stream($fh);
            }

        } else {
            $self->push_event({ type => 'can_write', fh => $fh });
        }
    }
        
    # incoming data, can_read is set.
    for my $fh (@{$select->{can_read}}) {
        my $cfg = $self->{fhs}{$fh};
        
        if ($self->{listenfh}{$fh}) {
            # new connection
            if ($cfg->{auto_accept}) {
                my $newfh = $fh->accept or next;
                
                my %creds;
                if($cfg->{class} eq 'socket') {
                    %creds = $self->socket_creds($newfh);
                }
                
                $self->push_event({ type => 'accepted', fh => $newfh,
                    parent_fh => $fh, %creds});
                
                # Add accepted client to IO::EventMux
                $self->add($newfh, %{$self->{fhs}{$fh}{opts}}, Listen => 0);
                
                # Set ready as we already sent a connect.
                $self->{fhs}{$newfh}{ready} = 1;
            
            } else {
                $self->push_event({ type => 'accepting', fh => $fh });
            }

        } elsif (!$self->{fhs}{$fh}{auto_read}) {
            $self->push_event({ type => 'can_read', fh => $fh });

        } else {
            $self->_read_all($fh);
        }
    }
}

sub _eventloop_handles_select {
    my ($self) = @_;
    return $self->{readfh}->handles;
}

sub _eventloop_add_select {
    my ($self, $list, $fh) = @_;
    $self->{$list}->add($fh);
}

sub _eventloop_remove_select {
    my ($self, $list, $fh) = @_;
    $self->{$list}->remove($fh);
}

sub _eventloop_wait_select {
    my ($self, $timeout) = @_;

    $! = 0;
    # TODO : handle OOB data and exceptions
    my @result = IO::Select->select($self->{readfh}, $self->{writefh},
        [@{$self->{readfh}}, @{$self->{writefh}}], $timeout);
    
    #use Data::Dumper; print Dumper({readeble => $result[0], writeble =>
    #   $result[1], exception => $result[2]}) if @result > 0;
    
    if (@result > 0) {
        return { 
            can_read => $result[0], 
            can_write => $result[1],
        };
    } else {
        if ($!) {
            die "Died because of error in IO::Select: $!";
        }
        return;
    }
}


sub _eventloop_handles_epoll {
    my ($self) = @_;

    return map { $_->[0] } values %{$self->{fds}};
}

sub _dumpflags {
    my @flags;
    push(@flags, "EPOLLIN") if EPOLLIN & $_[0];
    push(@flags, "EPOLLOUT") if EPOLLOUT & $_[0];
    push(@flags, "EPOLLERR") if EPOLLERR & $_[0];
    push(@flags, "EPOLLHUP") if EPOLLHUP & $_[0];
    return join("|", @flags);
}

sub _eventloop_add_epoll {
    my ($self, $list, $fh) = @_;
    my $fd = fileno $fh;
    $self->{fhs}{$fh}{fd} = $fd;

    #my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, 
    #    $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(0);

    my $mask = $list eq 'writefh' ? EPOLLOUT : EPOLLIN;
  
    $mask |= EPOLLERR|EPOLLHUP; 

    if(my $cfd = $self->{fds}{$fd}) {
        $mask |= $cfd->[1];
        #print "modadd: $package\::$subroutine $line : $fh : "._dumpflags($mask)."\n";
        epoll_ctl($self->{epollfd}, EPOLL_CTL_MOD, $fd, $mask) >= 0 
            or croak("->add($fh, ...) : epoll_ctl($self->{epollfd}, "
            ."EPOLL_CTL_MOD, $fd, $mask): $!\n");
    } else {
        #print "add: $package\::$subroutine $line : $fh : "._dumpflags($mask)."\n";
        epoll_ctl($self->{epollfd}, EPOLL_CTL_ADD, $fd, $mask) >= 0 
            or croak("->add($fh, ...) : epoll_ctl($self->{epollfd}, "
            ."EPOLL_CTL_ADD, $fd, $mask): $!\n");
    }

    $self->{fds}{$fd} = [$fh, $mask];
}

sub _eventloop_remove_epoll {
    my ($self, $list, $fh) = @_;
    my $fd = $self->{fhs}{$fh}{fd};

    #print "$fh -> $fd\n";
    #use Data::Dumper; print Dumper($self->{fds});
   
    #my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, 
    #    $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(0);
    
    my $mask = $list eq 'writefh' ? EPOLLIN : EPOLLOUT;
    
    $mask |= EPOLLERR|EPOLLHUP; 
    
    if(my $cfd = $self->{fds}{$fd}) {
        if(($cfd->[1] & EPOLLIN and $cfd->[1] & EPOLLOUT)) {
            $cfd->[1] = $mask;
            #print "modrem($list): $package\::$subroutine $line : $fh : "._dumpflags($mask)."\n";
            epoll_ctl($self->{epollfd}, EPOLL_CTL_MOD, $fd, $mask) >= 0 
                or croak("->add($fh, ...) : epoll_ctl($self->{epollfd}, "
                ."EPOLL_CTL_MOD, $fd, EPOLLIN): $!\n");
        } elsif($cfd->[1] & ($list eq 'writefh' ? EPOLLOUT : EPOLLIN)) {
            #print "remove($list): $package\::$subroutine $line : $fh : "._dumpflags($mask)."\n";
            epoll_ctl($self->{epollfd}, EPOLL_CTL_DEL, $fd, 0);
            delete $self->{fds}{$fd};
        }
    }
}


sub _eventloop_wait_epoll {
    my ($self, $timeout) = @_;

    $timeout = defined $timeout ? $timeout * 1000 : -1; 

    # Max 100 events returned, 1s resolution
    my $events = epoll_wait($self->{epollfd}, 100, $timeout)
        or die "Died because of error in epoll_wait: $!";
    
    # Return undef if timed out.
    return if @{$events} == 0;

    my %select;
    foreach my $event (@{$events}) {
        my ($fh) = @{$self->{fds}{$event->[0]}};
        #print "event: $fh\n";
        if($event->[1] & EPOLLIN) {    
            push(@{$select{can_read}}, $fh);
        } elsif($event->[1] & EPOLLOUT) {
            push(@{$select{can_write}}, $fh);
        } elsif($event->[1] & EPOLLERR|EPOLLHUP) {
            push(@{$select{can_read}}, $fh);
        }
    }

    return \%select;
}


=head2 B<add($handle, [ %options ])>

Add a socket to the internal list of handles being watched.

The optional parameters for the handle will be taken from the IO::EventMux
object if not given here:

=head3 Listen

Defines if the file handle should be treated as a listening socket, the default
is to auto detect this. I should not be necessary to set this value.

The socket must be set up for listening, which is easily done with
IO::Socket::INET:

  my $listener = IO::Socket::INET->new(
    Listen    => 5,
    LocalPort => 7007,
    ReuseAddr => 1,
  );

  $mux->add($listener);

=head3 Type

Either "stream" or "dgram". Should be auto detected in most cases.

Defaults to "stream".

=head3 ManualAccept

If a connection comes in on a listening socket, it will by default be accepted
automatically, and C<mux()> will return a 'connect' event.  If ManualAccept is set
an 'accepting' event will be returned instead, and the user code must handle it
itself.

  $mux->add($my_fh, ManualAccept => 1);

=head3 ManualWrite

By default EventMux handles nonblocking writing and you should use
C<$mux->send($fh, $data)> or C<$mux->sendto($fh, $addr, $data)> to send your data,
but if for some reason you send data yourself you can tell EventMux not to do
writing for you and generate a 'can_write' event instead.
    
  $mux->add($my_fh, ManualWrite => 1);

In both cases you can use C<send()> to write data to the file handle.

Note: If both ManualRead and ManualWrite is set, EventMux will not set the 
socket to nonblocking. 

=head3 ManualRead

By default EventMux will handle nonblocking reading and generate a read event
with the data, but if some reason you would like to do the reading yourself 
you can have EventMux generate a 'can_read' event for you instead.
    
  $mux->add($my_fh, ManualRead => 1);

Never read or recv on the file handle. When the socket becomes readable, a
C<can_read()> event is returned.

Note: If both ManualRead and ManualWrite is set, EventMux will not set the 
socket to nonblocking. 

=head3 ReadSize

By default IO::EventMux will try to read 65536 bytes from the file handle, setting
this options to something smaller might help make it easier for EventMux to be
fair about how it returns it's event, but will also give more overhead as more
system calls will be required to empty a file handle.

=head3 Errors

By default IO::EventMux will not deal with socket errors on non connected sockets
such as a UDP socket in listening mode or where no peer has been defined. Or
in other words whenever you use C<sendto()> on socket. When enabling error 
handling, IO::EventMux sets the socket to collect errors with the MSG_ERRQUEUE 
option and collect errors with C<recvmsg()> call.

Errors are sent as error events with a little more information than normal, eg: 

  $event = {
    data     => 'packet data',
    dst_port => 'destination port',
    from     => 'ip where the error is from',
    dst_ip   => 'destination ip',
  }

=head3 Meta

An optional scalar piece of metadata for the file handle. Can be retrieved and
manipulated later with meta()

=head3 Buffered

IO::EventMux supports buffering of data before generating events, this can be used to only return events when a "complete" event is done. For this IO::EventMux uses IO::Buffered. 

  # Would only return when a complete line 
  $mux->add($goodfh, Buffered => new IO::Buffered(Split => qr/\n/));

Read more here: L<IO::Buffered>

=cut

sub add {
    my ($self, $fh, %opts) = @_;

    croak "undefined file handle given" if !defined $fh;
    croak "file handle already added: $fh" if $self->{fhs}{$fh}; 
    croak "Buffered is not a IO::Buffered object" if defined $opts{Buffered} 
        and !(blessed($opts{Buffered}) 
        and $opts{Buffered}->isa('IO::Buffered'));
    croak "MetaHandler is not a code ref" if defined $opts{MetaHandler} 
        and !(ref $opts{MetaHandler} eq 'CODE');

    # Init for new fh
    $self->{fhs}{$fh} = {
        errors => (exists $opts{Errors} ? $opts{Errors} : $self->{errors}),
        type => 'stream',
        auto_accept => (exists $opts{ManualAccept} ? !$opts{ManualAccept} 
            : $self->{auto_accept}),
        auto_write => (exists $opts{ManualWrite} ? !$opts{ManualWrite}
            : $self->{auto_write}),
        auto_read => (exists $opts{ManualRead} ? !$opts{ManualRead}
            : $self->{auto_read}),
        read_size => (exists $opts{ReadSize} ? $opts{ReadSize}
            : $self->{read_size}),
        # Save %opts, so we can given it to $fh->accept() children.
        opts => \%opts,
        inbuffer => (defined $opts{Buffered} ? $opts{Buffered} : undef),
        meta_handler => (exists $opts{MetaHandler} ? $opts{MetaHandler} : undef),
        mode => 'normal',
    };
  
    # Set the initial session/Meta information
    if(exists $opts{Meta}) {
        $self->{sessions}{$fh} = $opts{Meta};
    }

    my $cfg = $self->{fhs}{$fh}; 

    # Check if we can set the socket nonblocking
    if($cfg->{auto_read} or $cfg->{auto_write} or $opts{Listen}) {
        $self->nonblock($fh);
    }
    
    # Check if it's a socket and what the type is
    if(my $type = $self->socket_type($fh)) {
        $cfg->{class} = 'socket';
        $cfg->{type} = $type;
       
        if($self->socket_listening($fh)) {
            $self->{listenfh}{$fh} = 1;
        }

    } else {
        $cfg->{class} = 'other';
    }
   
    # Override what has been detected 
    $self->{listenfh}{$fh} = 1 if $opts{Listen};
    $cfg->{type} = $opts{Type} if exists $opts{Type};

    if($cfg->{type} eq 'stream') {
        # Return a ready event by creating ready option
        $cfg->{ready} = 0;

        # Use string out buffer for stream
        $cfg->{outbuffer} = '';

        if($cfg->{inbuffer}) {
            # Should an event of read_last be returned for this buffer type
            $cfg->{return_last} = $opts{Buffered}->returns_last();
        }

    } else {
        croak "Can't use Buffered for dgram file handles" if $cfg->{inbuffer};
        
        # Set socket to recieve errors
        setsockopt($fh, SOL_IP, IP_RECVERR, 1) if $cfg->{errors};
        
        # Use array out buffer for dgram
        @{$cfg->{outbuffer}} = ();
    }

    if (!exists $self->{listenfh}{$fh}) {
        _eventloop_add($self, "writefh",$fh);
    }
    _eventloop_add($self, "readfh", $fh);

    # Find out if this object has it's own recv() function else use sysread()
    if (blessed($fh) && $fh->can('recv')) {
        $cfg->{read} = sub {
            my ($fh, $readsize, $flags) = @_;
            my $data = '';
            my $sender = $fh->recv($data, $readsize, ($flags or 0));
            croak $! if !defined $sender;
            return (($sender or undef), $data); 
        }; 
    
    } else {
        $cfg->{read} = sub {
            my ($fh, $readsize, $flags) = @_;
            my $data = '';
            my $rv = sysread($fh, $data, $readsize);
            croak $! if !defined $rv;
            return(undef, $data);
        };
        
    }

    # Find out if this object has it's own send() function else use syswrite()
    if(blessed($fh) && $fh->can('send')) {
        $cfg->{write} = sub {
            my ($fh, $data, @to) = @_;
            my $rv = $fh->send($data, 0, @to);
            croak $! if !defined $rv;
            return $rv;
        }
    } else {
        $cfg->{write} = sub {
            my ($fh, $data) = @_;
            my $rv = syswrite($fh, $data);
            croak $! if !defined $rv;
            return $rv;
        }
    }
}


=head2 B<listen()>

Wrapper around connect() with option (Listen => SOMAXCONN) set 

=cut

sub listen {
    my ($self) = shift;

    # Put Listen first in argument list so the user can override it
    if(@_ % 2) {
        my ($url, %opts) = @_;
        $self->connect($url, Listen => SOMAXCONN, %opts);
    } else {
        my (%opts) = @_;
        $self->connect(Listen => SOMAXCONN, %opts);
    }
}

=head2 B<connect()>

Connect and add a socket to IO::EventMux, by using either URL syntax or
IO::Socket Syntax. All options related to IO::EventMux is passed when calling
add() on the new socket. Connect returns the new socket on completion.

URL Syntax supports this format:

 * (tcp|udp)://HOST:PORT, Returns a udp of tcp socket.
 * (unix|unix_dgram)://path/file.sock, Returns a unix domain socket connection.

For more information on how to use IO::Socket syntax look in
L<IO::Socket::INET> and L<IO::Socket::UNIX>.

Example of URL syntax; making a connection to localhost port 22

  my $fh = $mux->connect("tcp://127.0.0.1:22");

Example of the same thing in IO::Socket Syntax;
  
  my $fh = $mux->connect(
    Proto => 'tcp',
    PeerAddr => '127.0.0.1',
    PeerPort => 22,
  );

=cut

sub connect {
    my ($self) = shift;
    croak "no arguments given" if @_ == 0;
    
    # Check if we called with url_connect or IO::Socket syntax
    if(@_ % 2) { # url_connect
        my ($url, %opts) = @_;
        croak "url not defined" if !defined $url;
        
        # FIXME: Use Misc::Regexp
        if ($url =~ m{^(tcp|udp)://(\d+\.\d+\.\d+\.\d+):(\d+)$}) {
            my ($proto, $ip, $port) = ($1, $2, $3);
            
            my %sopts = (
                Proto => $proto,
                Type => ($proto eq 'tcp' ? SOCK_STREAM : SOCK_DGRAM),
                Blocking => 0,
                ($opts{Listen} ?(Listen => $opts{Listen}):()),
            );

            my $fh;
            if($opts{Listen}) {
                # Only TCP supports the Listen option
                delete $sopts{Listen} if $proto eq 'udp';
                delete $opts{Listen} if $proto eq 'udp';
                
                $fh = IO::Socket::INET->new(
                    ($ip?(LocalAddr => $ip):()),
                    ($port?(LocalPort => $port):()),
                    ReuseAddr => 1,
                    %sopts,
                ) or croak "Listening to $url: $!";
            
            } else {
                $fh = IO::Socket::INET->new(
                    ($ip?(PeerAddr => $ip):()),
                    ($port?(PeerPort => $port):()),
                    %sopts,
                ) or croak "Connection to $url: $!";
            }

            $self->add($fh, %opts);
            return $fh;
    
        } elsif($url =~ m{^unix(?:_(dgram))?://(.+)$}) {
            my ($dgram, $file) = ($1, $2);
            
            my %sopts = (
                ($dgram?(Type => SOCK_DGRAM):()),
                Blocking => 0,
            );
                
            my $fh;
            if($opts{Listen}) {
                $fh = IO::Socket::UNIX->new(
                    Peer => $file,
                    %sopts,
                ) or croak "Listening to $url: $!";
            
            } else {
                $fh = IO::Socket::UNIX->new(
                    Local => $file,
                    %sopts,
                ) or croak "Connecting to $url: $!";
            }

            delete $opts{Listen};
            $self->add($fh, %opts);
            return $fh;
    
        } else {
            croak "unknown url type: $url";
        }
   
    } else { # IO::Socket
        my (%opts) = @_;
        
        # Get list of options that are for IO::Socket
        my (%sopts) = map { $_ => $opts{$_} } 
                      grep { !exists $allowed_add_opts{$_} } keys %opts;
        
        # Remove Socket options from add options, but keep Listen
        %opts = map { $_ => $opts{$_} } 
                grep { !exists $sopts{$_} or $_ eq 'Listen'} keys %opts;

        # Check if this is a tcp or udp socket
        if(defined $sopts{Proto}) {
            # Only TCP supports the Listen option
            delete $sopts{Listen} if $sopts{Proto} eq 'udp';
            delete $opts{Listen} if $sopts{Proto} eq 'udp';
           
            my $fh = IO::Socket::INET->new(
                Blocking => 0,
                %sopts,
            ) or croak "Could not create IO::Socket::INET: $!";
            
            $self->add($fh, %opts);
            return $fh;

        # Check if this is a UNIX domain socket
        } elsif(defined $sopts{Local} or defined $sopts{Peer}) {
            my $fh = IO::Socket::UNIX->new(
                Blocking  => 0,
                %sopts,
            ) or croak "Could not create IO::Socket::UNIX: $!";
            
            $self->add($fh, %opts);
            return $fh;
        
        } else {
            croak "unknown socket options set or no Proto defined";
        }
    }
}

=head2 B<set()>

Set new options on a fh in IO::EventMux, currently only Buffered options is handled

=cut

sub set {
    my ($self, $fh, %opts) = @_;
    
    croak "undefined file handle given" if !defined $fh;
    croak "$fh not handled by IO::EventMux" if !exists $self->{fhs}{$fh};
    croak "Buffered is not a IO::Buffered object" if defined $opts{Buffered} 
        and !(blessed($opts{Buffered}) 
        and $opts{Buffered}->isa('IO::Buffered'));

    my $cfg = $self->{fhs}{$fh};
    my $inbuffer = $cfg->{inbuffer}; 

    if(exists $opts{Buffered}) { 
        if(defined $opts{Buffered}) {
            if(blessed($inbuffer)) {
                $opts{Buffered}->write($inbuffer->buffer());
            } else {
                $opts{Buffered}->write($inbuffer);
            }
        }
        $cfg->{inbuffer} = $opts{Buffered};
    }
}


=head2 B<handles()>

Returns a list of file handles managed by this object.

=cut

sub handles {  } # Stub - is created in new()

=head2 B<has_events()>

Returns true if there are pending events, or false otherwise

=cut

sub has_events {
    my ($self) = @_;
    return @{$self->{events}} + @{$self->{actionq}};
}

=head2 B<type()>

Returns the socket type for a file handle

=cut

sub type {
    my ($self, $fh) = @_;
    return $self->{fhs}{$fh}{type};
}

=head2 B<class()>

Returns the socket class for a file handle

=cut

sub class {
    my ($self, $fh) = @_;
    return $self->{fhs}{$fh}{class};
}

=head2 B<meta($fh, [$newval])>

Set or get a piece of metadata on the filehandle. This can be any scalar value.

=cut

sub meta {
    my ($self, $id, $newval) = @_;
    return if !defined $id; 

    if (@_ > 2) {
        $self->{sessions}{$id} = $newval;
    }

    return $self->{sessions}{$id};
}

=head2 B<remove($fh)>

Make EventMux forget about a file handle. The caller will then take over the
responsibility of closing it.

=cut

sub remove {
    my ($self, $fh) = @_;

    _eventloop_remove($self, "readfh", $fh);
    _eventloop_remove($self, "writefh", $fh);
    delete $self->{listenfh}{$fh};
    delete $self->{fhs}{$fh};
}


=head2 B<close($fh)>

Close a file handle. IO::EventMux will stop listing to both reads and writes on
the file handle and return a "closing" event and on next C<mux> call kill will
be called, returning "closed" for the file handle.

Note: All 'Meta' data associated with the file handle will be kept until the 
final 'closed' event is returned.

=cut

sub close {
    my ($self, $fh) = @_;
    return if !exists $self->{fhs}{$fh}; # Only remove if we handle this fh

    return if $self->{fhs}{$fh}{disconnecting};
    $self->{fhs}{$fh}{disconnecting} = 1;
    
    delete $self->{listenfh}{$fh};
    _eventloop_remove($self, "readfh", $fh);
    _eventloop_remove($self, "writefh", $fh);
    
    $self->push_event({ type => 'closing', fh => $fh });
    
    # wait with the close so a valid file handle can be returned
    push @{$self->{actionq}}, sub {
        $self->kill($fh);
    };
}

=head2 B<kill($fh)>

Closes a file handle without giving time to finish any outstanding operations. 
Returns a 'closed' event, deletes all buffers and does not keep 'Meta' data.

Note: Does not return the 'read_last' event.

=cut

sub kill {
    my ($self, $fh) = @_;
    return if !exists $self->{fhs}{$fh}; # Only remove if we handle this fh

    _eventloop_remove($self, "readfh", $fh);
    _eventloop_remove($self, "writefh", $fh);

    $self->push_event({ type => 'closed', fh => $fh, 
            missing => $self->buflen($fh) });
    
    $self->_close_fh($fh);
}

sub _close_fh {
    my ($self, $fh) = @_;

    if ($self->{fhs}{$fh}) {
        delete $self->{fhs}{$fh};
        shutdown $fh, 2;
        CORE::close $fh or croak "closing $fh: $!";
    }
}

=head2 B<buflen($fh)>

Queries the length of the output buffer for this file handle.  This only
applies if ManualWrite is turned off, which is the default. For Type="dgram"
sockets, it returns the number of datagrams in the queue.

An application can use this method to see whether it should send more data or
wait until the buffer queue is a bit shorter.

=cut

sub buflen {
    my ($self, $fh) = @_;
    my $cfg = $self->{fhs}{$fh};

    croak "$fh not handled by EventMux" if !$cfg;

    if ($cfg->{type} eq "dgram") {
        return $cfg->{outbuffer} ? scalar(@{$cfg->{outbuffer}}) : 0;
    }

    return $cfg->{outbuffer} ? length($cfg->{outbuffer}) : 0;
}


=head2 B<recvdata($fh, $length)>

TODO: Queues @data to be written to the file handle $fh. Can only be used when ManualWrite is
off (default).

=cut

# FIXME: Cleanup, remove print
sub recvdata {
    my ($self, $fh, $length) = @_;
    my $cfg = $self->{fhs}{$fh}; 
    
    if(my $buffer = $cfg->{inbuffer}) {
        $cfg->{recvlength} = $length;
        print "length: $length\n";
        foreach my $record ($buffer->read($cfg->{recvlength})) {
            $self->push_event({ type => 'read', fh => $fh, 
                data => $record });
            delete $cfg->{recvlength}; 
        }
    }
}


=head2 B<send($fh, @data)>

Queues @data to be written to the file handle $fh. Can only be used when ManualWrite is
off (default).

=over

=item If the socket is of Type="stream"

Returns true on success, undef on error. The data is sent when the socket
becomes unblocked and a 'sent' event is posted when all data is sent and the 
buffer is empty. Therefore the socket should not be closed until 
L</B<buflen($fh)>> returns 0 or a sent request has been posted.  

=item If the socket is of Type="dgram"

Each item in @data will be sent as a separate packet.  Returns true on success
and undef on error.

=back

=cut

sub send {
    my ($self, $fh, @data) = @_;
    return $self->sendto($fh, undef, @data);
}

=head2 B<sendto($fh, $to, @data)>

Like C<send()>, but with the recepient C<$to> as a packed sockaddr structure,
such as the one returned by C<Socket::pack_sockaddr_in()>. Only for Type="dgram"
sockets.

  $mux->sendto($my_fh, pack_sockaddr_in($port, inet_aton($ip)), $data);

=cut

sub sendto {
    my ($self, $fh, $to, @data) = @_;

    croak "send() on an undefined file handle" if !defined $fh;

    my $cfg = $self->{fhs}{$fh};

    croak "send() on filehandle not handled by IO::Eventmux" if !$cfg;

    return if $cfg->{disconnecting};

    if (not $cfg->{auto_write}) {
        croak "send() on a ManualWrite file handle";
        return;
    }

    if ($cfg->{type} eq "dgram") {
        push @{$cfg->{outbuffer}}, map { [$_, $to] } @data;
        my $rv = $self->_send_dgram($fh);
        
        if(@{$cfg->{outbuffer}}) {
            _eventloop_add($self, "writefh", $fh);
        }

        return $rv;
    
    } else {
        $cfg->{outbuffer} .= join('', @data);
        my $rv = $self->_send_stream($fh);
    
        if(length $cfg->{outbuffer}) {
            _eventloop_add($self, "writefh", $fh);
        }

        return $rv;
    }
}

sub _send_dgram {
    my ($self, $fh) = @_;
    my $cfg = $self->{fhs}{$fh};
    my $write = $self->{fhs}{$fh}{write};
    my $packets_sent = 0;

    if (@{$cfg->{outbuffer}} == 0) {
        # no data to send
        _eventloop_remove($self, "writefh", $fh);
        return;
    }

    while (my $queue_item = shift @{$cfg->{outbuffer}}) {
        my ($data, $to) = @$queue_item;
      
        croak "Trying to send undef" if !defined $data;

        my $rv = eval { $write->($fh, $data, (defined $to ? $to : ())); };
           
        # Clean up error
        $@ =~ s/\s*at \S+ line [\d\.]+\n//g;

        if ($@ =~ /Resource temporarily unavailable/) {
            # retry later
            unshift @{$cfg->{outbuffer}}, $queue_item;
            return $packets_sent;
            
        } elsif($@ and $cfg->{errors} and my @events = socket_errors($fh)) {
            unshift @{$cfg->{outbuffer}}, $queue_item;
            $self->push_event(@events);
            next;
        
        } elsif($@) {
            # FIXME: Add MetaHandler id to error information
            $self->push_event({ type => 'error', error => "$@", fh => $fh, 
                    receiver => $to });   
            return;
        
        } elsif ($rv < length $data) {
            die "Incomplete datagram sent (should not happen)";

        } else {
            # all pending data was sent
            $packets_sent++;
        }
    }
   
    # Buffer is empty and stop listening to write
    $self->push_event({type => 'sent', fh => $fh});
    _eventloop_remove($self, "writefh", $fh);

    return $packets_sent;
}

sub _send_stream {
    my ($self, $fh) = @_;
    my $cfg = $self->{fhs}{$fh};
    my $write = $self->{fhs}{$fh}{write};

    #my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, 
    #    $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(0);
    # 
    #print "sendstream $line\n";

    if ($cfg->{outbuffer} eq '') {
        # no data to send
        _eventloop_remove($self, "writefh", $fh);
        return;
    }

    my $rv = eval { $write->($fh, $cfg->{outbuffer}); };

    # Clean up error
    $@ =~ s/\s*at \S+ line [\d\.]+\n//g;

    # Check for undef or -1 as both can be error retvals 
    if ($@ =~ /Resource temporarily unavailable/) {
        return;
    
    } elsif($@ =~ /Bad file descriptor/) {
        $self->push_event({ type => 'error', error => "$@", fh => $fh });   
        $self->push_event({ type => 'closing', fh => $fh });
        $self->kill($fh);
        return;
    
    } elsif($@ =~ /Cannot determine peer address/ and $cfg->{ready} == 0) {
        # To soon to send data, retry when we get a ready
        return;

    } elsif($@) {
        $self->push_event({ type => 'error', error => "$@", fh => $fh });   
        return;

    } elsif ($rv < length $cfg->{outbuffer}) {
        # only part of the data was sent
        substr($cfg->{outbuffer}, 0, $rv) = '';
        _eventloop_add($self, "writefh", $fh);
        
    } else {
        # all pending data was sent
        $cfg->{outbuffer} = '';
        _eventloop_remove($self, "writefh", $fh);

        if($cfg->{ready} == 0) {
            $cfg->{ready} = 1;
            $self->push_event({ type => 'ready', fh => $fh });
        }
        
        $self->push_event({type => 'sent', fh => $fh});
    }


    return $rv;
}

=head2 B<push_event($event)> 

Push event on queue

=cut

sub push_event {
    my($self, @events) = @_;
    push(@{$self->{events}}, @events);
}

=head2 B<nonblock($fh)> 

Puts socket into nonblocking mode.

=cut

sub nonblock {
    my $socket = $_[1];

    my $flags = fcntl($socket, F_GETFL, 0)
        or die "Can't get flags for socket: $!\n";
    if (not $flags & O_NONBLOCK) {
        fcntl($socket, F_SETFL, $flags | O_NONBLOCK)
            or die "Can't make socket nonblocking: $!\n";
    }
}

=head2 B<socket_creds($fh)>

Return credentials on UNIX domain sockets.

=cut

sub socket_creds {
    my ($self, $fh) = @_;
    my %creds;

    # TODO: Support localhost TCP via: /proc/net/tcp
    my $rv = getsockopt($fh, SOL_SOCKET, SO_PEERCRED);
    if(defined $rv) {
        my ($pid, $uid, $gid) = unpack('LLL', $rv);
        %creds = (pid => $pid, uid => $uid, gid => $gid);
    }

    return %creds;
}


=head2 B<socket_type($fh)>

Return socket type.

=cut

sub socket_type {
    my ($self, $fh) = @_;
   
    my $ptype = getsockopt($fh, SOL_SOCKET, SO_TYPE);
    if(defined $ptype) {
        my $type = unpack("S", $ptype);
        if($type == SOCK_STREAM) { # type = 1
            return 'stream';

        } elsif($type == SOCK_DGRAM or $type == SOCK_RAW) { # type = 2,3
            return 'dgram';
        
        } else {
            croak "Unknown socket type: $type";
        }

    } else {
        return;
    }
}


=head2 B<socket_listening($fh)>

Check if the socket is set to listening mode

=cut

sub socket_listening {
    my ($self, $fh) = @_;
    my $listening = getsockopt($fh, SOL_SOCKET, SO_ACCEPTCONN);
    if(defined $listening) {
        return unpack("I", $listening);
    } else {
        return;
    }
}


=head2 recroak()

Helper function to rethrow croaks

=cut

sub recroak {
  $_[0] =~ s/ at \S+ line \d+.*$//s;
  croak $_[0];
}

# Call read_events until at least one event is returned or max 10 times.
sub _read_all {
    my ($self, $fh) = @_;
    
    my $eventscount = int @{$self->{events}}; 
    my $reads = 10; # Max number of reads pr. fh.

    while($reads--) {
        if($self->_read_events($fh) and int @{$self->{events}} == $eventscount){
            next;
        } else {
            last;
        }
    }
}

# Returns 1 when another call might give more events, else undef
sub _read_events {
    my ($self, $fh) = @_;

    my $cfg = $self->{fhs}{$fh}; 
    my $read = $cfg->{read};
    my $buffer = $cfg->{inbuffer};

    my ($sender, $data) = eval { $read->($fh, $cfg->{read_size}); };
    
    # Clean up error
    $@ =~ s/\s*at \S+ line [\d\.]+\n//g;
    
    if($@ =~ /Resource temporarily unavailable/) {
        return;

    } elsif($@ =~ /Filehandle.+opened only for output/) {
        $self->push_event({ type => 'error', error => "$@ in _read_events()", 
            fh => $fh });   
        $self->push_event({ type => 'closing', fh => $fh });
        $self->kill($fh);
        return;
    
    } elsif($@ =~ /Bad file descriptor/) {
        $self->push_event({ type => 'error', error => "$@ in _read_events()", 
            fh => $fh });   
        $self->push_event({ type => 'closing', fh => $fh });
        $self->kill($fh);
        return;
    
    } elsif($@ and $cfg->{errors} and my @events = socket_errors($fh)) {
        # FIXME: Adde MetaHandler information to events
        $self->push_event(@events);
        return 1;
    
    } elsif($@) {
        $self->push_event({ type => 'error', error => "$@ in _read_events()", 
            fh => $fh });   
        return;
   
    # Check if connection closed for tcp
    } elsif($cfg->{type} eq 'stream' and length $data == 0) {
        # Return the last of the buffer on disconnect
        if($buffer) {
            if($buffer->buffer() ne '') {
                $self->push_event({ 
                    type => $cfg->{return_last} ? 'read_last' : 'read', 
                    fh => $fh, 
                    data => $buffer->buffer() 
                });
            }
        }
        
        # Wait with the close so a valid file handle can be returned
        push(@{$self->{actionq}}, sub { $self->kill($fh); }); 
        $self->push_event({ type => 'closing', fh => $fh });
        return;
    
    } elsif($buffer) {    
        eval { $buffer->write($data); };
        if($@) {
            # Push buffer overflow error or other error to the event queue
            $self->push_event({ type => 'error', error => "$@", fh => $fh, 
                data=> $data });
            $self->push_event({ type => 'read_last', fh => $fh, 
                data => $buffer->buffer() });

            # Wait with the close so a valid file handle can be returned
            push(@{$self->{actionq}}, sub { $self->kill($fh); }); 
            $self->push_event({ type => 'closing', fh => $fh });
            return;
        
        } else {
            foreach my $record ($buffer->read($cfg->{recvlength})) {
                $self->push_event({ type => 'read', fh => $fh, 
                    data => $record });
                delete $cfg->{recvlength}; 
            }
        }
        
        return 1;

    } else {
        # Add MetaHandler information
        my $id;
        if(defined $cfg->{meta_handler}) {
            $id = $cfg->{meta_handler}->($fh, $data, $sender);
        }

        $self->push_event({ type => 'read', fh => $fh, data => $data, 
            ($sender ? (sender => $sender) : ()),
            ($id ? (id => $id) : ()),
        });
        return 1;
    }
}

=head2 socket_errors

Dummy sub that casts an error if the IO::EventMux::Socket::MsgHdr is not installed and the Errors option is used

=cut

=head2 NOTES

B<Working with PIPE's:> 
When the other end of a pipe closes it's end, signals can get thrown. To handle
this a signal handler needs to be defined:

  # Needed when writing to a broken pipe 
  $SIG{PIPE} = sub { # SIGPIPE
     croak "Broken pipe";
 };

B<Getting rid of 'Filehandle ... opened only for output'> 

  # Needed as sysread() throws warnings when STDIN gets closed by the child
  $SIG{__WARN__} = sub {
     croak @_;    
  };

=cut

=head1 AUTHOR

Jonas Jensen <jonas@infopro.dk>, Troels Liebe Bentsen <troels@infopro.dk>

=head1 COPYRIGHT AND LICENCE

Copyright 2006-2008: Troels Liebe Bentsen
Copyright 2006-2007: Jonas Jensen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
