use strict;
use warnings;
use utf8;

use Test::More;

binmode Test::More->builder->output,         ":encoding(utf8)";
binmode Test::More->builder->failure_output, ":encoding(utf8)";
binmode Test::More->builder->todo_output,    ":encoding(utf8)";

use Geo::Coder::OpenCage;

my $api_key;
if ($ENV{GEO_CODER_OPENCAGE_API_KEY}) {
    $api_key = $ENV{GEO_CODER_OPENCAGE_API_KEY};
}
else {
    plan skip_all => "Set GEO_CODER_OPENCAGE_API_KEY environment variable to run this test";
}

my $Geocoder = Geo::Coder::OpenCage->new(
    api_key => $api_key,
);

my @tests = (
    # Basics
    {
        input => {
            lat => -32.5980702,
            lng => 149.5886383
        },
        output => "Mudgee",
    },

    # Encoding
    {
        input => {
            lat => 51.9625101,
            lng => 7.6251879,
        },
        output => "Münster",
    },

    # language
    {
        input => {
            lat => 35.6823815,
            lng => 139.7530053,
            language => "jp",
        },
        output => "東京都",
    },
);

for my $test (@tests) {
    my $location = join(", ", $test->{input}{lat}, $test->{input}{lng});
    ok $location, "Trying to geocode '$location'";

    my $result = $Geocoder->reverse_geocode(%{ $test->{input} });

    ok $result, '... got a sane response';

    my @results = @{ $result->{results} || [] };
    my $num_results = @results;

    ok @results > 0, "... got at least one ($num_results) results";

    my $good_results = 0;
    RESULT:
    for my $individual_result (@results) {
        COMPONENT:
        for my $component (values %{ $individual_result->{components} }) {
            if ($component =~ /^$test->{output}\b/) {
                $good_results++;
                last COMPONENT;
            }
        }
    }
    ok $good_results, "... got at least one ($good_results) results with the name we expect ($test->{output})"
}

done_testing();
