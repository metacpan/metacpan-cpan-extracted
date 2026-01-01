package IPC::Manager::Client;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak/;
use Errno qw/ESRCH/;
use Scalar::Util qw/blessed weaken/;

use IPC::Manager::Message;

use Object::HashBase qw{
    <id
    <pid
    <route
    <disconnected
    <serializer
    +reconnect
    <stats
};

my ($PID, @LOCAL);

sub local_clients {
    my $class = shift;
    my ($route) = @_;

    croak "'route' is required" unless $route;

    return unless $PID;
    if ($PID != $$) {
        $PID = $$;
        return @LOCAL = ();
    }

    return grep { $_ && $_->route eq $route } @LOCAL;
}

sub unspawn              { }
sub pre_disconnect_hook  { }
sub pre_suspend_hook     { }
sub post_suspend_hook    { }
sub post_disconnect_hook { }

sub reconnect { shift->connect(@_, reconnect => 1) }
sub pid_check { croak "Client used from wrong PID" if $_[0]->{+PID} != $$; $_[0] }

sub have_pending_messages { 0 }
sub have_ready_messages   { croak "Not Implemented" }

sub get_messages { croak "Not Implemented" }
sub peer_exists  { croak "Not Implemented" }
sub peer_pid     { croak "Not Implemented" }
sub peers        { croak "Not Implemented" }
sub read_stats   { croak "Not Implemented" }
sub send_message { croak "Not Implemented" }
sub spawn        { croak "Not Implemented" }
sub write_stats  { croak "Not Implemented" }
sub all_stats    { croak "Not Implemented" }

sub pid_is_running {
    my $pid = pop;

    croak "A pid is required" unless $pid;

    local $!;

    return 1 if kill(0, $pid);    # Running and we have perms
    return 0 if $! == ESRCH;      # Does not exist (not running)
    return -1;                    # Running, but not ours
}


sub connect {
    my $class = shift;
    my ($id, $serializer, $route, %params) = @_;
    return $class->new(%params, SERIALIZER() => $serializer, ROUTE() => $route, ID() => $id);
}

sub init {
    my $self = shift;

    if (!$PID || $PID != $$) {
        $PID   = $$;
        @LOCAL = ();
    }

    push @LOCAL => $self;
    weaken($LOCAL[-1]);

    croak "'serializer' is a required attribute" unless $self->{+SERIALIZER};
    croak "'route' is a required attribute"      unless $self->{+ROUTE};

    my $id = $self->{+ID} // croak "'id' is a required attribute";

    croak "'id' may not begin with an underscore" if $id =~ m/^_/;

    $self->{+PID} //= $$;
    $self->{+STATS} = $self->read_stats if $self->{+RECONNECT};
    $self->{+STATS} //= {read => {}, sent => {}};
}

sub build_message {
    my $self = shift;
    my $in   = @_ % 2 ? shift(@_) : undef;
    if (@_ == 2 && $_[1] ne 'content') {
        @_ = (to => $_[0], content => $_[1]);
    }
    return IPC::Manager::Message->new(($in ? %$in : ()), from => $self->{+ID}, @_);
}

sub broadcast {
    my $self = shift;

    if (@_ == 1 && !(blessed($_[0]) && $_[0]->isa('IPC::Manager::Message'))) {
        @_ = (content => $_[0]);
    }

    my %out;
    for my $peer ($self->peers) {
        my ($ok, $err) = $self->try_message(@_, to => $peer, broadcast => 1, id => undef);
        $out{$peer} = $ok ? {sent => 1} : {sent => 0, error => $err};
    }

    return \%out;
}

sub try_message {
    my $self = shift;
    my $args = \@_;

    my ($ok, $err);
    {
        local $@;
        if (eval { $self->send_message(@$args); 1 }) {
            $ok = 1;
        }
        else {
            $ok  = 0;
            $err = $@ // "unknown error";
        }
    }

    return ($ok, $err) if wantarray;

    $@ = $err;
    return $ok;
}

sub requeue_message {
    my $self = shift;
    $self->send_message(@_, to => $self->{+ID});
}

sub peer_active {
    my $self = shift;

    my $peer_pid = $self->peer_pid(@_);

    return 0 unless $peer_pid;
    return 0 unless $self->pid_is_running($peer_pid);
    return 0 unless kill(0, $peer_pid);
    return 1;
}

sub disconnect {
    my $self = shift;
    my ($handler) = @_;

    $self->pid_check;

    return if $self->{+DISCONNECTED};

    $self->pre_disconnect_hook;

    # Wait for any messages that are still being written
    my $err;
    while ($self->pending_messages || $self->ready_messages) {
        if (my @ready = $self->get_messages) {
            @ready = grep { !$_->is_terminate } @ready;
            if (@ready) {
                if ($handler) {
                    $self->$handler(\@ready);
                }
                else {
                    $self->{+STATS}->{read}->{$_->{from}}-- for @ready;
                    $err = "Messages waiting at disconnect for $self->{+ID}";
                    last;
                }
            }
        }
    }

    $self->{+DISCONNECTED} = 1;

    $self->post_disconnect_hook;

    $self->write_stats;

    croak $err if $err;
}

sub suspend {
    my $self = shift;
    $self->pid_check;

    $self->pre_suspend_hook;

    $self->{+DISCONNECTED} = 1;

    $self->post_suspend_hook;
    $self->write_stats;
}

sub DESTROY {
    my $self = shift;
    return unless $self->{+PID} && $self->{+PID} == $$;
    local $@;
    eval { $self->disconnect;  1 } or warn $@;
    eval { $self->write_stats; 1 } or warn $@;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Client - Base class for all client protocols

=head1 DESCRIPTION

All connections should be a subclass of this class. This interface describes
all the common methods provided by all protocols.

=head1 SYNOPSIS

    my $con = IPC::Manager::Client::[PROTOCOL]->new($client_name, $serializer_class, $route);

    $con->send_message($peer_name => {hello => 'world'});

    for my $msg ($con->get_messages) {
        handle_message($msg);
    }

    $con->disconnect;

=head1 METHODS

=head2 CLASS METHODS

=over 4

=item ($route, $stash) = IPC::Manager::Client::[PROTOCOL]->spawn(serializer => $SERIALIZER, %params)

Used to vivify a completely new message store for the given protocol.

=item IPC::Manager::Client::[PROTOCOL]->unspawn($route, $stash)

Used to destroy the previously created message store.

=item $con = IPC::Manager::Client::[PROTOCOL]->connect($client_name, $serializer, $route)

Establish a connection with a message store.

=item $con = IPC::Manager::Client::[PROTOCOL]->reconnect($client_name, $serializer, $route)

Re-establish a suspended connection.

Note: This is not possible with some protocols, mainly 'UnixSocket'.

=item @clients = $con->local_clients($route)

This will return a reference to every active client for the specified route
that was established in the current process.

This is mainly used to disconnect clients in this process before waiting for
all clients to exit, avoiding a deadlock.

=back

=head1 INSTANCE METHODS

=over 4

=item $stats = $con->all_stats

Get all stats for all connections.

B<Note:> This is not useful until all connections have disconnected as stats
are not written until disconnect.

=item $con->broadcast($message)

=item $con->broadcast($message_content)

=item $con->broadcast(%message_fields)

Send a message to all peers. Can be an L<IPC::Manager::Message> instance,
contents of a message, or a list of fields and values for the message
(contructor arguments).

=item $msg = $con->build_message($message_obj)

=item $msg = $con->build_message($message_obj, %overrides)

=item $msg = $con->build_message($peer, $message_content)

=item $msg = $con->build_message($peer, $message_content, %message_fields)

=item $msg = $con->build_message(to => $peer, content => $message_content, %other_fields)

Construct a message from various possible argument forms. This is used by
C<send_message()> and C<try_message()>.

=item $con->disconnect

Sub terminate the connection.

=item $con->disconnected

Check if the connection has been terminated.

=item @messages = $con->get_messages()

Get all currently ready messages. Each message will be an instance of
L<IPC::Manager::Message>. All message info will already be deserialized for
you.

=item $bool = $con->have_pending_messages

True if there are messages still incoming and the protocol can detect that. For
many protocols this will always return 0.

=item $bool = $con->have_ready_messages

True if there are messages ready for reading.

=item $client_name = $con->id

Get the identifier for this connection.

=item $bool = $con->peer_active($peer_name)

Check if the specified peer is active.

=item $bool = $con->peer_exists($peer_name)

Check if the specified peer exists, even if it is suspended.

=item $pid = $con->peer_pid($peer_name)

Get the pid of a peer, undef if it does not exist or is not running.

=item @peer_names = $con->peers()

Get the names of all peers.

=item $pid = $con->pid

Get the PID for this connection.

=item $con = $con->pid_check

Returns the connection object if the current PID matches the connection PID.
Throws an exception if used from the wrong PID.

=item $state = $con->pid_is_running($pid)

Check if a PID is running.

Returns 1 if the process is running, 0 if it is not running, and -1 if it is
running but we have no permissions to send signals to it.

=item $con->post_disconnect_hook

Used by subclasses to add disconnect behaviors before disconnect.

=item $con->post_suspend_hook

Used by subclasses to add disconnect behaviors before suspend.

=item $con->pre_disconnect_hook

Used by subclasses to add disconnect behaviors after disconnect.

=item $con->pre_suspend_hook

Used by subclasses to add disconnect behaviors after suspend.

=item $hashref = $con->read_stats()

Read the connections stats (messages sent and recieved). This will only work
after either a disconnect or a call to C<< $con->write_stats >>.

=item $con->requeue_message($msg)

Put a message back in the queue. This is useful if the process needs to exec,
or be re-started before the message can be handled.

=item $rourte = $con->route

Get the route info for the message store.

=item $con->send_message($message_obj)

=item $con->send_message($message_obj, %overrides)

=item $con->send_message($peer, $message_content)

=item $con->send_message($peer, $message_content, %message_fields)

=item $con->send_message(to => $peer, content => $message_content, %other_fields)

Takes all the same argument options as C<< build_message() >>.

Will send a message, and will throw an exception if it is unable to send.
Success only guarentees that the message was written, not that the peer reads
it.

=item $serializer_class = $con->serializer

Get the serializer class used for the connection.

=item $hashref = $con->stats

Get the message stats (sent and recieved counts).

=item $con->suspend

Used to disconnect with intent to reconnect, which means peers can still send
messages to this connection while it is offline. Some protocols, like
UnixSocket do not support this.

=item $bool = $con->try_message($message_obj)

=item ($bool, $err) = $con->try_message($message_obj)

=item $bool = $con->try_message($message_obj, %overrides)

=item ($bool, $err) = $con->try_message($message_obj, %overrides)

=item $bool = $con->try_message($peer, $message_content)

=item ($bool, $err) = $con->try_message($peer, $message_content)

=item $bool = $con->try_message($peer, $message_content, %message_fields)

=item ($bool, $err) = $con->try_message($peer, $message_content, %message_fields)

=item $bool = $con->try_message(to => $peer, content => $message_content, %other_fields)

=item ($bool, $err) = $con->try_message(to => $peer, content => $message_content, %other_fields)

Attempt to send a message. In list context it will return a boolean, and if the
boolean is false it will also return the error message. In scalar context it
returns a boolean and if it is false it sets $@ to the error message.

=item $con->write_stats

Write the C<< $con->stats >> data to the data store so that
C<< $con->read_stats >> can read it.

=back

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
