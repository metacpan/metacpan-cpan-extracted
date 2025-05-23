package IP::Geolocation::MMDB;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.014;
use warnings;
use utf8;

our $VERSION = 1.013;

use IP::Geolocation::MMDB::Metadata;
use Math::BigInt 1.999806;

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub getcc {
    my ($self, $ip_address) = @_;

    my $country_code;

    my $data = $self->record_for_address($ip_address);
    if (ref $data eq 'HASH') {
        if (exists $data->{country}) {
            my $country = $data->{country};
            if (exists $country->{iso_code}) {
                $country_code = $country->{iso_code};
            }
        }
    }

    return $country_code;
}

sub metadata {
    my ($self) = @_;

    return IP::Geolocation::MMDB::Metadata->new(%{$self->_metadata});
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

sub _to_bigint {
    my ($self, $bytes) = @_;

    return Math::BigInt->from_bytes($bytes);
}

1;
__END__

=encoding UTF-8

=head1 NAME

IP::Geolocation::MMDB - Read MaxMind DB files

=head1 VERSION

version 1.013

=head1 SYNOPSIS

  use IP::Geolocation::MMDB;
  my $db = IP::Geolocation::MMDB->new(file => '/path/to/Country.mmdb');
  my $metadata = $db->metadata;
  my $data = $db->get('1.2.3.4');
  my $country_code = $db->getcc('2620:fe::9');

=head1 DESCRIPTION

A Perl module that reads MaxMind DB files and maps IP addresses to location
information such as country and city names.

=head1 SUBROUTINES/METHODS

=head2 new

  my $db = IP::Geolocation::MMDB->new(file => '/path/to/Country.mmdb');

Returns a new database object.  Dies if the specified file cannot be read.

=head2 get

  my $data = $db->get($ip_address);
  my ($data, $prefix_length) = $db->get($ip_address);

Takes an IPv4 or IPv6 address as a string and returns the data associated with
the IP address or the undefined value.  In list context, the data and the
network prefix length associated with the IP address are returned.  Dies if
the address is not a valid IP address.

The returned data is usually a hash reference but could also be a an array
reference or a scalar for custom databases.  Here's an example from an IP to
city database:

  {
    city => {
      geoname_id => 2950159,
      names      => {
        en => "Berlin"
      }
    },
    country => {
      geoname_id => 2921044,
      iso_code   => "DE",
      names      => {
        en => "Germany",
        fr => "Allemagne"
      }
    },
    location => {
      latitude  => 52.524,
      longitude => 13.411
    }
  }

=head2 getcc

  my $country_code = $db->getcc($ip_address);

Takes an IPv4 or IPv6 address as a string and returns a two-letter country
code or the undefined value.  Dies if the address is not a valid IP address.

=head2 record_for_address

  my $data = $db->record_for_address($ip_address);

An alias for C<get> that always returns a scalar.

=head2 iterate_search_tree

  sub data_callback {
    my ($numeric_ip, $prefix_length, $data) = @_;
  }

  sub node_callback {
    my ($node_number, $left_node_number, $right_node_number) = @_;
  }

  $db->iterate_search_tree(\&data_callback, \&node_callback);

Iterates over the entire search tree.  Calls the provided callbacks for each
data record and node in the tree.  Both callbacks are optional.

The data callback is called with a numeric IP address as a L<Math::BigInt>
object, a network prefix length and the data associated with the network.

The node callback is called with the node's number in the tree and the
children's node numbers.

=head2 metadata

  my $metadata = $db->metadata;

Returns an L<IP::Geolocation::MMDB::Metadata> object for the database.

=head2 file

  my $file = $db->file;

Returns the file path passed to the constructor.

=head2 libmaxminddb_version

  my $version = IP::Geolocation::MMDB::libmaxminddb_version;

Returns the libmaxminddb version.

=head1 DIAGNOSTICS

=over

=item B<< The "file" parameter is mandatory >>

The constructor was called without a database filename.

=item B<< Error opening database file >>

The database file could not be read.

=item B<< The IP address you provided is not a valid IPv4 or IPv6 address >>

A parameter did not contain a valid IP address.

=item B<< Error looking up IP address >>

A database error occurred while looking up an IP address.

=item B<< Entry data error looking up >>

A database error occurred while reading the data associated with an IP
address.

=item B<< Error getting metadata >>

An error occurred while reading the database's metadata.

=item B<< Invalid record when reading node >>

Either an invalid node was looked up or the database is corrupt.

=item B<< Unknown record type >>

An unknown record type was found in the database.

=item B<< Invalid depth when reading node >>

An error occurred while traversing the search tree.

=back

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

Requires L<Math::BigInt> version 1.999806, which is distributed with Perl 5.26
and newer.  Requires libmaxminddb 1.2.0 or newer.

Requires a database in the MaxMind DB file format from
L<MaxMind|https://www.maxmind.com/> or L<DP-IP.com|https://db-ip.com/>.

Alien::libmaxminddb from CPAN is a build dependency.  The built module does
only depend on modules that are distributed with Perl.

Install C<pkg-config> and C<libmaxminddb-devel> or C<libmaxminddb-dev> if you
would like to use your operating system's libmaxminddb library.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

If your Perl interpreter does not support 64-bit integers,
MMDB_DATA_TYPE_UINT64 values are put into Math::BigInt objects.

MMDB_DATA_TYPE_UINT128 values are put into Math::BigInt objects.

IP::Geolocation::MMDB can replace MaxMind::DB::Reader in many cases with the
following differences:

=over

=item *

The classes aren't Moo classes.

=item *

There is no replacement for MaxMind::DB::Reader::Decoder.

=back

Create the file F<MaxMind/DB/Reader.pm> in your C<@INC> path if you want to
try IP::Geolocation::MMDB as a replacement for MaxMind::DB::Reader:

  use IP::Geolocation::MMDB;
  @MaxMind::DB::Reader::ISA = qw(IP::Geolocation::MMDB);
  1;

=head1 SEE ALSO

See L<Geo::Location::IP> for object-oriented wrapper classes.

=head1 ACKNOWLEDGEMENTS

Thanks to all who have contributed patches and reported bugs:

=over

=item *

Yujuan Jiang

=back

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
