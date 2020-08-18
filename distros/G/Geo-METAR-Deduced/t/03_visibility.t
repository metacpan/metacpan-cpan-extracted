use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

my @metars = (
    [
        'KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014',
        8, 'Visibility of 8SM is 8',
    ],
    [
        'KFDY 251450Z 21012G21KT 3/4SM OVC065 04/M01 A3010 RMK 57014',
        .75, 'Visibility of 3/4SM is 0.75',
    ],
    [
        'KFDY 251450Z 21012G21KT 1 1/4SM OVC065 04/M01 A3010 RMK 57014',
        1.25, 'Visibility of 1 1/4SM is 1.25',
    ],
);

plan tests => ( 0 + @metars ) + 1;

require Geo::METAR::Deduced;
my $m = Geo::METAR::Deduced->new();
foreach my $metar (@metars) {
    $m->metar( @{$metar}[0] );
    is( $m->visibility()->mile(), @{$metar}[1], @{$metar}[2] );
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
