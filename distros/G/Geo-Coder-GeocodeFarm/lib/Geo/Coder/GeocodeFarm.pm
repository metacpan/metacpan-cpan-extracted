package Geo::Coder::GeocodeFarm;

=head1 NAME

Geo::Coder::GeocodeFarm - Geocode addresses with the GeocodeFarm API

=head1 SYNOPSIS

  use Geo::Coder::GeocodeFarm;

  my $geocoder = Geo::Coder::GeocodeFarm->new(
      key => '3d517dd448a5ce1c2874637145fed69903bc252a',
  );
  my $result = $geocoder->geocode(
      location => '530 W Main St Anoka MN 55303 US',
      lang     => 'en',
      count    => 1,
  );
  printf "%f,%f",
      $result->{RESULTS}{COORDINATES}{latitude},
      $result->{RESULTS}{COORDINATES}{longitude};

=head1 DESCRIPTION

The C<Geo::Coder::GeocodeFarm> module provides an interface to the geocoding
functionality of the GeocodeFarm API v3.

=for readme stop

=cut


use 5.006;
use strict;
use warnings;

our $VERSION = '0.0402';

use Carp qw(croak);
use Encode;
use HTTP::Tiny;
use URI;
use URI::QueryParam;
use JSON;
use Scalar::Util qw(blessed);

use constant DEBUG => !! $ENV{PERL_GEO_CODER_GEOCODEFARM_DEBUG};


=head1 METHODS

=head2 new

  $geocoder = Geo::Coder::GeocodeFarm->new(
      key    => '3d517dd448a5ce1c2874637145fed69903bc252a',
      url    => 'https://www.geocode.farm/v3/',
      ua     => HTTP::Tiny->new,
      parser => JSON->new->utf8,
      raise_failure => 1,
  );

Creates a new geocoding object with optional arguments.

An API key is optional and can be obtained at
L<https://www.geocode.farm/dashboard/login/>

C<url> argument is optional and then the default address is http-based if
C<key> argument is missing and https-based if C<key> is provided.

C<ua> argument is a L<HTTP::Tiny> object by default and can be also set to
L<LWP::UserAgent> object.

New account can be registered at L<https://www.geocode.farm/register/>

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless +{
        ua     => $args{ua} || HTTP::Tiny->new(
            agent => __PACKAGE__ . "/$VERSION",
        ),
        url    => sprintf('%s://www.geocode.farm/v3/', $args{key} ? 'https' : 'http'),
        parser => $args{parser} || JSON->new->utf8,
        raise_failure => $args{raise_failure} || 1,
        %args,
    } => $class;

    return $self;
}


=head2 geocode

  $result = $geocoder->geocode(
      location => $location,
      lang     => 'en',  # optional: 'en' or 'de'
      country  => 'US',  # optional
      count    => 1,     # optional
  )

Forward geocoding takes a provided address or location and returns the
coordinate set for the requested location as a nested list:

    {
        "geocoding_results": {
            "LEGAL_COPYRIGHT": {
                "copyright_notice": "Copyright (c) 2015 Geocode.Farm - All Rights Reserved.",
                "copyright_logo": "https:\/\/www.geocode.farm\/images\/logo.png",
                "terms_of_service": "https:\/\/www.geocode.farm\/policies\/terms-of-service\/",
                "privacy_policy": "https:\/\/www.geocode.farm\/policies\/privacy-policy\/"
            },
            "STATUS": {
                "access": "FREE_USER, ACCESS_GRANTED",
                "status": "SUCCESS",
                "address_provided": "530 W Main St Anoka MN 55303 US",
                "result_count": 1
            },
            "ACCOUNT": {
                "ip_address": "1.2.3.4",
                "distribution_license": "NONE, UNLICENSED",
                "usage_limit": "250",
                "used_today": "26",
                "used_total": "26",
                "first_used": "26 Mar 2015"
            },
            "RESULTS": [
                {
                    "result_number": 1,
                    "formatted_address": "530 West Main Street, Anoka, MN 55303, USA",
                    "accuracy": "EXACT_MATCH",
                    "ADDRESS": {
                        "street_number": "530",
                        "street_name": "West Main Street",
                        "locality": "Anoka",
                        "admin_2": "Anoka County",
                        "admin_1": "Minnesota",
                        "postal_code": "55303",
                        "country": "United States"
                    },
                    "LOCATION_DETAILS": {
                        "elevation": "UNAVAILABLE",
                        "timezone_long": "UNAVAILABLE",
                        "timezone_short": "America\/Menominee"
                    },
                    "COORDINATES": {
                        "latitude": "45.2041251174690",
                        "longitude": "-93.4003513528652"
                    },
                    "BOUNDARIES": {
                        "northeast_latitude": "45.2041251778513",
                        "northeast_longitude": "-93.4003513845523",
                        "southwest_latitude": "45.2027761197097",
                        "southwest_longitude": "-93.4017002802923"
                    }
                }
            ],
            "STATISTICS": {
                "https_ssl": "DISABLED, INSECURE"
            }
        }
    }

Method throws an error (or returns failure as nested list if raise_failure
argument is false) if the service failed to find coordinates or wrong key was
used.

Methods throws an error if there was an other problem.

=cut

sub geocode {
    my ($self, %args) = @_;

    my ($addr) = do {
        if (defined $args{location}) {
            $args{location};
        }
        elsif (defined $args{addr}) {
            $args{addr};
        }
        else {
            croak "Attribute (location) or attribute (addr) is required";
        }
    };

    return $self->_request('forward', %args, addr => $addr);
};


=head2 reverse_geocode

  $result = $geocoder->reverse_geocode(
      lat      => $latitude,
      lon      => $longtitude,
      lang     => 'en',  # optional: 'en' or 'de'
      country  => 'US',  # optional
      count    => 1,     # optional
  )

or

  $result = $geocoder->reverse_geocode(
      latlng => "$latitude,$longtitude",
      # ... optional args
  )

Reverse geocoding takes a provided coordinate set and returns the address for
the requested coordinates as a nested list. Its format is the same as for
L</geocode> method.

Method throws an error (or returns failure as nested list if raise_failure
argument is false) if the service failed to find coordinates or wrong key was
used.

Method throws an error if there was an other problem.

=cut

sub reverse_geocode {
    my ($self, %args) = @_;

    my ($lat, $lon) = do {
        if (defined $args{latlng}) {
            my @latlng = split ',', $args{latlng};
            croak "Attribute (latlng) is invalid" unless @latlng == 2;
            @latlng;
        }
        elsif (defined $args{lat} and defined $args{lon}) {
            @args{qw(lat lon)};
        }
        else {
            croak "Attribute (latlng) or attributes (lat) and (lon) are required";
        }
    };

    return $self->_request('reverse', %args, lat => $lat, lon => $lon);
};


sub _request {
    my ($self, $type, %args) = @_;

    my $url = URI->new_abs(sprintf('json/%s/', $type), $self->{url});

    if ($type eq 'forward') {
        $url->query_param_append(addr => $args{addr});
    } elsif ($type eq 'reverse') {
        $url->query_param_append(lat => $args{lat});
        $url->query_param_append(lon => $args{lon});
    } else {
        croak "Unknown type for request";
    }

    $url->query_param_append(key => $self->{key}) if $self->{key};
    warn $url if DEBUG;

    my $res = $self->{ua}->get($url);

    my $content = do {
        if (blessed $res and $res->isa('HTTP::Response')) {
            croak $res->status_line unless $res->is_success;
            $res->decoded_content;
        } elsif (ref $res eq 'HASH') {
            croak "@{[$res->{status}, $res->{reason}]}" unless $res->{success};
            $res->{content};
        } else {
            croak "Wrong response $res ";
        }
    };

    warn $content if DEBUG;
    return unless $content;

    my $data = eval { $self->{parser}->decode($content) };
    croak $content if $@;

    croak "GeocodeFarm API returned status: ", $data->{geocoding_results}{STATUS}{status}
        if ($self->{raise_failure} and ($data->{geocoding_results}{STATUS}{status}||'') ne 'SUCCESS');

    return $data->{geocoding_results};
};


1;


=for readme continue

=head1 SEE ALSO

L<https://www.geocode.farm/>

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-Geo-Coder-GeocodeFarm/issues>

The code repository is available at
L<http://github.com/dex4er/perl-Geo-Coder-GeocodeFarm>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2013, 2015 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
