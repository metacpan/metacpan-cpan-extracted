#!perl -T

use strict;
use warnings;

use Test::More tests => 5 + 1;
use Test::NoWarnings;
use Test::Differences;
use Test::Exception;

BEGIN {
    use_ok('Locale::Utils::PluralForms');
}

my $obj = Locale::Utils::PluralForms->new(
    all_plural_forms => {
        dummy => {
            english_name => 'dummy',
            plural_forms => 'nplurals=1; plural=0',
        },
        de => {
            english_name => 'German',
            plural_forms => 'nplurals=2; plural=(n != 1)',
        },
    },
    language => 'dummy',
);

$obj->language('de');

eq_or_diff(
    $obj->plural_forms,
    'nplurals=2; plural=(n != 1)',
    'plural_forms de',
);

throws_ok(
    sub {
        $obj->language('en');
    },
    qr{\QMissing plural forms for language en in all_plural_forms\E}xms,
    'language en not exists',
);

$obj->plural_forms('nplurals=1; plural=0');

lives_ok(
    sub {
        $obj->language('de_AT');
    },
    'language de exists for de_AT',
);

eq_or_diff(
    $obj->plural_forms,
    'nplurals=2; plural=(n != 1)',
    'plural_forms de for de_AT',
);
