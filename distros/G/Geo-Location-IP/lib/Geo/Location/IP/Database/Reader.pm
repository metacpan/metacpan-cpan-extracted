package Geo::Location::IP::Database::Reader;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Object::Pad;

class Geo::Location::IP::Database::Reader
    :isa(Geo::Location::IP::Database::SimpleReader);

our $VERSION = 0.001;

use Geo::Location::IP::Address;
use Geo::Location::IP::Error::Generic;
use Geo::Location::IP::Error::AddressNotFound;

method anonymous_ip ($key, $ip) {
    $self->_assert_database_type(qr{Anonymous-IP});
    $self->_assert_ip_address($key, $ip);
    my $model = $self->SUPER::anonymous_ip($key => $ip);
    $self->_assert_record($model, $ip);
    return $model;
}

method asn ($key, $ip) {
    $self->_assert_database_type(qr{ASN});
    $self->_assert_ip_address($key, $ip);
    my $model = $self->SUPER::asn($key => $ip);
    $self->_assert_record($model, $ip);
    return $model;
}

method city ($key, $ip) {
    $self->_assert_database_type(qr{City});
    $self->_assert_ip_address($key, $ip);
    my $model = $self->SUPER::city($key => $ip);
    $self->_assert_record($model, $ip);
    return $model;
}

method connection_type ($key, $ip) {
    $self->_assert_database_type(qr{Connection-Type});
    $self->_assert_ip_address($key, $ip);
    my $model = $self->SUPER::connection_type($key => $ip);
    $self->_assert_record($model, $ip);
    return $model;
}

method country ($key, $ip) {
    $self->_assert_database_type(qr{Country});
    $self->_assert_ip_address($key, $ip);
    my $model = $self->SUPER::country($key => $ip);
    $self->_assert_record($model, $ip);
    return $model;
}

method domain ($key, $ip) {
    $self->_assert_database_type(qr{Domain});
    $self->_assert_ip_address($key, $ip);
    my $model = $self->SUPER::domain($key => $ip);
    $self->_assert_record($model, $ip);
    return $model;
}

method enterprise ($key, $ip) {
    $self->_assert_database_type(qr{Enterprise});
    $self->_assert_ip_address($key, $ip);
    my $model = $self->SUPER::enterprise($key => $ip);
    $self->_assert_record($model, $ip);
    return $model;
}

method isp ($key, $ip) {
    $self->_assert_database_type(qr{ISP});
    $self->_assert_ip_address($key, $ip);
    my $model = $self->SUPER::isp($key => $ip);
    $self->_assert_record($model, $ip);
    return $model;
}

our $private_ip_address_regex = qr{
    \A
    10\.
    |
    172\.(?:1[6-9]|2[0-9]|3[01])\.
    |
    192\.168\.
    |
    f[cd]
}xms;

method _assert_database_type ($type_regex) {
    state $type = $self->metadata->database_type;
    if ($type !~ $type_regex) {
        my $class   = ref $self;
        my $method  = (caller(1))[3] =~ s{.+::}{}r;
        my $message = "The $class->$method() method cannot be called with a "
            . "$type database";
        Geo::Location::IP::Error::Generic->throw(message => $message);
    }
    return;
}

method _assert_ip_address ($key, $ip) {
    if (!defined $ip || !defined $key || $key ne 'ip') {
        my $class   = ref $self;
        my $method  = (caller(1))[3] =~ s{.+::}{}r;
        my $message = "Required param (ip) was missing when calling $method "
            . "on $class";
            Geo::Location::IP::Error::Generic->throw(message => $message);
    }
    if ($ip eq 'me') {
        my $class   = ref $self;
        my $method  = (caller(1))[3] =~ s{.+::}{}r;
        my $message = "me is not a valid IP when calling $method on $class";
        Geo::Location::IP::Error::Generic->throw(message => $message);
    }
    if ($ip =~ $private_ip_address_regex) {
        my $class   = ref $self;
        my $method  = (caller(1))[3] =~ s{.+::}{}r;
        my $message = "The IP address you provided ($ip) is not a public "
            . "IP address when calling $method on $class";
        Geo::Location::IP::Error::Generic->throw(message => $message);
    }
    return;
}

method _assert_record ($obj, $ip) {
    if (!defined $obj) {
        my $ip_address = Geo::Location::IP::Address->new(
            address => $ip,
            network => undef,
        );
        Geo::Location::IP::Error::AddressNotFound->throw(
            message    => "No record found for IP address $ip",
            ip_address => $ip_address,
        );
    }
    return;
}

method _get ($ip) {
    local $@;
    my @result = eval { $self->SUPER::_get($ip) };
    if (my $e = $@) {
        Geo::Location::IP::Error::Generic->throw(message => $e);
    }
    return @result;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Geo::Location::IP::Database::Reader - Read MaxMind DB files

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Geo::Location::IP::Database::Reader;
  my $reader = Geo::Location::IP::Database::Reader->new(
    file    => '/path/to/City.mmdb',
    locales => ['de', 'en'],
  );
  eval {
    my $city_model = $reader->city(ip => '1.2.3.4');
    my $city       = $city_model->city;
    my $country    = $city_model->country;
    printf "%s in %s\n", $city->name, $country->name;
  };

=head1 DESCRIPTION

Read MaxMind DB files and map IP addresses to location information such as
country and city names.

This is a L<Geo::Location::IP::Database::SimpleReader> subclass that throws
L<Geo::Location::IP::Error::Generic> and
L<Geo::Location::IP::Error::AddressNotFound> exceptions on unsuccessful
queries.

=head1 SUBROUTINES/METHODS

=head2 anonymous_ip

  my $anon_ip_model = eval { $reader->anonymous_ip(ip => '1.2.3.4') };

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::AnonymousIP> object.  Dies on unsuccessful
queries.

=head2 asn

  my $asn_model = eval { $reader->asn(ip => '1.2.3.4') };

Takes an IP address as a string and returns a L<Geo::Location::IP::Model::ASN>
object.  Dies on unsuccessful queries.

=head2 city

  my $city_model = eval { $reader->city(ip => '1.2.3.4') };

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::City> object.  Dies on unsuccessful queries.

=head2 connection_type

  my $ct_model = eval { $reader->connection_type(ip => '1.2.3.4') };

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::ConnectionType> object.  Dies on unsuccessful
queries.

=head2 country

  my $country_model = eval { $reader->country(ip => '1.2.3.4') };

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::Country> object.  Dies on unsuccessful queries.

=head2 domain

  my $domain_model = eval { $reader->domain(ip => '1.2.3.4') };

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::Domain> object.  Dies on unsuccessful queries.

=head2 enterprise

  my $enterprise_model = eval { $reader->enterprise(ip => '1.2.3.4') };

Takes an IP address as a string and returns a
L<Geo::Location::IP::Model::Enterprise> object.  Dies on unsuccessful queries.

=head2 isp

  my $isp_model = eval { $reader->isp(ip => '1.2.3.4') };

Takes an IP address as a string and returns a L<Geo::Location::IP::Model::ISP>
object.  Dies on unsuccessful queries.

=for Pod::Coverage DOES META

=head1 DIAGNOSTICS

=over

=item B<< ->METHOD() method cannot be called with a TYPE database >>

A query method has been called on the wrong database type.

=item B<< Required param (ip) was missing >>

A query method has been called with an undefined value.

=item B<< me is not a valid IP >>

The string "me" cannot be passed as an IP address.

=item B<< The IP address you provided (IP) is not a public IP address >>

The specified IP address is private.

=item B<< No record found for IP address >>

No data is associated with the specified IP address.

=back

See also L<IP::Geolocation::MMDB>.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

See L<Geo::Location::IP::Database::SimpleReader>.

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
