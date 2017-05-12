#!perl -T

use strict;
use warnings;

use Test::More;
BEGIN {
    $ENV{AUTHOR_TESTING}
        or plan skip_all => 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
    plan tests => 3;
}
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok 'Locale::Utils::PlaceholderBabelFish';
}

throws_ok
    sub {
        Locale::Utils::PlaceholderBabelFish->new(xxx => 1);
    },
    qr{unknown \s+ attribute .+? xxx}xms,
    'false attribute';
