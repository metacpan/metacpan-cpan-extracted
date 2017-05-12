use strict;
use Test::Base;
plan tests => 2046 * blocks;

use Geo::JapanMesh qw(:iareamesh);

run {
    my $block = shift;
    my ($code)             = split(/\n/,$block->input);
    my ($lls)              = split(/\n/,$block->expected);

    my ( $tmny, $tmnx, $tmxy, $tmxx ) = split( /,/, $lls );

    lowmesh_test( $code, 2, $tmny, $tmnx, $tmxy, $tmxx );
};

sub lowmesh_test {
    my ( $code, $depth, $tmny, $tmnx, $tmxy, $tmxx ) = @_;
    my ( $tcy,  $tcx  ) = map { sprintf( "%.6f", $_ ) } ( ( $tmny + $tmxy ) / 2, ( $tmnx + $tmxx ) / 2 );
    
    my ( $mny, $mnx, $mxy, $mxx, $cy, $cx ) = map { sprintf( "%.6f", $_ ) } iareamesh2rect( $code );

    ok abs( $mny - $tmny ) <= 0.000001, "miny: $mny $tmny";
    ok abs( $mnx - $tmnx ) <= 0.000001, "minx: $mnx $tmnx";
    ok abs( $mxy - $tmxy ) <= 0.000001, "maxy: $mxy $tmxy";
    ok abs( $mxx - $tmxx ) <= 0.000001, "maxx: $mxx $tmxx";
    ok abs( $cy  - $tcy  ) <= 0.000001, "ceny: $cy  $tcy"; 
    ok abs( $cx  - $tcx  ) <= 0.000001, "cenx: $cx  $tcx";

    unless ( $depth >= 6 ) {
        lowmesh_test( $code.'0' , $depth + 1, $tmny, $tmnx, $tcy,  $tcx  );
        lowmesh_test( $code.'1' , $depth + 1, $tmny, $tcx,  $tcy,  $tmxx );
        lowmesh_test( $code.'2' , $depth + 1, $tcy,  $tmnx, $tmxy, $tcx  );
        lowmesh_test( $code.'3' , $depth + 1, $tcy,  $tcx,  $tmxy, $tmxx );
    }
}

__END__
===
--- input
543823
--- expected
36.166667,138.375000,36.250000,138.500000

