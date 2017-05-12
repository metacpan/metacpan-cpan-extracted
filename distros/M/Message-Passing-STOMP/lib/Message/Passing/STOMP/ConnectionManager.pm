package Message::Passing::STOMP::ConnectionManager;
use Moose;
use Scalar::Util qw/ weaken /;
use AnyEvent;
use AnyEvent::STOMP;
use Carp qw/ croak /;
use Try::Tiny qw/ try /;
use namespace::autoclean;

BEGIN { # For RabbitMQ https://rt.cpan.org/Ticket/Display.html?id=68432
    if (!try{ AnyEvent::STOMP->VERSION("0.6") }) {
        no warnings 'redefine';
        sub AnyEvent::STOMP::send_frame {
            my $self = shift;
            my ($command, $body, $headers) = @_;

            croak 'Missing command' unless $command;

            $headers->{'content-length'} = length $body || 0;
            $body = '' unless defined $body;

            my $frame = sprintf("%s\n%s\n\n%s\000",
                        $command,
                        join("\n", map { "$_:$headers->{$_}" } keys %$headers),
                        $body);
            $self->{handle}->push_write($frame);
        }
    }
}

with qw/
    Message::Passing::Role::ConnectionManager
    Message::Passing::Role::HasHostnameAndPort
/;

sub _default_port { 6163 }

has ssl => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has [qw/ username password /] => (
    is => 'ro',
    isa => 'Str',
    default => 'guest',
);

sub _build_connection {
    my $self = shift;
    weaken($self);
    my $client = AnyEvent::STOMP->connect(
        $self->hostname, $self->port, $self->ssl, undef, 0,
        {
            'accept-version' => '1.1',
            host => '/',
            login => $self->username,
            passcode => $self->password,
        },
        {},
    );
    $client->reg_cb(CONNECTED => -2000 => sub {
        my ($client, $handle, $host, $port, $retry) = @_;
        $self->_set_connected(1);
    });
    $client->reg_cb(io_error => sub {
        my ($client, $errmsg) = @_;
        warn("IO ERROR $errmsg");
        $self->_set_connected(0);
    });
    $client->reg_cb(connect_error =>  sub {
        my ($client, $errmsg) = @_;
        warn("CONNECT ERROR $errmsg");
        $self->_set_connected(0);
    });
    return $client;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Message::Passing::STOMP::ConnectionManager - Wraps an AnyEvent::STOMP connection.

=head1 ATTRIBUTES


=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::STOMP>.

=cut

