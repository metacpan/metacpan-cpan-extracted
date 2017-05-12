use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Geo::Raster' );
}

sub diff {
    my ($a1,$a2) = @_;
    return 0 unless defined $a1 and defined $a2;
    my $test = abs($a1 - $a2);
    $test /= $a1 unless $a1 == 0;
    abs($test) < 0.01;
}

# tests here for terrain analysis & hydrological functions
# not tested: route, killoutlets, prune, number_streams, subcatchments

{
    $dem = Geo::Raster->new(filename=>'data/dem.bil', load=>1);
    @fit = $dem->fit_surface;
    ok(@fit == 9, "fit_surface");
    $aspect = $dem->aspect;
    ok($aspect, "aspect");
    $slope = $dem->slope;
    ok($slope, "slope");
    for $method (qw/D8 Rho8 many/) {
	for $drain_all (0,1) {
	    $fdg = $dem->fdg(method=>$method, drain_all=>$drain_all, quiet=>1);
	    ok($fdg, "fdg $method drain_all is $drain_all");
	}
    }
    for $method (qw/one multiple/) {
	$fdg = $dem->fdg;
	$fdg->drain_flat_areas($dem, method=>$method, quiet=>1);
	ok($fdg, "drain_flat_areas $method");
    }
    $fdg = $dem->fdg;
    $fdg->drain_depressions($dem);
    ok($fdg, "drain_depressions");
    $fdg = $dem->fdg;
    @o = $fdg->outlet($fdg, 10,10);
    ok(@o == 2, "outlet");
    $fdg = $dem->fdg;
    $ucg = $fdg->ucg;
    ok($ucg, "ucg");
    $dem2 = $dem+0;
    $fdg = $dem2->fill_depressions(iterative=>1, quiet=>1);
    ok($fdg, "fill_depressions");
    $dem2 = $dem+0;
    $fdg = $dem2->breach(iterative=>1, quiet=>1);
    ok($fdg, "breach_depressions");
    
    $fdg = Geo::Raster->new(4,1);
    $fdg->set(5);
    $op = Geo::Raster->new(4,1);
    $op->nodata_value(-1);
    $op->set();
    for $i (0..3) {
	next if $i == 1;
	$op->set($i,0,$i);
    }

    $c = $fdg->path(1,0);
    my @test = (undef,1,1,1);
    for $i (0..3) {
	if (defined $test[$i]) {
	    ok($test[$i] == $c->get($i,0),"path at index $i");
	} else {
	    ok(!(defined $c->get($i,0)),"path at index $i");
	}
    }
    $c = $fdg->path_length(undef, $op);
    @test = (2.5,2,1.5,0.5);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"path at index $i");
    }
    $c = $fdg->path_sum(undef, $op);
    @test = (5,5,4,1.5);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"path at index $i");
    }
	
    $c = $fdg->upslope_count(0);
    @test = (0,1,2,3);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope count at index $i");
    }
    $c = $fdg->upslope_count(0,$op);
    @test = (0,1,1,2);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope count with op at index $i");
    }
    $c = $fdg->upslope_count(1);
    @test = (1,2,3,4);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope count including self at index $i");
    }
    $c = $fdg->upslope_count(1,$op);
    @test = (1,1,2,3);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope count including self with op at index $i");
    }
    $c = $fdg->upslope_sum($op,0);
    @test = (0,0,0,2);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope sum at index $i ".$c->get($i,0));
    }
    $c = $fdg->upslope_sum($op,1);
    @test = (0,0,2,5);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope sum including self at index $i ".$c->get($i,0));
    }

    $fdg->set(1);
    $c = $fdg->upslope_count(0);
    @test = (3,2,1,0);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope count at index $i");
    }
    $c = $fdg->upslope_count(0,$op);
    @test = (2,2,1,0);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope count with op at index $i");
    }
    $c = $fdg->upslope_count(1);
    @test = (4,3,2,1);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope count including self at index $i");
    }
    $c = $fdg->upslope_count(1,$op);
    @test = (3,2,2,1);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope count including self with op at index $i");
    }
    $c = $fdg->upslope_sum($op,0);
    @test = (5,5,3,0);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope sum at index $i");
    }
    $c = $fdg->upslope_sum($op);
    @test = (5,5,5,3);
    for $i (0..3) {
	ok($test[$i] == $c->get($i,0),"upslope sum including self at index $i");
    }
}
