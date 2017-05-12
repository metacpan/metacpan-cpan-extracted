use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More;

BEGIN {
    eval "use Geo::Gpx";
    plan skip_all => 'Geo::Gpx not available' if $@;

    plan 'no_plan';
}

use IO::File;

use_ok( 'Geo::Google::PolylineEncoder' );

# Test 3
# A basic encoded polyline with ~100 points

my $filename = 't/data/20061228.gpx';
my $fh = IO::File->new( $filename );
my $gpx = Geo::Gpx->new( input => $fh );

my @points;
my $iter = $gpx->iterate_trackpoints;
while (my $pt = $iter->()) {
    push @points, {lat => $pt->{lat}, lon => $pt->{lon}};
}

{
    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
    my $eline   = $encoder->encode( \@points );
    is( $eline->{num_levels}, 18, 'ex3 num_levels' );
    is( $eline->{zoom_factor}, 2, 'ex3 zoom_factor' );
    is( $eline->{points}, '{w}yHtP`NbEDzAEADf@HNh@N^\\TrAB`GA|DlF[pJaBhBa@RG|AOvD{AhFkCRE`Da@hFU`@Ub@Mj@JVfCj@fE\\zCI@PbALb@f@|@d@^XLj@HlDmAjGQRv@?JJrBpAvHbAjAdBjCrBfFTfFxA|SlA|J@^AST~@l@KxEcBb@WCAFST[`@Y`@GJj@SP_@LSv@?j@FnA@_@Hd@JV', 'small gpx: points' );
    is( $eline->{levels}, 'PF@?C@@BD?GBA?ADA?CAB@BH??AB?AF@ADCFA?AD@BE@B?FBBCBA?@BAFB@BC?BB?P', 'small gpx: levels' );

    my $d_points = $encoder->decode_points( $eline->{points} );
    my $d_levels = $encoder->decode_levels( $eline->{levels} );
    is( scalar @$d_points, scalar @$d_levels, 'decode: num levels == num points' );
}

{
    # Test 2 - compare _all_ points to output from Google IPEU & original points
    my $ipeu    = '{w}yHtP`NbEDzAEADf@HNHD^H^\\TrAB`GA|DlF[vEw@xCi@vA[PERGl@Gn@IvDyAhFkCPEbDa@jDQ|@CPKNIb@Mj@JVdCh@hE^zCI@PbALb@f@|@d@^XLj@HlDmAjGQRv@?JJrBpAvHbAjAdBjCrBfFTfFxA|S^xCj@~E@B?@@\\@ACQH\\J`@l@KxAg@~B{@b@WCAFSR[b@Y`@GJj@SP_@LSv@?j@FnABSAKHd@HV';
    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18, visible_threshold => 0.00000001 );
    my $eline   = $encoder->encode( \@points );

    my $ipeu_points = $encoder->decode_points( $ipeu );
    my $d_points = $encoder->decode_points( $eline->{points} );
    my $d_levels = $encoder->decode_levels( $eline->{levels} );
    is( scalar @$d_points, scalar @$d_levels, 'decode all: num levels == num points' );
    is( scalar @$d_points, scalar @points, 'decode all: num points == orig num' );
    is( scalar @$d_points, scalar @$ipeu_points, 'decode all: num points == num ipeu points' );

  SKIP: {
	eval "use Test::Approx";
	skip 'Test::Approx not available', scalar( @points ) * 4 if $@;

	# compare the decoded, original & ipeu points, should be only rounding diffs
	for my $i (0 .. $#points) {
	    my ($Pa, $Pb, $Pc) = ($d_points->[$i], $points[$i], $ipeu_points->[$i]);
	    is_approx_num( $Pa->{lon}, $Pb->{lon}, "d.lon[$i] =~ orig.lon[$i]", 1e-5 );
	    is_approx_num( $Pa->{lat}, $Pb->{lat}, "d.lat[$i] =~ orig.lat[$i]", 1e-5 );
	    is_approx_num( $Pa->{lon}, $Pc->{lon}, "d.lon[$i] =~ ipeu.lon[$i]", 1.2e-5 );
	    is_approx_num( $Pa->{lat}, $Pc->{lat}, "d.lat[$i] =~ ipeu.lat[$i]", 1.2e-5 );
	}
    }
}

