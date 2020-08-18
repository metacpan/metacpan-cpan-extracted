use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

my @metars = (
    [
        'KFDY 260950Z AUTO 29011KT 1/4SM OVC001 16/16 Q1010',
        0, '.25 statute mile visibility with 100ft ceiling is low IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 3/4SM OVC004 16/16 Q1010',
        0, '.75 statute mile visibility with 400ft ceiling is low IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 3/4SM OVC005 16/16 Q1010',
        0, '.75 statute mile visibility with 500ft ceiling is low IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 1SM OVC005 16/16 Q1010',
        1, '1 statute mile visibility with 500ft ceiling is IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 3SM OVC009 16/16 Q1010',
        1, '3 statute mile visibility with 900ft ceiling is IFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 3SM OVC010 16/16 Q1010',
        2, '3 statute mile visibility with 1000ft ceiling is MVFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 5SM OVC025 16/16 Q1010',
        2, '5 statute mile visibility with 2500ft ceiling is MVFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 5SM OVC030 16/16 Q1010',
        2, '5 statute mile visibility with 3000ft ceiling is MVFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 5 1/4SM OVC031 16/16 Q1010',
        3, '5.25 statute mile visibility with 3100ft ceiling is MVFR in US rules',
    ],
    [
        'KFDY 260950Z AUTO 29011KT 15SM OVC065 16/16 Q1010',
        3, '15 statute mile visibility with 6500ft ceiling is MVFR in US rules',
    ],
);

plan tests => ( 0 + @metars ) + 1;

require Geo::METAR::Deduced;
my $m = Geo::METAR::Deduced->new();
foreach my $metar (@metars) {
    $m->metar( @{$metar}[0] );
    is( $m->flight_rule(), @{$metar}[1], @{$metar}[2] );
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
