use strict;
use Test::Base;
plan tests => 18 * blocks;

use Geo::JapanMesh qw(:japanmesh);

run {
    my $block = shift;
    my ($code)             = split(/\n/,$block->input);
    my @lls                = split(/\n/,$block->expected);
    my @code               = $code =~ /(((\d{4})\-\d{2})\-\d{2})/;
    @code                  = reverse( @code ); 

    for (my $i = 0; $i < 3; $i++ ) {
        my ( $tmny, $tmnx, $tmxy, $tmxx ) = split( /,/, $lls[$i] );
        my ( $tcy,  $tcx  ) = map { sprintf( "%.6f", $_ ) } ( ( $tmny + $tmxy ) / 2, ( $tmnx + $tmxx ) / 2 );

        my ( $mny, $mnx, $mxy, $mxx, $cy, $cx ) = map { sprintf( "%.6f", $_ ) } japanmesh2rect( $code[$i] );

        ok abs( $mny - $tmny ) <= 0.000001, "miny: $mny $tmny";
        ok abs( $mnx - $tmnx ) <= 0.000001, "minx: $mnx $tmnx";
        ok abs( $mxy - $tmxy ) <= 0.000001, "maxy: $mxy $tmxy";
        ok abs( $mxx - $tmxx ) <= 0.000001, "maxx: $mxx $tmxx";
        ok abs( $cy  - $tcy  ) <= 0.000001, "ceny: $cy  $tcy";
        ok abs( $cx  - $tcx  ) <= 0.000001, "cenx: $cx  $tcx";
    }

};

__END__
===
--- input
5438-23-34
--- expected
36.000000,138.000000,36.666667,139.000000
36.166667,138.375000,36.250000,138.500000
36.191667,138.425000,36.200000,138.437500

