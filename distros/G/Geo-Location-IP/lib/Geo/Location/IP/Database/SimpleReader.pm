package Geo::Location::IP::Database::SimpleReader;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Database::SimpleReader;

our $VERSION = 0.005;

use Geo::Location::IP::Address;
use Geo::Location::IP::Model::AnonymousIP;
use Geo::Location::IP::Model::ASN;
use Geo::Location::IP::Model::City;
use Geo::Location::IP::Model::ConnectionType;
use Geo::Location::IP::Model::Country;
use Geo::Location::IP::Model::Domain;
use Geo::Location::IP::Model::Enterprise;
use Geo::Location::IP::Model::ISP;
use Geo::Location::IP::Network;
use IP::Geolocation::MMDB 1.011;

apply Geo::Location::IP::Role::HasLocales;

field $db;

#<<<
ADJUST :params (:$file) {
    $db = IP::Geolocation::MMDB->new(file => $file);
}
#>>>

method anonymous_ip ($, $ip) {
    my ($hash_ref, $ip_address) = $self->_get($ip);
    if (defined $hash_ref) {
        return Geo::Location::IP::Model::AnonymousIP->_from_hash($hash_ref,
            $ip_address);
    }
    return;
}

method asn ($, $ip) {
    my ($hash_ref, $ip_address) = $self->_get($ip);
    if (defined $hash_ref) {
        return Geo::Location::IP::Model::ASN->_from_hash($hash_ref,
            $ip_address);
    }
    return;
}

method city ($, $ip) {
    my ($hash_ref, $ip_address) = $self->_get($ip);
    if (defined $hash_ref) {
        return Geo::Location::IP::Model::City->_from_hash($hash_ref,
            $ip_address, $self->locales);
    }
    return;
}

method connection_type ($, $ip) {
    my ($hash_ref, $ip_address) = $self->_get($ip);
    if (defined $hash_ref) {
        return Geo::Location::IP::Model::ConnectionType->_from_hash($hash_ref,
            $ip_address);
    }
    return;
}

method country ($, $ip) {
    my ($hash_ref, $ip_address) = $self->_get($ip);
    if (defined $hash_ref) {
        return Geo::Location::IP::Model::Country->_from_hash($hash_ref,
            $ip_address, $self->locales);
    }
    return;
}

method domain ($, $ip) {
    my ($hash_ref, $ip_address) = $self->_get($ip);
    if (defined $hash_ref) {
        return Geo::Location::IP::Model::Domain->_from_hash($hash_ref,
            $ip_address);
    }
    return;
}

method enterprise ($, $ip) {
    my ($hash_ref, $ip_address) = $self->_get($ip);
    if (defined $hash_ref) {
        return Geo::Location::IP::Model::Enterprise->_from_hash($hash_ref,
            $ip_address, $self->locales);
    }
    return;
}

method isp ($, $ip) {
    my ($hash_ref, $ip_address) = $self->_get($ip);
    if (defined $hash_ref) {
        return Geo::Location::IP::Model::ISP->_from_hash($hash_ref,
            $ip_address);
    }
    return;
}

method file () {
    return $db->file;
}

method metadata () {
    return $db->metadata;
}

method _get ($ip) {
    my ($hash_ref, $prefixlen) = $db->get($ip);
    my $ip_address;
    if (defined $hash_ref) {
        my $network = Geo::Location::IP::Network->new(
            address   => $ip,
            prefixlen => $prefixlen,
        );
        $ip_address = Geo::Location::IP::Address->new(
            address => $ip,
            network => $network,
        );
    }
    return $hash_ref, $ip_address;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Database::SimpleReader - Read MaxMind DB files

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Geo::Location::IP::Database::SimpleReader;
  my $reader = Geo::Location::IP::Database::SimpleReader->new(
    file    => '/path/to/City.mmdb',
    locales => ['de', 'en'],
  );
  my $ip = '1.2.3.4';
  my $city_model = $reader->city(ip => $ip)
    or die "No record found for IP address $ip";
  my $city    = $city_model->city;
  my $country = $city_model->country;
  printf "%s in %s\n", $city->name, $country->name;

=head1 DESCRIPTION

Read MaxMind DB files and map IP addresses to location information such as
country and city names.

The query methods return the undefined value on unsuccessful queries.  Use
L<Geo::Location::IP::Database::Reader> if you prefer exceptions.

=head1 SUBROUTINES/METHODS

=head2 new

  my $reader = Geo::Location::IP::Database::SimpleReader->new(
      file    => '/path/to/City.mmdb',
      locales => ['de', 'en'],
  );

Creates a new reader object.  Dies if the specified file cannot be read.

The C<file> parameter is a path to a database in the MaxMind DB file format.

The C<locales> parameter is an array reference of acceptable locales in
preferred order.  The default is ['en'].  It is recommended to always append
'en' to your list, as English may be the only language in the database.
Common locale codes are:

=over

=item *

de - German

=item *

en - English

=item *

es - Spanish

=item *

fa - Farsi

=item *

fr - French

=item *

ja - Japanese

=item *

ko - Korean

=item *

pt-BR - Brazilian Portuguese

=item *

ru - Russian

=item *

zh-CN - Simplified Chinese

=back

=head2 file

  my $file = $reader->file;

Returns the file path passed to the constructor.

=head2 locales

  my @locales = @{$reader->locales};

Returns the locale codes passed to the constructor.

=head2 metadata

  my $metadata = $reader->metadata;

Returns an L<IP::Geolocation::MMDB::Metadata> object containing information
about the database.

=head2 anonymous_ip

  my $anon_ip_model = $reader->anonymous_ip(ip => '1.2.3.4');

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::AnonymousIP> object or the undefined value.  Dies
if the address is not a valid IP address.

=head2 asn

  my $asn_model = $reader->asn(ip => '1.2.3.4');

Takes an IP address as a string and returns a L<Geo::Location::IP::Model::ASN>
object or the undefined value.  Dies if the address is not a valid IP address.

=head2 city

  my $city_model = $reader->city(ip => '1.2.3.4');

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::City> object or the undefined value.  Dies if the
address is not a valid IP address.

=head2 connection_type

  my $ct_model = $reader->connection_type(ip => '1.2.3.4');

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::ConnectionType> object or the undefined value.
Dies if the address is not a valid IP address.

=head2 country

  my $country_model = $reader->country(ip => '1.2.3.4');

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::Country> object or the undefined value.  Dies if
the address is not a valid IP address.

=head2 domain

  my $domain_model = $reader->domain(ip => '1.2.3.4');

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::Domain> object or the undefined value.  Dies if
the address is not a valid IP address.

=head2 enterprise

  my $enterprise_model = $reader->enterprise(ip => '1.2.3.4');

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::Enterprise> object or the undefined value.  Dies
if the address is not a valid IP address.

=head2 isp

  my $isp_model = $reader->isp(ip => '1.2.3.4');

Takes an IP address as a string and returns a L<Geo::Location::IP::Model::ISP>
object or the undefined value.  Dies if the address is not a valid IP address.

=for Pod::Coverage DOES META

=head1 DIAGNOSTICS

See L<IP::Geolocation::MMDB>.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

Requires the module L<IP::Geolocation::MMDB>.

Requires databases in the MaxMind DB file format from
L<MaxMind|https://www.maxmind.com/> or L<DP-IP.com|https://db-ip.com/>.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
