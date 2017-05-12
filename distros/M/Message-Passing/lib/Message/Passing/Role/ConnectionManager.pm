package Message::Passing::Role::ConnectionManager;
use Moo::Role;
use MooX::Types::MooseLike::Base qw/ Bool ArrayRef /;
use Scalar::Util qw/ blessed weaken /;
use Carp qw/ confess /;
use Message::Passing::Exception::ConnectionDisconnected;
use Message::Passing::Exception::ConnectionTimeout;
use namespace::clean -except => 'meta';

requires '_build_connection';

sub BUILD {
    my $self = shift;
    $self->connection;
}

with qw/
    Message::Passing::Role::HasTimeoutAndReconnectAfter
    Message::Passing::Role::HasErrorChain
/;

has _timeout_timer => (
    is => 'rw',
);

has connected => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
    writer => '_set_connected',
);

has connection => (
    is => 'ro',
    lazy => 1,
    predicate => '_has_connection',
    builder => '_build_connection',
    clearer => '_clear_connection',
);

after _build_connection => sub {
    my $self = shift;
    weaken($self);
    $self->_timeout_timer($self->_build_timeout_timer);
};

sub _build_timeout_timer {
    my $self = shift;
    weaken($self);
    AnyEvent->timer(
        after => $self->timeout,
        cb => sub {
            $self->error->consume(Message::Passing::Exception::ConnectionTimeout->new(
                after => $self->timeout,
            ));
            $self->_timeout_timer(undef);
            $self->_set_connected(0); # Use public API, causing reconnect timer to be built
        },
    );
}

sub _build_reconnect_timer {
    my $self = shift;
    weaken($self);
    AnyEvent->timer(
        after => $self->reconnect_after,
        cb => sub {
#            $self->error->consume("Reconnecting to ...");
            $self->_timeout_timer(undef);
            $self->connection; # Just rebuild the connection object
        },
    );
}

before _clear_connection => sub {
    my $self = shift;
    return unless $self->_has_connection;
    $self->_timeout_timer($self->_build_reconnect_timer);
};

has _connect_subscribers => (
    isa => ArrayRef,
    is => 'ro',
    default => sub { [] },
    writer => '_set_connect_subscribers',
);

sub __clean_subs {
    my $self = shift;
    my $subs = [ grep { weaken($_); defined $_ } @{$self->_connect_subscribers} ];
    $self->_set_connect_subscribers($subs);
}

sub subscribe_to_connect {
    my ($self, $subscriber) = @_;
    confess "Subscriber '$subscriber' is not blessed" unless blessed $subscriber;
    confess "Subscriber '$subscriber' does not have a ->connected method" unless $subscriber->can('connected');
    $self->__clean_subs;
    my $subs = $self->_connect_subscribers;
    push(@$subs, $subscriber);
    if ($self->connected) {
        $subscriber->connected($self->connection);
    }
}

after _set_connected => sub {
    my ($self, $connected) = @_;
    $self->__clean_subs;
    my $method = $connected ? 'connected' : 'disconnected';
    foreach my $sub (@{$self->_connect_subscribers}) {
        $sub->$method($self->connection) if $sub->can($method);
    }
    $self->_timeout_timer(undef) if $connected;
    if (!$connected && $self->_has_connection) {
        $self->error->consume(Message::Passing::Exception::ConnectionDisconnected->new);
        $self->_clear_connection;
    }
};

1;

=head1 NAME

Message::Passing::Role::ConnectionManager - A simple manager for inputs and outputs that need to make network connections.

=head1 DESCRIPTION

This role is for components which make network connections, and need to handle the connection not starting,
timeouts, disconnects etc.

It provides a simple abstraction for multiple other classes to be able to use the same connection manager, and
a notifies

=head1 REQUIRED METHODS

=head2 _build_connection

Build and return the connection we're managing, start the connection
process.

Your connection should use the API as documented below to achieve notification of connect and disconnect events.

=head1 API FOR CONNECTIONS

=head2 _set_connected (1)

Notify clients that the connection is now ready for use.

=head2 _set_connected (0)

Notify clients that the connection is no longer ready for use.

Will cause the connection to be terminated and retried.

=head1 API FOR CLIENTS

To use a connection manager, you should register yourself like this:

    $manager->subscribe_to_connect($self);

The manager will call C<< $self->connected($connection) >> and C<< $self->disconnected() >> when appropriate.

If the manager is already connected when you subscribe, it will immediately call back into your
C<< connected >> method, if it is not already connected then this will happen at a later point
once the connection is established.

See L<Message::Passing::Role::HasAConnection> for a role to help with dealing with a connection manager.

=head1 ATTRIBUTES

=head2 connected

A Boolean indicating if the connection is currently considered fully connected

=head2 connection

The connection object (if we are connected, or connecting currently) - can
be undefined if we are during a reconnect timeout.

=head2 timeout

Connections will be timed out and aborted after this time if they haven't
successfully connected.

Defaults to 30s

=head2 reconnect_after

The number of seconds to wait before starting a reconnect after a connection has timed out
or been aborted.

Defaults to 2s

=head1 METHODS

=head2 subscribe_to_connect ($subscriber)

This is called by your Input or Output, as C<< $self->connection_manager->subscribe_to_connect($self) >>.

This is done for you by L<Message::Passing::Role::HasAConnection> usually..

This arranges to store a weak reference to your component, allowing the 
connection manager to call the C<< ->connect >>
or C<< ->disconnect >> methods for any components registered when a connection is established or destroyed.

Note that if the connection manager is already connected, it will B<immediately> call the C<< ->connect >> method.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

==head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut
