package Message::Passing::Collectd;
use strict;
use warnings;

our $VERSION = '0.006';

1;

=head1 NAME

Message::Passing::Collectd - a suite of adaptors between Message::Passing and collectd.

=head1 DESCRIPTION

This package is a placeholder for adaptors between L<Message::Passing> and L<collectd|http://collectd.org>.

Please see L<Collectd::Plugin::Write::Message::Passing> for emitting
metrics data and
L<Collectd::Plugin::Read::Message::Passing> for reading metrics data

=head1 NOTE

The adaptors in this plugin are currently experimental, and have only
been tested with the L<ZeroMQ|Message::Passing::ZeroMQ> transport.

=head1 AUTHOR

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 the above author.

Licensed under the same terms a perl itself.

=cut

