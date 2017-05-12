#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 19;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('Locale::TextDomain::OO');
    require_ok('Locale::TextDomain::OO::Lexicon::File::MO');
}

Locale::TextDomain::OO::Lexicon::File::MO
    ->new(
        logger => sub { note shift },
    )
    ->lexicon_ref({
        search_dirs => [ './t/LocaleData' ],
        decode      => 1,
        data        => [
            '*:LC_MESSAGES:test_maketext' => '*/LC_MESSAGES/test_maketext.mo',
        ],
    });

my $loc = Locale::TextDomain::OO->new(
    language => 'de',
    category => 'LC_MESSAGES',
    domain   => 'test_maketext',
    plugins  => [ qw( Expand::Maketext ) ],
    logger   => sub { note shift },
);
is
    $loc->maketext(
        'This is a text.',
    ),
    'Das ist ein Text.',
    'maketext';
is
    $loc->maketext(
        '§ book',
    ),
    '§ Buch',
    'maketext, umlaut';
is
    $loc->maketext(
        '[_1] is programming [_2].',
        'Steffen',
        'Perl',
    ),
    'Steffen programmiert Perl.',
    'maketext, placeholder';
is
    $loc->maketext(
        '[_1] is programming [_2].',
        'Steffen',
    ),
    'Steffen programmiert .',
    'maketext, missing placeholder';
is
    $loc->maketext(
        '[quant,_1,shelf,shelves]',
        1,
    ),
    '1 Regal',
    'maketext, quant 1';
is
    $loc->maketext(
        '[quant,_1,shelf,shelves]',
        2,
    ),
    '2 Regale',
    'maketext, quant 2';
is
    $loc->maketext_p(
        'maskulin',
        'Dear',
    ),
    'Sehr geehrter',
    'maketext_p';
is
    $loc->maketext_p(
        'maskulin',
        'Dear [_1]',
        'Steffen Winkler',
    ),
    'Sehr geehrter Steffen Winkler',
    'maketext_p, placeholder';
is
    $loc->maketext_p(
        'appointment',
        'This is/are [*,_1,date,dates].',
        1,
    ),
    'Das ist/sind 1 Date.',
    'maketext_p, * 1';
is
    $loc->maketext_p(
        'appointment',
        'This is/are [*,_1,date,dates].',
        2,
    ),
    'Das ist/sind 2 Dates.',
    'maketext_p, * 2';
is
    $loc->maketext(
        '[*,_1,shelf,shelves,no shelf]',
        0,
    ),
    'kein Regal',
    'maketext, * 0';
is
    $loc->maketext(
        '[*,_1,shelf,shelves,no shelf]',
        1,
    ),
    '1 Regal',
    'maketext, * 1';
is
    $loc->maketext(
        '[*,_1,shelf,shelves,no shelf]',
        2,
    ),
    '2 Regale',
    'maketext, * 2';
is
    $loc->Nmaketext(
        'book',
    ),
    'book',
    'Nmaketext';
eq_or_diff
    [
        $loc->Nmaketext_p(
            'appointment',
            'date',
        ),
    ],
    [
        'appointment',
        'date',
    ],
    'Nmaketext_p';
eq_or_diff
    [
        $loc->Nmaketext_p(
            'not existing context',
            'book',
        ),
    ],
    [
        'not existing context',
        'book',
    ],
    'Nmaketext_p (not in lexicon)';
