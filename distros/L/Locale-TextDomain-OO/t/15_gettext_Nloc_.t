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
    plugins => [ qw( Expand::Gettext::Loc ) ],
);
is
    $loc->Nloc_('This is a text.'),
    'This is a text.',
    'Nloc_ scalar context';
eq_or_diff
    [
        $loc->Nloc_(
            'This is a text.',
        ),
    ],
    [ 
        'This is a text.',
    ],
    'Nloc_ list context';
eq_or_diff
    [
        $loc->Nloc_x(
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
    'Nloc_x';
eq_or_diff
    [
        $loc->Nloc_n(
            'Singular',
            'Plural',
            1,
        ),
    ],
    [ qw( Singular Plural 1 ) ],
    'Nloc_n';
eq_or_diff
    [
        $loc->Nloc_nx(
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
    'Nloc_nx';
eq_or_diff
    [
        $loc->Nloc_p(
            'maskulin',
            'Dear',
        ),
    ],
    [ qw(maskulin Dear) ],
    'Nloc_p';
eq_or_diff
    [
        $loc->Nloc_px(
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
    'Nloc_px';
eq_or_diff
    [
        $loc->Nloc_np(
            'appointment',
            'date',
            'dates',
            1,
        ),
    ],
    [ qw( appointment date dates 1 ) ],
    'Nloc_np';
eq_or_diff
    [
        $loc->Nloc_npx(
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
    'Nloc_npx';
