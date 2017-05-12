package Message::Passing::Input::ZeroMQ;
use Moo;
use ZMQ::FFI::Constants qw/ :all /;
use AnyEvent;
use Scalar::Util qw/ weaken /;
use Try::Tiny qw/ try catch /;
use namespace::clean -except => 'meta';

with qw/
    Message::Passing::ZeroMQ::Role::HasASocket
    Message::Passing::Role::Input
/;

has '+_socket' => (
    handles => {
        _zmq_recv => 'recv',
    },
);

sub _socket_type { 'SUB' }

has socket_hwm => (
    is      => 'rw',
    default => 10000,
);

has subscribe => (
    isa => sub { ref($_[0]) eq 'ARRAY' },
    is => 'ro',
    lazy => 1,
    default => sub { [ '' ] }, # Subscribe to everything!
);

sub setsockopt {
    my ($self, $socket) = @_;

    if ($self->zmq_major_version >= 3){
        $socket->set(ZMQ_RCVHWM, 'int', $self->socket_hwm);
    }
    else {
        $socket->set(ZMQ_HWM, 'uint64_t', $self->socket_hwm);
    }

    if ($self->socket_type eq 'SUB') {
        foreach my $sub (@{ $self->subscribe }) {
            $socket->set(ZMQ_SUBSCRIBE, "binary", $sub);
        }
    }

    return;
}

sub _try_rx {
    my $self = shift();
    my $msg;
    try {
        $msg = $self->_zmq_recv(ZMQ_NOBLOCK);
    };
    if ($msg) {
        $self->output_to->consume($msg);
    }
    return $msg;
}

has _io_reader => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $weak_self = shift;
        weaken($weak_self);
        AE::io $weak_self->_socket->get_fd, 0,
            sub { my $more; do { $more = $weak_self->_try_rx } while ($more) };
    },
);

# Note that we need this timer as ZMQ is magic..
# Just checking our local FD for readability will not always
# be enough, as the client end of ZQM may not start pushing messages to us,
# ergo we call ->recv explicitly on the socket to get messages
# which may be pre-buffered at a client as fast as possible (i.e. before
# the client pushes another message).
has _zmq_timer => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $weak_self = shift;
        weaken($weak_self);
        AnyEvent->timer(after => 1, interval => 1,
            cb => sub { my $more; do { $more = $weak_self->_try_rx } while ($more) });
    },
);

sub BUILD {
    my $self = shift;
    $self->_io_reader;
    $self->_zmq_timer;
}

1;

=head1 NAME

Message::Passing::Input::ZeroMQ - input messages from ZeroMQ.

=head1 SYNOPSIS

    message-passing --output STDOUT --input ZeroMQ --input_options '{"socket_bind":"tcp://*:5552"}'

=head1 DESCRIPTION

A L<Message::Passing> ZeroMQ input class.

Can be used as part of a chain of classes with the L<message-passing> utility, or directly as
an input with L<Message::Passing::DSL>.

=head1 ATTRIBUTES

See L<Message::Passing::ZeroMQ/CONNECTION ATTRIBUTES>

=head2 subscribe

If the input socket is a C<SUB> socket, then the C<ZMQ_SUBSCRIBE>
socket option will be set once for each value in the subscribe attribute.

Defaults to '', which means all messages are subscribed to.

=head1 SEE ALSO

=over

=item L<Message::Passing::ZeroMQ>

=item L<Message::Passing::Output::ZeroMQ>

=item L<Message::Passing>

=item L<ZeroMQ>

=item L<http://www.zeromq.org/>

=back

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::ZeroMQ>.

=cut

