package Message::Passing::ZeroMQ::Role::HasASocket;
use Moo::Role;
use ZMQ::FFI::Constants qw/ :all /;
use MooX::Types::MooseLike::Base qw/ :all /;
use namespace::clean -except => 'meta';
use File::pushd qw/tempd/;

with 'Message::Passing::ZeroMQ::Role::HasAContext';

has _socket => (
    is => 'ro',
#    isa => 'ZeroMQ::Socket',
    lazy => 1,
    builder => '_build_socket',
    predicate => '_has_socket',
    clearer => '_clear_socket',
);

has socket_builder => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => '_has_socket_builder',
);

before _clear_ctx => sub {
    my $self = shift;
    if ($self->linger) {
        $self->_socket->set_linger($self->linger);
    }
    $self->_socket->close;
    $self->_clear_socket;
};

requires '_socket_type';

has linger => (
    is => 'ro',
    default => sub { 0 },
    isa => Int,
);

sub _build_socket {
    my $self = shift;

    return $self->socket_builder->($self, $self->_ctx)
        if $self->_has_socket_builder;

    my $type_name = "ZMQ::FFI::Constants::ZMQ_" . $self->socket_type;
    my $socket = $self->_ctx->socket(do { no strict 'refs'; &$type_name() });
    if ($self->linger) {
        $socket->set_linger($self->linger);
    }
    $self->setsockopt($socket);
    if ($self->_should_connect) {
        $socket->connect($self->connect);
    }
    if ($self->_should_bind) {
        $socket->bind($self->socket_bind);
    }
    if (!$self->_should_connect && !$self->_should_bind) {
        use Data::Dumper;
        die "Neither asked to connect or bind, invalid" . Dumper($self);
    }
    return $socket;
}

has socket_bind => (
    is => 'ro',
    isa => Str,
    predicate => '_should_bind',
);

has socket_type => (
#    isa => enum([qw[PUB SUB PUSH PULL]]),
    is => 'ro',
    builder => '_socket_type',
    lazy => 1,
);

has connect => (
    isa => Str,
    is => 'ro',
    predicate => '_should_connect',
);

1;

=head1 NAME

Message::Passing::ZeroMQ::Role::HasASocket - Role for instances which have a ZeroMQ socket.

=head1 ATTRIBUTES

=head2 socket_bind

Bind a server to an address.

For example C<< tcp://*:5222 >> to make a server listening
on a port on all of the host's addresses, or C<< tcp://127.0.0.1:5222 >>
to bind the socket to a specific IP on the host.

=head2 connect

Connect to a server. For example C<< tcp://127.0.0.1:5222 >>.

This option is mutually exclusive with socket_bind, as sockets
can connect in one direction only.

=head2 socket_type

The connection direction can be either the same as, or the opposite
of the message flow direction.

The currently supported socket types are:

=head3 PUB

This socket publishes messages to zero or more subscribers.

All subscribers get a copy of each message.

=head3 SUB

The pair of PUB, receives broadcast messages.

=head3 PUSH

This socket type distributes messages in a round-robin fashion between
subscribers. Therefore N subscribers will see 1/N of the message flow.

=head2 PULL

The pair of PUSH, receives a proportion of messages distributed.

=head2 linger

Integer indicating the value of the ZMQ_LINGER options.

Defaults to 0 meaning sockets will not block on shutdown if a server
is unavailable (i.e. queued messages will be discarded).

=head3 socket_hwm

Set the High Water Mark for the socket. Depending on the socket type,
messages are likely to be discarded once this high water mark is exceeded
(i.e. there are more than this many messages buffered).

A value of 0 disables the high water mark, meaning that messages will be
buffered until RAM runs out.

=head3 socket_builder

A code reference returning a new L<ZeroMQ::Socket> instance within a new
L<ZeroMQ::Context> every time it is called.

If a value this attribute is provided, responsibility for building sockets is
solely the callback's responsibility. None of the other attributes usually
involved in creating sockets, such as C<socket_type>, C<linger>, or
C<socket_hmw> will be taken into account automatically.

If a socket builder callback needs to make use of the aforementioned attributes,
it will have to do so manually by looking at the object implementing
C<Message::Passing::ZeroMQ::Role::HasASocket>, which is going to be passed to
the callback as the first argument upon invocation.

The second and final argument passed to the callback with be a newly
L<ZeroMQ::Context> that the new socket is expected to be created in.

=head1 METHODS

=head2 setsockopt

For wrapping by sub-classes to set options after the socket
is created.

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API -
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::ZeroMQ>.

=cut

