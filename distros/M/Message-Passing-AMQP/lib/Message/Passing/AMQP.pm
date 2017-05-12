package Message::Passing::AMQP;
use Moose ();
use namespace::autoclean;

our $VERSION = "0.007";
$VERSION = eval $VERSION;

1;

=head1 NAME

Message::Passing::AMQP - input and output message-pass messages via AMQP.

=head1 SYNOPSIS

    # Terminal 1:
    $ message-pass --input STDIN --output AMQP --output_options '{"exchange_name":"test","hostname":"127.0.0.1","username":"guest","password":"guest"}'
    {"data":{"some":"data"},"@metadata":"value"}

    # Terminal 2:
    $ message-pass --output STDOUT --input AMQP --input_options '{"queue_name":"test","exchange_name":"test","hostname":"127.0.0.1","username":"guest","password":"guest"}'
    {"data":{"some":"data"},"@metadata":"value"}

=head1 DESCRIPTION

An AMQP adaptor for L<Message::Passing> for speaking to AMQP servers, for example L<RabbitMQ|http://www.rabbitmq.com/> or QPID.

=head1 PROTOCOL VERSION

This adaptor supports all versions of the AMQP protocol supported by L<AnyEvent::RabbitMQ>.

=head1 SEE ALSO

=over

=item L<Message::Passing::Output::AMQP>

=item L<Message::Passing::Input::AMQP>

=item L<Message::Passing>

=item L<AnyEvent::RabbitMQ>

=back

=head1 AUTHOR

Tomas (t0m) Doran <bobtfish@bobtfish.net>

=head1 COPYRIGHT

Copyright The above mentioned AUTHOR 2012.

=head1 LICENSE

GNU Library General Public License, Version 2.1

=cut

1;

