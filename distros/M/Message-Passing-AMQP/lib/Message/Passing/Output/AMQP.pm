package Message::Passing::Output::AMQP;
use Moose;
use namespace::autoclean;

with qw/
    Message::Passing::AMQP::Role::DeclaresExchange
    Message::Passing::Role::Output
/;

has routing_key => (
    isa => 'Str',
    is => 'ro',
    default => '',
);

has header_cb => (
    isa => 'CodeRef',
    is => 'ro',
);

has serialize_cb => (
    isa => 'CodeRef',
    is => 'ro',
);

sub consume {
    my $self = shift;
    my $data = shift;
    if (ref $data && ! defined $self->serialize_cb) {
        warn("Passed non-serialized data - is a perl reference. Dropping.\n");
        return;
    }
    unless ($self->_exchange) {
        warn("No exchange yet, dropping message");
        return;
    }
    my $header;
    $header = $self->header_cb->($data)
        if defined $self->header_cb;

    $data = $self->serialize_cb->($data)
        if defined $self->serialize_cb;

    $self->_channel->publish(
        body => $data,
        header => $header,
        exchange => $self->exchange_name,
        routing_key => $self->routing_key,
    );
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Message::Passing::Output::AMQP - output messages to AMQP.

=head1 SYNOPSIS

    message-pass --input STDIN --output AMQP --output_options '{"exchange_name":"test","hostname":"127.0.0.1","username":"guest","password":"guest"}'

=head1 DESCRIPTION

A L<Message::Passing> L<AnyEvent::RabbitMQ> output class.

Can be used as part of a chain of classes with the L<message-pass> utility, or directly as
a logger in normal perl applications.

=head1 ATTRIBUTES

=head2 routing_key

The routing key for all messages, defaults to ''.

=head2 header_cb

Optional callback function which gets passed the message before it is
serialized using L</serialize_cb>.
Should return a hashref which gets passed to publish( header => ).

NOTE: if you want to set the message headers (note the s) you have to pass them inside headers, e.g.:

  {
      content_type => 'application/json',
      headers => {
          key => 'value',
      }
  }

=head2 serialize_cb

Optional callback function which gets passed the message and should return a
scalar. This is useful when passing structured messages e.g. hashrefs or
objects where some attributes should be accessible for the L</header_cb> function.
If the serialization happens before using a L<Message::Passing::Role::Filter>
it would require to deserialize it again in header_cb.
To use a Message::Passing filter you can instantiate it and pass it's filter
function to serialize_cb:

  my $filter = Message::Passing::Filter::Encoder::JSON->new(output_to => undef);

  ...

  {
      serialize_cb => sub { $filter->filter(shift) },
  }

=head1 METHODS

=head2 consume

Sends a message.

=head1 SEE ALSO

=over

=item L<Message::Passing::AMQP>

=item L<Message::Passing::Input::AMQP>

=item L<Message::Passing>

=item L<AMQP>

=item L<http://www.zeromq.org/>

=back

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing::AMQP>.

=cut
