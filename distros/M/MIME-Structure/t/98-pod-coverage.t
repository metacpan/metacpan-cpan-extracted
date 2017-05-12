use strict;
use warnings;

use Test::More;

$| = 1;

eval "use Test::Pod::Coverage 1.00";

plan 'skip_all' => "Test::Pod::Coverage 1.00 required for testing POD coverage"
    if $@;
plan 'tests' => 1;

pod_coverage_ok(
    'MIME::Structure', {
        'also_private' => [ qr/^(init|fields2hash|parse_content_type|parse_params|parse_header|test)$/ ],
    },
);

