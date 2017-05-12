package Message::Passing::Output::ZeroMQ;
use Moo;
use MooX::Types::MooseLike::Base qw/ :all /;
use namespace::clean -except => 'meta';

use ZMQ::FFI::Constants qw/ :all /;
use Time::HiRes;

with qw/
    Message::Passing::ZeroMQ::Role::HasASocket
    Message::Passing::Role::Output
/;

has '+_socket' => (
    handles => {
        '_zmq_send' => 'send',
    },
);

sub _socket_type { 'PUB' }

has socket_hwm => (
    is      => 'rw',
    default => 10000,
);

has subscribe_delay => (
    is      => 'ro',
    isa     => Num,
    default => 0.2,
    );

# socket_(probably)_subscribed, but who has the bytes for that
has socket_subscribed => (
    is  => 'rw',
    isa => Bool,
    );
has socket_connect_time => (
    is  => 'rw',
    isa => Num,
    );

sub BUILD {
    my $self = shift;
    # Force a socket to be built, so that there's more chance the first message will be sent
    if ($self->_should_connect){
        my $socket = $self->_socket;
        return;
    }

    return;
}

sub consume {
    my ($self, $data) = @_;

    # See the slow joiner problem for PUB/SUB, outlined in
    # http://zguide.zeromq.org/page:all#Getting-the-Message-Out
    if (!$self->socket_subscribed && $self->socket_connect_time){
        my $time = Time::HiRes::time;
        my $alive_time = $time - $self->socket_connect_time;
        my $sleep_time = sprintf "%.4f", ($self->subscribe_delay - $alive_time);
        # warn "Alive $alive_time, so sleep time $sleep_time";
        if ($sleep_time > 0){
            Time::HiRes::sleep $sleep_time;
        }
        $self->socket_subscribed(1);
    }

    return $self->_zmq_send($data);
}

sub setsockopt {
    my ($self, $socket) = @_;

    if ($self->zmq_major_version >= 3){
        $socket->set(ZMQ_SNDHWM, 'int', $self->socket_hwm);
    }
    else {
        $socket->set(ZMQ_HWM, 'uint64_t', $self->socket_hwm);
    }

    return;
}

after _build_socket => sub {
    my $self = shift;
    $self->socket_connect_time( Time::HiRes::time );
};

1;

=head1 NAME

Message::Passing::Output::ZeroMQ - output messages to ZeroMQ.

=head1 SYNOPSIS

    use Message::Passing::Output::ZeroMQ;

    my $logger = Message::Passing::Output::ZeroMQ->new;
    $logger->consume({data => { some => 'data'}, '@metadata' => 'value' });

    # Or see Log::Dispatch::Message::Passing for a more 'normal' interface to
    # simple logging.

    # Or use directly on command line:
    message-passing --input STDIN --output ZeroMQ --output_options \
        '{"connect":"tcp://192.168.0.1:5552"}'
    {"data":{"some":"data"},"@metadata":"value"}

=head1 DESCRIPTION

A L<Message::Passing> ZeroMQ output class.

Can be used as part of a chain of classes with the L<message-passing> utility, or directly as
a logger in normal perl applications.

=head1 ATTRIBUTES


See L<Message::Passing::ZeroMQ/CONNECTION ATTRIBUTES>.

=head2 subscribe_delay

Time in floating seconds to sleep to ensure the receiving socket has subscribed.
This is the longest the sleep might take.

See the slow-joiner problem: L<http://zguide.zeromq.org/page:all#Getting-the-Message-Out>.

DEFAULT: 0.2 seconds

=head1 METHODS

=head2 consume ($msg)

Sends a message, as-is. This means that you must have encoded the message to a string before
sending it. The C<message-pass> utility will do this for you into JSON, or you can
do it manually as shown in the example in L<Message::Passing::ZeroMQ>.

=head1 SEE ALSO

=over

=item L<Message::Passing::ZeroMQ>

=item L<Message::Passing::Input::ZeroMQ>

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

See L<Message::Passing>.

=cut

