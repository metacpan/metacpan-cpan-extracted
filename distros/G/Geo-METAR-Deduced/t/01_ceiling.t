use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

my @metars = (
    [
        'KFDY 251450Z 21012G21KT 8SM VV065 04/M01 A3010 RMK 57014',
        '6500',
        'Vertical visibility of 6500 feet makes ceiling 6500 feet in US',
    ],
    [
        'KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014',
        '6500',
        'Overcast at 6500 feet makes ceiling 6500 feet',
    ],
    [
        'EHAM 251450Z 21012G21KT 8SM OVC200 04/M01 A3010 RMK 57014',
        'inf',
        'Overcast at 20000ft makes ceiling unlimited under ICAO rules',
    ],
    [
        'EHAM 251450Z 21012G21KT 8SM OVC199 04/M01 A3010 RMK 57014',
        '19900',
        'Overcast at 19900ft makes ceiling 19900ft under ICAO rules',
    ],
    [
        'EGFF 251450Z 21012G21KT 8SM OVC200 04/M01 A3010 RMK 57014',
        '20000',
        'Overcast at 20000ft makes ceiling 20000ft in UK',
    ],
    [
        'KFDY 251450Z 21012G21KT 8SM OVC200 04/M01 A3010 RMK 57014',
        '20000',
        'Overcast at 20000ft makes ceiling 20000ft in US',
    ],
    [
        'EHAM 261625Z 13006KT 090V170 CAVOK 29/15 Q1008 NOSIG',
        'inf',
        'CAVOK makes ceiling unlimited in ICAO',
    ],
);

plan tests => ( 0 + @metars ) + 1;

require Geo::METAR::Deduced;
my $m = Geo::METAR::Deduced->new();
foreach my $metar (@metars) {
    $m->metar( @{$metar}[0] );
    is( $m->ceiling()->ft(), @{$metar}[1], @{$metar}[2] );
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
