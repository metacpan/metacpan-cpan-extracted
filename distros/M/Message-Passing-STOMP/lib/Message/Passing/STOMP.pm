package Message::Passing::STOMP;
use Moose ();
use namespace::autoclean;

our $VERSION = "0.006";
$VERSION = eval $VERSION;

1;

=head1 NAME

Message::Passing::STOMP - input and output messages to STOMP.

=head1 SYNOPSIS

    # Terminal 1:
    $ message-pass --input STDIN --output STOMP --output_options \
        '{"destination":"/queue/foo","hostname":"localhost","port":"6163","username":"guest","password":"guest"}'
    {"data":{"some":"data"},"@metadata":"value"}

    # Terminal 2:
    $ message-pass --output STDOUT --input STOMP --input_options \
        '{"destination":"/queue/foo","hostname":"localhost","port":"6163","username":"guest","password":"guest"}'
    {"data":{"some":"data"},"@metadata":"value"}

=head1 DESCRIPTION

An L<STOMP|http://stomp.github.com/> transport for L<Message::Passing>.

L<STOMP|http://stomp.github.com/> is a simple and well supported messaging protocol, with clients in
many languages.

This is a simple adaptor to allow you to send or receive STOMP messages

=head1 QUEUES AND TOPICS

STOMP does not specify the semantics for message destinations or subscriptions (other than
that they are a string), however most common STOMP servers (including ActiveMQ and RabbitMQ)
expect a string matching /queue/name or /topic/name.

Messages published to a destination prefixed by /queue/ are queued up, until a subscriber connects,
at which point they are delivered. If multiple subscribers connect then the messages are distributed
between the subscribers (i.e. each subscriber sees a portion of the messages).

Messages published to a destination prefixed by /topic/ are copied to all connected subscribers,
however if there are no subscribers currently, they are discarded, rather than being queued up.

=head1 STOMP SERVERS

There are a number of message brokers which will communicate with STOMP clients, the main ones
being:

=head2 RabbitMQ

L<RabbitMQ|http://www.rabbitmq.com/> has L<a STOMP plugin|http://www.rabbitmq.com/stomp.html>.

=head2 ActiveMQ

L<ActiveMQ|http://activemq.apache.org/> has L<a STOMP plugin|http://activemq.apache.org/stomp.html>.

=head1 SEE ALSO

=over

=item L<http://stomp.github.com/> - STOMP protocol documentation

=item L<Message::Passing::Output::STOMP>

=item L<Message::Passing::Input::STOMP>

=item L<Message::Passing>

=item L<AnyEvent::STOMP>

=back

=head1 AUTHOR

Tomas (t0m) Doran <bobtfish@bobtfish.net>

=head1 COPYRIGHT

Copyright The above mentioned AUTHOR 2012.

=head1 LICENSE

GNU Affero General Public License, Version 3

If you feel this is too restrictive to be able to use this software,
please talk to us as we'd be willing to consider re-licensing under
less restrictive terms.

=cut

1;

