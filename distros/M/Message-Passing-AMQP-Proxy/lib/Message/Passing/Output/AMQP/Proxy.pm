package Message::Passing::Output::AMQP::Proxy;
use Moose;
use namespace::autoclean;
use JSON qw/ decode_json /;

with qw/
    Message::Passing::AMQP::Role::HasAChannel
    Message::Passing::Role::Output
/;

sub consume {
    my $self = shift;
    my $data = shift;
    if (ref $data) {
        warn("Passed non-serialized data - is a perl reference. Dropping.\n");
        return;
    }

    my $hash = decode_json($data);

    $self->_channel->publish(
        body => $data,
        exchange => $hash->{'@exchange'},
        routing_key => $hash->{'@rk'},
    );
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Message::Passing::Output::AMQP::Proxy - output messages to AMQP.

=head1 SYNOPSIS

    message-pass --input STDIN --output AMQP::Proxy --output_options '{"exchange_name":"test","hostname":"127.0.0.1","username":"guest","password":"guest"}'

=head1 DESCRIPTION

A L<Message::Passing> L<AnyEvent::RabbitMQ> output class.

Can be used as part of a chain of classes with the L<message-pass> utility, or directly as
a logger in normal perl applications.

Takes the routeing key and exchange from the C<@rk> and C<@exchange> fields.

=head1 METHODS

=head2 consume

Sends a message.

=head1 SEE ALSO

=over

=item L<Message::Passing::AMQP>

=item L<Message::Passing::Output::AMQP>

=item L<Message::Passing>

=item L<AMQP>

=item L<http://www.zeromq.org/>

=back

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::AMQP::Proxy>.

=cut

