package GeoIP2::Model::Domain;

use strict;
use warnings;

our $VERSION = '2.006002';

use Moo;

use GeoIP2::Types qw( IPAddress Str );

use namespace::clean -except => 'meta';

with 'GeoIP2::Role::Model::Flat', 'GeoIP2::Role::HasIPAddress';

has domain => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_domain',
);

1;

# ABSTRACT: Model class for the GeoIP2 Domain database

__END__

=pod

=encoding UTF-8

=head1 NAME

GeoIP2::Model::Domain - Model class for the GeoIP2 Domain database

=head1 VERSION

version 2.006002

=head1 SYNOPSIS

  use 5.008;

  use GeoIP2::Model::Domain;

  my $domain = GeoIP2::Model::Domain->new(
      raw  => { domain => 'maxmind.com', ip_address => '24.24.24.24'}
  );

  print $domain->domain(), "\n";

=head1 DESCRIPTION

This class provides a model for the data returned by the GeoIP2 Domain
database.

=head1 METHODS

This class provides the following methods:

=head2 $domain->domain()

Returns the domain as a string.

=head2 $domain->ip_address()

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
