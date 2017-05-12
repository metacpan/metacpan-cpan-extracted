package Message::Passing::Redis;
use strict;
use warnings;
use Redis;
use namespace::clean -except => 'meta';

our $VERSION = '0.006';
$VERSION = eval $VERSION;

1;

=head1 NAME

Message::Passing::Redis - Produce or consume messages by Redis PubSub

=head1 SYNOPSIS

    # Terminal 1:
    $ message-pass --input STDIN --output Redis --output_options '{"topic":"foo","hostname":"127.0.0.1","port":"6379"}'
    {"data":{"some":"data"},"@metadata":"value"}

    # Terminal 2:
    $ message-pass --output STDOUT --input Redis --input_options '{"topics":["foo"],"hostname":"127.0.0.1","port":"6379"}'
    {"data":{"some":"data"},"@metadata":"value"}

=head1 DESCRIPTION

A L<Redis> transport for L<Message::Passing>, allowing you to publish
messages to, or subscribe to messages from Redis.

=head1 SEE ALSO

=over

=item L<Message::Passing::Input::Redis>

=item L<Message::Passing::Output::Redis>

=back

=head1 AUTHOR

Tomas (t0m) Doran <bobtfish@bobtfish.net>

=head1 COPYRIGHT

Copyright the above named author

=head1 LICENSE

GNU Affero General Public License, Version 3

If you feel this is too restrictive to be able to use this software, please talk to us as we'd be willing to consider re-licensing under less restrictive terms.

=cut

