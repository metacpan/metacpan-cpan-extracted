use strict;
use Test::Base;
plan tests => 6 * blocks;

SKIP:{
    eval "use Geo::Formatter qw(GeoPo)";
    skip "Geo::Formatter is not installed", 6 * blocks if($@);

    run {
        my $block = shift;
        my ($geopo)           = split(/\n/,$block->input);
        my ($lat,$lng,$scl)   = split(/\n/,$block->expected);

        my ( $tlat, $tlng, $tscl ) = format2latlng( 'geopo', $geopo );
        is sprintf("%.2f", $tlat), sprintf("%.2f", $lat );
        is sprintf("%.2f", $tlng), sprintf("%.2f", $lng );
        is $tscl, $scl;

        ( $tlat, $tlng, $tscl ) = format2latlng( 'geopo', "http://geopo.at/$geopo" );
        is sprintf("%.2f", $tlat), sprintf("%.2f", $lat );
        is sprintf("%.2f", $tlng), sprintf("%.2f", $lng );
        is $tscl, $scl;
    };
}

__END__
===
--- input
Z4RHXX
--- expected
35.658578
139.745447
6

===
--- input
C1qn6PM
--- expected
48.858271
2.294512
7

===
--- input
jr2QzI
--- expected
-13.1637
-72.545777
6

