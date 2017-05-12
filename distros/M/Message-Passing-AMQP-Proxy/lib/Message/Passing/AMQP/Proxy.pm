package Message::Passing::AMQP::Proxy;
use Moose ();
use namespace::autoclean;

our $VERSION = "0.002";
$VERSION = eval $VERSION;

1;

=head1 NAME

Message::Passing::AMQP::Proxy

=head1 SYNOPSIS

    $ message-pass --input STDIN --output AMQP::Proxy --output_options '{"hostname":"127.0.0.1","username":"guest","password":"guest"}'
    {"data":{"some":"data"},"@metadata":"value"}

=head1 DESCRIPTION

An AMQP adaptor for L<Message::Passing>, filtering JSON messages into
specified exchanges with specified routeing keys.

=over

=item *

The exchange is specified by the C<@exchange> field in the JSON data.

=item *

The routeing key is specified by the C<@rk> field in the JSON data.

=back

=head1 AUTHOR

Dave Lambley, based on work by Tomas (t0m) Doran.

=head1 LICENSE

GNU Affero General Public License, Version 3

=cut
