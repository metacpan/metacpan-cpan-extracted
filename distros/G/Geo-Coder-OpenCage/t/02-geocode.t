use strict;
use warnings;
use utf8;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Test::More;

binmode Test::More->builder->output,         ":encoding(utf8)";
binmode Test::More->builder->failure_output, ":encoding(utf8)";
binmode Test::More->builder->todo_output,    ":encoding(utf8)";

use lib './lib';  # actually use the module, not other versions installed
use Geo::Coder::OpenCage;

my $api_key;
if ($ENV{GEO_CODER_OPENCAGE_API_KEY}) {
    $api_key = $ENV{GEO_CODER_OPENCAGE_API_KEY};
}
else {
    plan skip_all => "Set GEO_CODER_OPENCAGE_API_KEY environment variable to run this test";
}

my $geocoder = Geo::Coder::OpenCage->new(
    api_key => $api_key,
);

my @tests = (
    # Basics
    {
        input => {
            location => "Mudgee, Australia",
        },
        output => [ -32.5980702, 149.5886383 ],
    },
    {
        input => {
            location => "EC1M 5RF",
        },
        output => [ 51.5201666,  -0.0985142 ],
    },

    # Encoding in request
    {
        input => {
            location => "Münster",
        },
        output => [ 51.9625101,   7.6251879 ],
    },

    # Encoding in response
    {
        input => {
            location => "Donostia",
        },
        output => [ 43.300836,  -1.9809529 ],
    },

    # language
    {
        input => {
            location => "東京都",
            language => "jp",
        },
        output => [ 35.68, 139.76 ],
    },

    # country
    {
        input => {
            location => "Madrid",
            countrycode => "es",
        },
        output => [ 40.383333, -3.716667 ],
    },
);

for my $test (@tests) {
    my $location = $test->{input}{location};
    ok $location, "Trying to geocode '$location'";

    my $result = $geocoder->geocode(%{ $test->{input} });

    ok $result, '... got a sane response';

    my @results = @{ $result->{results} || [] };
    my $num_results = @results;

    ok @results > 0, "... got at least one ($num_results) results";

    my $good_results = 0;
    for my $individual_result (@results) {
        $good_results++ if (
            (abs($individual_result->{geometry}{lat} - $test->{output}[0]) < 0.05) &&
            (abs($individual_result->{geometry}{lng} - $test->{output}[1]) < 0.05)
        );
    }
    ok $good_results, "... got at least one ($good_results) results where we expect them to be";
}

done_testing();
