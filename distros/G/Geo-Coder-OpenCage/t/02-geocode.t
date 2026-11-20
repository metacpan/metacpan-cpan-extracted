use strict;
use warnings;
use utf8;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Test::More;

binmode Test::More->builder->output,         ":encoding(utf8)";
binmode Test::More->builder->failure_output, ":encoding(utf8)";
binmode Test::More->builder->todo_output,    ":encoding(utf8)";

use lib './lib';   # actually use the module, not other versions installed
use lib './t/lib'; # shared test helpers
use Geo::Coder::OpenCage;
use TestConnectivity;

plan skip_all => "Set GEO_CODER_OPENCAGE_API_KEY environment variable to run this test"
    unless $ENV{GEO_CODER_OPENCAGE_API_KEY};

plan skip_all => "no connectivity to api.opencagedata.com"
    unless TestConnectivity::have_connection();

my $api_key = $ENV{GEO_CODER_OPENCAGE_API_KEY};

my $geocoder = Geo::Coder::OpenCage->new(api_key => $api_key,);

# Just in case geocoder's results (city centers) change a bit over time.
my $max_distance_km = 5;

use constant PI => 4 * atan2(1, 1);

# great-circle distance in km (haversine)
sub _distance_km {
    my ($lat1, $lng1, $lat2, $lng2) = map { $_ * PI / 180 } @_;
    my $h = sin(($lat2 - $lat1) / 2)**2
          + cos($lat1) * cos($lat2) * sin(($lng2 - $lng1) / 2)**2;
    return 6371 * 2 * atan2(sqrt($h), sqrt(1 - $h));
}

my @tests = (
    # Basics
    {   input  => {location => "Mudgee, Australia",},
        output => [-32.598, 149.589],
    },
    {   input  => {location => "EC1M 5RF",},
        output => [51.523, -0.103],
    },

    # Encoding in request
    {   input  => {location => "Münster",},
        output => [51.963, 7.625],
    },

    # Encoding in response
    {   input  => {location => "Donostia",},
        output => [43.322, -1.984],
    },

    # language
    {   input => {
            location => "東京都",
            language => "ja",
        },
        output => [35.690, 139.692],
    },

    # country
    {   input => {
            location    => "Madrid",
            countrycode => "es",
        },
        output => [40.417, -3.704],
    },
);

for my $test (@tests) {
    my $location = $test->{input}{location};
    ok $location, "Trying to geocode '$location'";

    my $result = $geocoder->geocode(%{$test->{input}});

    ok $result, '... got a sane response';

    my @results     = @{$result->{results} || []};
    my $num_results = @results;

    ok @results > 0, "... got at least one ($num_results) results";

    my @distances    = map { _distance_km(@{$_->{geometry}}{qw(lat lng)}, @{$test->{output}}) } @results;
    my $good_results = grep { $_ <= $max_distance_km } @distances;
    ok $good_results, "... got at least one ($good_results) results within $max_distance_km km of where we expect them"
        or diag(map { sprintf "%.1f km away: %s\n", $distances[$_], $results[$_]{formatted} } 0 .. $#results);
}

done_testing();
