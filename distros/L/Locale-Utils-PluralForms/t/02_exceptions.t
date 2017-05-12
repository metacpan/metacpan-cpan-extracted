#!perl -T

use strict;
use warnings;

use Test::More tests => 2 + 1;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    use_ok('Locale::Utils::PluralForms');
}

throws_ok(
    sub {
        Locale::Utils::PluralForms->new(xxx => 1);
    },
    qr{unknown \s+ attribute .+? xxx}xms,
    'false attribute',
);
