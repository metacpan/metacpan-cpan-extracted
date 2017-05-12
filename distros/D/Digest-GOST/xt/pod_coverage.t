use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.00; 1" or do {
    plan skip_all => 'Test::Pod::Coverage 1.00 is not installed.';
};

pod_coverage_ok(
    'Digest::GOST' => {
        trustme => [qw( add clone digest new reset )],
    },
);

done_testing;
