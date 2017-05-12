#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

BEGIN {
    require_ok('Locale::TextDomain::OO');
    require_ok('Locale::TextDomain::OO::Lexicon::File::MO');
}

Locale::TextDomain::OO::Lexicon::File::MO
    ->new
    ->lexicon_ref({
        search_dirs => [ './t/LocaleData' ],
        decode      => 1,
        data        => [
            '*::' => '*/LC_MESSAGES/test.mo',
        ],
    });

Locale::TextDomain::OO->instance(
    language => 'de',
    plugins  => [ qw( Expand::Gettext ) ],
);

is
    +Locale::TextDomain::OO->instance->__(
        'This is a text.',
    ),
    'Das ist ein Text.',
    '__';
