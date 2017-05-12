package Message::Passing::Input::STOMP;
use Moose;
use AnyEvent;
use Scalar::Util qw/ weaken /;
use Message::Passing::Types qw/ ArrayOfStr /;
use namespace::autoclean;

with qw/
    Message::Passing::STOMP::Role::HasAConnection
    Message::Passing::Role::Input
/;

has destination => (
    is => 'ro',
    isa => ArrayOfStr,
    coerce => 1,
    required => 1,
);

my $id = 0;
sub connected {
    my ($self, $client) = @_;
    weaken($self);
    $client->reg_cb(MESSAGE => sub {
        my (undef, $body, $headers) = @_;
        $self->output_to->consume($body);
    });
    foreach my $destination (@{ $self->destination }) {
        my $subscribe_headers = {
            id => $id++,
            destination => $destination,
            ack => 'auto',
        };
        $client->send_frame('SUBSCRIBE',
            undef, $subscribe_headers);
    }
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Message::Passing::Input::STOMP - input messages from a STOMP queue.

=head1 SYNOPSIS

    message-pass --output STDOUT --input STOMP --input_options \
        '{"destination":"/queue/foo","hostname":"localhost","port":"6163","username":"guest","password":"guest"}'

=head1 DESCRIPTION

A simple STOMP subscriber for Message::Passing.

=head1 ATTRIBUTES

=head2 destination

The queue or topic name to subscribe to on the server.

This can either be a single value, or an array of values.

=head2 hostname

Server hostname to connect to.

=head2 port

Server port number to connect to (default 6163).

=head2 username

The username to connect with (defaults to 'guest').

=head2 password

The password to connect with (defaults to 'guest').

=head1 METHODS

=head2 connected

Called by L<Message::Passing::STOMP::ConnectionManager> to indicate a
connection to the STOMP server has been made.

Causes the subscription to the topic(s) to be started

=head1 SEE ALSO

=over

=item L<Message::Passing::STOMP>

=item L<Message::Passing::Output::STOMP>

=item L<Message::Passing>

=back

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::STOMP>.

=cut

