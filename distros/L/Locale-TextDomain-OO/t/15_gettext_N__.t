#!perl -T

use strict;
use warnings;

use Test::More tests => 11;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    require_ok('Locale::TextDomain::OO');
}

my $loc = Locale::TextDomain::OO->new(
    plugins => [ qw( Expand::Gettext ) ],
);
is
    $loc->N__('This is a text.'),
    'This is a text.',
    'N__ scalar context';
eq_or_diff
    [
        $loc->N__(
            'This is a text.',
        ),
    ],
    [ 
        'This is a text.',
    ],
    'N__ list context';
eq_or_diff
    [
        $loc->N__x(
            '{name} is programming {language}.',
            name     => 'Steffen',
            language => 'Perl',
        ),
    ],
    [
        '{name} is programming {language}.',
        name     => 'Steffen',
        language => 'Perl',
    ],
    'N__x';
eq_or_diff
    [
        $loc->N__n(
            'Singular',
            'Plural',
            1,
        ),
    ],
    [ qw( Singular Plural 1 ) ],
    'N__n';
eq_or_diff
    [
        $loc->N__nx(
            '{num} shelf',
            '{num} shelves',
            1,
            num => 1,
        ),
    ],
    [
        '{num} shelf',
        '{num} shelves',
        1,
        num => 1,
    ],
    'N__nx';
eq_or_diff
    [
        $loc->N__p(
            'maskulin',
            'Dear',
        ),
    ],
    [ qw(maskulin Dear) ],
    'N__p';
eq_or_diff
    [
        $loc->N__px(
            'maskulin',
            'Dear {full name}',
            'full name' => 'Steffen Winkler',
        ),
    ],
    [
        'maskulin',
        'Dear {full name}',
        'full name' => 'Steffen Winkler',
    ],
    'N__px';
eq_or_diff
    [
        $loc->N__np(
            'appointment',
            'date',
            'dates',
            1,
        ),
    ],
    [ qw( appointment date dates 1 ) ],
    'N__np';
eq_or_diff
    [
        $loc->N__npx(
            'appointment',
            '{num} date',
            '{num} dates',
            1,
            num => 1,
        ),
    ],
    [
        'appointment',
        '{num} date',
        '{num} dates',
        1,
        num => 1,
    ],
    'N__npx';
