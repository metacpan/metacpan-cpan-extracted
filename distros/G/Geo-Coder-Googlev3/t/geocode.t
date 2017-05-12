# -*- coding:iso-8859-1; -*-

use strict;
use FindBin;
use lib "$FindBin::RealBin";

use Test::More 'no_plan';

sub within ($$$$$$);
sub safe_geocode (&);

use_ok 'Geo::Coder::Googlev3';

my $geocoder = Geo::Coder::Googlev3->new;
isa_ok $geocoder, 'Geo::Coder::Googlev3';

SKIP: {

{ # list context
    ## There are eight hits in Berlin. Google uses to know seven of them.
    ## But beginning from approx. 2010-05, only one location is returned.
    #my @locations = $geocoder->geocode(location => 'Berliner Straße, Berlin, Germany');
    #cmp_ok scalar(@locations), ">=", 1, "One or more results found";
    #like $locations[0]->{formatted_address}, qr{Berliner Straße}, 'First result looks OK';

    my @locations = safe_geocode { $geocoder->geocode(location => 'Waterloo, UK') };
    # Since approx. 2011-12 there's only one result, previously it was more
    cmp_ok scalar(@locations), ">=", 1, "One or more results found";
    like $locations[0]->{formatted_address}, qr{Waterloo}, 'First result looks OK';
}

{
    my $location = safe_geocode { $geocoder->geocode(location => 'Brandenburger Tor, Berlin, Germany') };
    # Since approx. 2011-12 "brandenburg gate" instead of "brandenburger tor" is returned
    # Since approx. 2017-01 "pariser platz" is returned
    like $location->{formatted_address}, qr{(brandenburger tor.*berlin|brandenburg gate|pariser platz.*berlin.*germany)}i;
    my($lat, $lng) = @{$location->{geometry}->{location}}{qw(lat lng)};
    within $lat, $lng, 52.5, 52.6, 13.3, 13.4;
}

{
    # ... but if language=>"de" is forced, then the German name is returned
    my $geocoder_de = Geo::Coder::Googlev3->new(language => 'de');
    my $location = safe_geocode { $geocoder_de->geocode(location => 'Brandenburger Tor, Berlin, Germany') };
    # Since approx. 2017-01 "pariser platz" is returned
    like $location->{formatted_address}, qr{(brandenburger tor.*berlin|pariser platz.*berlin.*deutschland)}i;
    my($lat, $lng) = @{$location->{geometry}->{location}}{qw(lat lng)};
    within $lat, $lng, 52.5, 52.6, 13.3, 13.4;
}

# Since approx. 2014-10 "Oeschelbronner Path" instead of "Öschelbronner Weg" is returned (!)
{ # encoding checks - bytes
    my $location = safe_geocode { $geocoder->geocode(location => 'Öschelbronner Weg, Berlin, Germany') };
    like $location->{formatted_address}, qr{schelbronner (weg|path).*berlin}i;
    my($lat, $lng) = @{$location->{geometry}->{location}}{qw(lat lng)};
    within $lat, $lng, 52.6, 52.7, 13.3, 13.4;
}

{ # encoding checks - utf8
    my $street = 'Öschelbronner Weg';
    utf8::upgrade($street);
    my $location = safe_geocode { $geocoder->geocode(location => "$street, Berlin, Germany") };
    like $location->{formatted_address}, qr{schelbronner (weg|path).*berlin}i;
    my($lat, $lng) = @{$location->{geometry}->{location}}{qw(lat lng)};
    within $lat, $lng, 52.6, 52.7, 13.3, 13.4;
}

{ # encoding checks - more utf8
    my $street = "Trg bana Josipa Jela\x{10d}i\x{107}a";
    my $alternative = "Ban Jela\x{10d}i\x{107} Square"; # outcome as of 2011-02-02
    my $alternative2 = 'City of Zagreb, Croatia'; # happened once in February 2011, see http://www.cpantesters.org/cpan/report/447c31b8-6cb5-1014-b648-c13506c0976e
    my $location = safe_geocode { $geocoder->geocode(location => "$street, Zagreb, Croatia") };
    like $location->{formatted_address}, qr{($street|$alternative|$alternative2)}i;
    my($lat, $lng) = @{$location->{geometry}->{location}}{qw(lat lng)};
    within $lat, $lng, 45.8, 45.9, 15.9, 16.0;
}

{
    my $postal_code = 'E1A 7G1';
    my $location = safe_geocode { $geocoder->geocode(location => "$postal_code, Canada") };
    my $postal_code_component;
    for my $address_component (@{ $location->{address_components} }) {
	if (grep { $_ eq 'postal_code' } @{ $address_component->{types} }) {
	    $postal_code_component = $address_component;
	    last;
	}
    }
    is $postal_code_component->{long_name}, $postal_code;
}

{ # region
    my $geocoder_es = Geo::Coder::Googlev3->new(gl => 'es', language => 'de');
    is $geocoder_es->language, 'de', 'language accessor';
    is $geocoder_es->region, 'es', 'region accessor';
    my $location_es = safe_geocode { $geocoder_es->geocode(location => 'Toledo') };
    within $location_es->{geometry}->{location}->{lat}, $location_es->{geometry}->{location}->{lng},
	39.852434, 39.881947, -4.04314, -4.012585;
    my $geocoder_us = Geo::Coder::Googlev3->new();
    my $location_us = safe_geocode { $geocoder_us->geocode(location => 'Toledo') };
    within $location_us->{geometry}->{location}->{lat}, $location_us->{geometry}->{location}->{lng},
	41.663938, 41.663939, -83.55522, -83.55521;
}

{ # bounds
    my $location_chicago = safe_geocode { $geocoder->geocode(location => 'Winnetka') };
    within $location_chicago->{geometry}->{location}->{lat}, $location_chicago->{geometry}->{location}->{lng},
	42.1080830, 42.1080840, -87.735900, -87.735890;

    my $bounds = [{lat=>34.172684,lng=>-118.604794},{lat=>34.236144,lng=>-118.500938}];
    my $geocoder_la = Geo::Coder::Googlev3->new(bounds => $bounds);
    is_deeply $geocoder_la->bounds, $bounds, 'bounds accessor';
    my $location_la = safe_geocode { $geocoder_la->geocode(location => 'Winnetka') };
    within $location_la->{geometry}->{location}->{lat}, $location_la->{geometry}->{location}->{lng},
	34.172684, 34.236144, -118.604794, -118.500938;
}

{ # invalid bounds
    eval { $geocoder->bounds('scalar') };
    like $@, qr{array reference}, 'bounds is not an array';
    eval { $geocoder->bounds([]) };
    like $@, qr{two array elements}, 'bounds has not enough elements';
    eval { $geocoder->bounds([1,2]) };
    like $@, qr{lat/lng hashes}, 'bound elements are not hashes';
    eval { $geocoder->bounds([{lng=>1},{lat=>2}]) };
    like $@, qr{lat/lng hashes}, 'bound elements are missing keys';
    is $geocoder->bounds, undef, 'bounds is still unchanged';
}

{ # zero results
    my @locations = safe_geocode { $geocoder->geocode(location => 'This query should not find anything but return ZERO_RESULTS, Foobartown') };
    cmp_ok scalar(@locations), "==", 0, "No result found";

    my $location = safe_geocode { $geocoder->geocode(location => 'This query should not find anything but return ZERO_RESULTS, Foobartown') };
    is $location, undef, "No result found";
}

{ # raw
    my $raw_result = $geocoder->geocode(location => 'Brandenburger Tor, Berlin, Germany', raw => 1);
    # This is the 11th query here, so it's very likely that the API
    # limits are hit.
    like $raw_result->{status}, qr{^(OK|OVER_QUERY_LIMIT)$}, 'raw query';
    if ($raw_result->{status} eq 'OVER_QUERY_LIMIT') {
	diag 'over query limit hit, sleep a little bit';
	sleep 1; # in case a smoker tries this module with another perl...
    }
}

{ # sensor
    {
	my $geocoder = Geo::Coder::Googlev3->new(sensor => "false");
	ok $geocoder;
	is $geocoder->sensor, 'false';
	my $url = $geocoder->geocode_url(location => 'Hauptstr., Berlin');
	like $url, qr{sensor=false}, 'sensor=false detected in URL';

	my $geocoder_default = Geo::Coder::Googlev3->new();
	ok $geocoder_default;
	is $geocoder_default->sensor, 'false', 'Default is false';
	my $url_default = $geocoder_default->geocode_url(location => 'Hauptstr., Berlin');
	like $url_default, qr{sensor=false}, 'sensor=false detected in URL without explicit sensor setting';
    }

    {
	my $geocoder = Geo::Coder::Googlev3->new(sensor => "true");
	ok $geocoder;
	is $geocoder->sensor, 'true';
	my $url = $geocoder->geocode_url(location => 'Hauptstr., Berlin');
	like $url, qr{sensor=true}, 'sensor=false detected in URL';
    }

    eval {
	Geo::Coder::Googlev3->new(sensor => "nonsense");
    };
    like $@, qr{sensor argument has to be either 'false' or 'true'}, 'expected error message for unsupported sensor argument';
}

}

sub within ($$$$$$) {
    my($lat,$lng,$lat_min,$lat_max,$lng_min,$lng_max) = @_;
    cmp_ok $lat, ">=", $lat_min;
    cmp_ok $lat, "<=", $lat_max;
    cmp_ok $lng, ">=", $lng_min;
    cmp_ok $lng, "<=", $lng_max;
}

sub safe_geocode (&) {
    my($code0) = @_;
    my @locations;
    my $code;
    if (wantarray) {
	$code = sub { @locations = eval { &$code0 } };
    } else {
	$code = sub { $locations[0] = eval { &$code0 } };
    }

    $code->();
    if ($@ =~ m{OVER_QUERY_LIMIT}) {
	diag $@;
	diag "Hit OVER_QUERY_LIMIT, sleep some seconds before retrying...";
	sleep 3;
	$code->();
	if ($@ =~ m{OVER_QUERY_LIMIT}) {
	    diag $@;
	    diag "Hit OVER_QUERY_LIMIT, skipping remaining tests...";
	    no warnings 'exiting';
	    last SKIP;
	}
    } elsif ($@ =~ m{Fetching.*failed: 500}) {
	diag $@;
	diag "Fetch failed, probably network connection problems, skipping remaining tests";
	no warnings 'exiting';
	last SKIP;
    }

    if (wantarray) {
	@locations;
    } else {
	$locations[0];
    }
}

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
# vim:ft=perl:et:sw=4
