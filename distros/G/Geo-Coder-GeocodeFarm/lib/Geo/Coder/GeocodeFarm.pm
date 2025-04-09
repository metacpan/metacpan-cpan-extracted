package Geo::Coder::GeocodeFarm;

=head1 NAME

Geo::Coder::GeocodeFarm - Geocode addresses with the GeocodeFarm API

=head1 SYNOPSIS

=for markdown ```perl

    use Geo::Coder::GeocodeFarm;

    my $geocoder = Geo::Coder::GeocodeFarm->new(
        key => 'YOUR-API-KEY-HERE',
    );

    my $result = $geocoder->geocode(
        location => '530 W Main St Anoka MN 55303 US',
    );
    printf "%f,%f\n",
        $result->{coordinates}{lat},
        $result->{coordinates}{lon};

    my $reverse = $geocoder->reverse_geocode(
        lat      => '45.2040305',
        lon      => '-93.3995728',
    );
    print $reverse->{formatted_address}, "\n";

=for markdown ```

=head1 DESCRIPTION

The C<Geo::Coder::GeocodeFarm> module provides an interface to the geocoding
functionality of the GeocodeFarm API v4.

=cut

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.0500';

use Carp qw(croak);
use Encode;
use HTTP::Tiny;
use URI;
use URI::QueryParam;
use JSON;
use Scalar::Util qw(blessed);

use constant DEBUG => !!$ENV{PERL_GEO_CODER_GEOCODEFARM_DEBUG};

=head1 METHODS

=head2 new

=for markdown ```perl

    $geocoder = Geo::Coder::GeocodeFarm->new(
        key    => 'YOUR-API-KEY-HERE',
        url    => 'https://api.geocode.farm/',
        ua     => HTTP::Tiny->new,
        parser => JSON->new->utf8,
        raise_failure => 1,
    );

=for markdown ```

Creates a new geocoding object with optional arguments.

An API key is required and can be obtained at
L<https://geocode.farm/store/api-services/>

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless +{
        ua => $args{ua} || HTTP::Tiny->new(
            agent => __PACKAGE__ . "/$VERSION",
        ),
        url           => $args{url}    || 'https://api.geocode.farm/',
        parser        => $args{parser} || JSON->new->utf8,
        raise_failure => defined $args{raise_failure} ? $args{raise_failure} : 1,
        %args,
    } => $class;

    croak "API key is required" unless $self->{key};

    return $self;
}

=head2 geocode

=for markdown ```perl

    $result = $geocoder->geocode(
        location => $location,
    )

=for markdown ```

Forward geocoding takes a provided address or location and returns the
coordinate set for the requested location.

Method throws an error (or returns failure as nested list if raise_failure
argument is false) if the service failed to find coordinates or wrong key was
used.

=cut

sub geocode {
    my ($self, %args) = @_;
    my $addr = $args{location} || croak "Attribute (location) is required";
    my $results = $self->_request('forward', addr => $addr);
    return $results->{result};    # Adjust based on actual API response structure
}

=head2 reverse_geocode

=for markdown ```perl

    $result = $geocoder->reverse_geocode(
        lat      => $latitude,
        lon      => $longitude,
    )

=for markdown ```

Reverse geocoding takes a provided coordinate set and returns the address for
the requested coordinates.

Method throws an error (or returns failure as nested list if raise_failure
argument is false) if the service failed to find coordinates or wrong key was
used.

=cut

sub reverse_geocode {
    my ($self, %args) = @_;
    my $lat = defined $args{lat} ? $args{lat} : croak "Attribute (lat) is required";
    my $lon = defined $args{lon} ? $args{lon} : croak "Attribute (lon) is required";
    my $results = $self->_request('reverse', lat => $lat, lon => $lon);
    return unless $results->{result}{"0"} and $results->{result}{accuracy};
    my %result = %{ $results->{result}{"0"} };
    $result{accuracy} = $results->{result}{accuracy};
    return \%result;
}

sub _request {
    my ($self, $type, %args) = @_;

    my $url = URI->new_abs($type eq 'forward' ? 'forward/' : 'reverse/', $self->{url});

    if ($type eq 'forward') {
        $url->query_param_append(addr => $args{addr});
    } elsif ($type eq 'reverse') {
        $url->query_param_append(lat => $args{lat});
        $url->query_param_append(lon => $args{lon});
    } else {
        croak "Unknown type for request";
    }

    $url->query_param_append(key => $self->{key});
    warn $url if DEBUG;

    my $res = $self->{ua}->get($url);

    my $content = do {
        if (blessed $res and $res->isa('HTTP::Response')) {
            croak $res->status_line if $self->{raise_failure} and not $res->is_success;
            $res->decoded_content;
        } elsif (ref $res eq 'HASH') {
            croak "@{[$res->{status}, $res->{reason}]}" if $self->{raise_failure} and not $res->{success};
            $res->{content};
        } else {
            croak "Wrong response $res";
        }
    };

    warn $content if DEBUG;
    return unless $content;

    my $data = eval { $self->{parser}->decode(Encode::encode_utf8($content)) };
    croak $@ if $@;

    croak "GeocodeFarm API returned status: ", $data->{STATUS}{status} || 'unknown'
        if ($self->{raise_failure} and ($data->{STATUS}{status} || '') ne 'SUCCESS');

    return $data->{RESULTS};
}

1;

=head1 SEE ALSO

L<https://geocode.farm/>

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/issues>

The code repository is available at
L<https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2013, 2015, 2025 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
