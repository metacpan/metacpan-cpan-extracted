# -*- mode:perl; coding:iso-8859-1 -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2010,2011,2013,2014,2017,2018 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Geo::Coder::Googlev3;

use strict;
use vars qw($VERSION);
our $VERSION = '0.17';

use Carp            ('croak');
use Encode          ();
use JSON::XS        ();
use LWP::UserAgent  ();
use URI		    ();
use URI::QueryParam ();

sub new {
    my($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{ua}       = delete $args{ua} ||
        LWP::UserAgent->new(
                            agent     => __PACKAGE__ . "/$VERSION libwww-perl/$LWP::VERSION",
                            env_proxy => 1,
                            timeout   => 15,
                           );
    $self->{region}   = delete $args{region} || delete $args{gl};
    $self->{language} = delete $args{language};
    {
        my $sensor;
        if ($args{sensor}) {
            $sensor = delete $args{sensor};
            if ($sensor !~ m{^(false|true)$}) {
                croak "sensor argument has to be either 'false' or 'true'";
            }
        }
        $self->{sensor} = $sensor;
    }
    if ($args{bounds}) {
        $self->bounds(delete $args{bounds});
    }
    $self->{key} = delete $args{key};
    $self->{use_https} = delete $args{use_https};
    croak "Unsupported arguments: " . join(" ", %args) if %args;
    $self;
}

sub ua {
    my $self = shift;
    if (@_) {
	$self->{ua} = shift;
    }
    $self->{ua};
}

sub geocode {
    my($self, %args) = @_;
    my $raw = delete $args{raw};
    my $url = $self->geocode_url(%args);
    my $ua = $self->ua;
    my $resp = $ua->get($url);
    if ($resp->is_success) {
	my $content = $resp->decoded_content(charset => "none");
	my $res = JSON::XS->new->utf8->decode($content);
        if ($raw) {
            return $res;
        }
	if ($res->{status} eq 'OK') {
            if (wantarray) {
                return @{ $res->{results} };
            } else {
                return $res->{results}->[0];
            }
        } elsif ($res->{status} eq 'ZERO_RESULTS') {
            return;
	} else {
	    croak "Fetching $url did not return OK status, but '" . $res->{status} . "'";
	}
    } else {
	croak "Fetching $url failed: " . $resp->status_line;
    }
}

# private!
sub geocode_url {
    my($self, %args) = @_;
    my $loc = $args{location};
    my $url = URI->new(($self->{use_https} ? 'https' : 'http') . '://maps.google.com/maps/api/geocode/json');
    my %url_params;
    $url_params{address}  = $loc;
    $url_params{sensor}   = $self->{sensor}   if defined $self->{sensor};
    $url_params{region}   = $self->{region}   if defined $self->{region};
    $url_params{language} = $self->{language} if defined $self->{language};
    if (defined $self->{bounds}) {
        $url_params{bounds} = join '|', map { $_->{lat}.','.$_->{lng} } @{ $self->{bounds} };
    }
    $url_params{key}      = $self->{key}      if defined $self->{key};
    while(my($k,$v) = each %url_params) {
        $url->query_param($k => Encode::encode_utf8($v));
    }
    $url = $url->as_string;
    $url;
}

sub region {
    my $self = shift;
    $self->{region} = shift if @_;
    return $self->{region};
}


sub language {
    my $self = shift;
    $self->{language} = shift if @_;
    return $self->{language};
}

sub sensor {
    my $self = shift;
    $self->{sensor} = shift if @_;
    return $self->{sensor};
}

use constant _BOUNDS_ERROR_MSG => "bounds must be in the form [{lat=>...,lng=>...}, {lat=>...,lng=>...}]";

sub bounds {
    my $self = shift;
    if (@_) {
        my $bounds = shift;
        if (ref $bounds ne 'ARRAY') {
            croak _BOUNDS_ERROR_MSG . ', but the supplied parameter is not even an array reference.';
        }
        if (@$bounds != 2) {
            croak _BOUNDS_ERROR_MSG . ', but the supplied parameter has not exactly two array elements.';
        }
        if ((grep { ref $_ eq 'HASH' && exists $_->{lng} && exists $_->{lat} ? 1 : 0 } @$bounds) != 2) {
            croak _BOUNDS_ERROR_MSG . ', but the supplied elements are not lat/lng hashes.';
        }
        $self->{bounds} = $bounds;
    }
    return $self->{bounds};
}

1;

__END__

=encoding ISO8859-1

=head1 NAME

Geo::Coder::Googlev3 - Google Maps v3 Geocoding API 

=head1 SYNOPSIS

    use Geo::Coder::Googlev3;

    my $geocoder = Geo::Coder::Googlev3->new;
    my $location  = $geocoder->geocode(location => 'Brandenburger Tor, Berlin');
    my @locations = $geocoder->geocode(location => 'Berliner Straße, Berlin, Germany');

=head1 DESCRIPTION

Use this module just like L<Geo::Coder::Google>. Note that no
C<apikey> is used in Google's v3 API, and the returned data structure
differs.

Please check also
L<https://developers.google.com/maps/documentation/geocoding/>
for more information about Google's Geocoding API and especially usage
limits.

=head2 CONSTRUCTOR

=over

=item new

    $geocoder = Geo::Coder::Googlev3->new;
    $geocoder = Geo::Coder::Googlev3->new(language => 'de', gl => 'es');

Creates a new geocoding object.

The C<ua> parameter may be supplied to override the default
L<LWP::UserAgent> object. The default C<LWP::UserAgent> object sets
the C<timeout> to 15 seconds and enables the C<env_proxy> option.

The L<Geo::Coder::Google>'s C<oe> parameter is not supported.

The parameters C<region>, C<language>, C<bounds>, and C<key> are also
accepted. The C<bounds> parameter should be in the form:

   [{lat => ..., lng => ...}, {lat => ..., lng => ...}]

The parameter C<sensor> should be set to the string C<true> if the
geocoding request comes from a device with a location sensor (see
L<https://developers.google.com/maps/documentation/geocoding/#GeocodingRequests>).
There's no default.

By default queries are done using C<http>. By setting the C<use_https>
parameter to a true value C<https> is used.

=back

=head2 METHODS

=over

=item geocode

    $location = $geocoder->geocode(location => $location);
    @locations = $geocoder->geocode(location => $location);

Queries I<$location> to Google Maps geocoding API. In scalar context
it returns a hash reference of the first (best matching?) location. In
list context it returns a list of such hash references.

The returned data structure looks like this:

  {
    "formatted_address" => "Brandenburger Tor, Pariser Platz 7, 10117 Berlin, Germany",
    "types" => [
      "point_of_interest",
      "establishment"
    ],
    "address_components" => [
      {
        "types" => [
          "point_of_interest",
          "establishment"
        ],
        "short_name" => "Brandenburger Tor",
        "long_name" => "Brandenburger Tor"
      },
      {
        "types" => [
          "street_number"
        ],
        "short_name" => 7,
        "long_name" => 7
      },
      {
        "types" => [
          "route"
        ],
        "short_name" => "Pariser Platz",
        "long_name" => "Pariser Platz"
      },
      {
        "types" => [
          "sublocality",
          "political"
        ],
        "short_name" => "Mitte",
        "long_name" => "Mitte"
      },
      {
        "types" => [
          "locality",
          "political"
        ],
        "short_name" => "Berlin",
        "long_name" => "Berlin"
      },
      {
        "types" => [
          "administrative_area_level_2",
          "political"
        ],
        "short_name" => "Berlin",
        "long_name" => "Berlin"
      },
      {
        "types" => [
          "administrative_area_level_1",
          "political"
        ],
        "short_name" => "Berlin",
        "long_name" => "Berlin"
      },
      {
        "types" => [
          "country",
          "political"
        ],
        "short_name" => "DE",
        "long_name" => "Germany"
      },
      {
        "types" => [
          "postal_code"
        ],
        "short_name" => 10117,
        "long_name" => 10117
      }
    ],
    "geometry" => {
      "viewport" => {
        "southwest" => {
          "lat" => "52.5094785",
          "lng" => "13.3617711"
        },
        "northeast" => {
          "lat" => "52.5230586",
          "lng" => "13.3937859"
        }
      },
      "location" => {
        "lat" => "52.5162691",
        "lng" => "13.3777785"
      },
      "location_type" => "APPROXIMATE"
    }
  };

The B<raw> option may be set to a true value to get the uninterpreted,
raw result from the API. Just the JSON data will be translated into a
perl hash.

    $raw_result = $geocoder->geocode(location => $location, raw => 1);

=item region

Accessor for the C<region> parameter. The value should be a country
code ("es", "dk", "us", etc). Use this to tell the webservice to
prefer matches from that region. See the Google documentation for more
information.

=item language

Accessor for the C<language> parameter.

=item bounds

Accessor for the C<bounds> parameter.

=item sensor

Accessor for the C<sensor> parameter.

=back  

=head1 AUTHOR

Slaven Rezic <srezic@cpan.org>

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Geo::Coder::Google>, L<Geo::Coder::Many>.

=cut

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim:sw=4:ts=8:sta:et
