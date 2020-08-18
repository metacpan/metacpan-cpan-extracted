use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

my @metars = (
    [
        'EGKK 260950Z AUTO 29011KT 9999 OVC003 16/16 Q1010',
        'UK', 'EGKK has UK rules',
    ],
    [
        'EGFF 260950Z AUTO 29011KT 9999 OVC003 16/16 Q1010',
        'UK', 'EGFF has UK rules',
    ],
    [
        'KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014',
        'US', 'KFDY has US rules',
    ],
    [
        'KFEG 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014',
        'US', 'KFEG has US rules',
    ],
    [
        'EHAM 260955Z 13009KT 060V170 CAVOK 27/15 Q1011 NOSIG',
        'ICAO', 'EHAM has ICAO rules',
    ],
    [
        'EHKK 260955Z 13009KT 060V170 CAVOK 27/15 Q1011 NOSIG',
        'ICAO', 'EHKK has ICAO rules',
    ],
    [
        'EHEG 260955Z 13009KT 060V170 CAVOK 27/15 Q1011 NOSIG',
        'ICAO', 'EHEG has ICAO rules',
    ],
);

plan tests => ( 0 + @metars ) + 1;

require Geo::METAR::Deduced;
my $m = Geo::METAR::Deduced->new();
foreach my $metar (@metars) {
    $m->metar( @{$metar}[0] );
    is( $m->rules(), @{$metar}[1], @{$metar}[2] );
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
