package GeoIP2::Model::AnonymousIP;

use strict;
use warnings;

our $VERSION = '2.006002';

use Moo;

use GeoIP2::Types qw( Bool );

use namespace::clean -except => 'meta';

with 'GeoIP2::Role::Model::Flat', 'GeoIP2::Role::HasIPAddress';

has [
    'is_anonymous',
    'is_anonymous_vpn',
    'is_hosting_provider',
    'is_public_proxy',
    'is_tor_exit_node'
] => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

1;

# ABSTRACT: Model class for the GeoIP2 Anonymous IP database

__END__

=pod

=encoding UTF-8

=head1 NAME

GeoIP2::Model::AnonymousIP - Model class for the GeoIP2 Anonymous IP database

=head1 VERSION

version 2.006002

=head1 SYNOPSIS

  use 5.008;

  use GeoIP2::Model::AnonymousIP;

  my $anon = GeoIP2::Model::AnonymousIP->new(
      raw => {
          is_anonymous        => 1,
          is_hosting_provider => 1,
          ip_address          => '24.24.24.24'
      }
  );

  print $anon->is_anonymous(), "\n";

=head1 DESCRIPTION

This class provides a model for the data returned by the GeoIP2 Anonymous IP
database.

=head1 METHODS

This class provides the following methods:

=head2 $anon->is_anonymous()

Returns true if the IP address belongs to any sort of anonymous network.

=head2 $anon->is_anonymous_vpn()

Returns true if the IP address is registered to an anonymous VPN provider.
If a VPN provider does not register subnets under names associated with them,
we will likely only flag their IP ranges using the C<is_hosting_provider>
attribute.

=head2 $anon->is_hosting_provider()

Returns true if the IP address belongs to a hosting or VPN provider
(see description of C<is_anonymous_vpn> attribute).

=head2 $anon->is_public_proxy()

Returns true if the IP address belongs to a public proxy.

=head2 $anon->is_tor_exit_node()

Returns true if the IP address is a Tor exit node.

=head2 $anon->ip_address()

Returns the IP address used in the lookup.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/GeoIP2-perl/issues>.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Greg Oschwald <goschwald@maxmind.com>

=item *

Mark Fowler <mfowler@maxmind.com>

=item *

Olaf Alders <oalders@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
