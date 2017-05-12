use UNIVERSAL;
use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Geo::Raster' );
}

#use PDL::NetCDF;

#my $ncobj = PDL::NetCDF->new ('t2m.SMHI.HCA2.nc');
#my $slice = $ncobj->get('t2m', [100, 0, 0, 0], [1, 1, 86, 90]);
#my $a = Geo::Raster->new($slice);

sub diff {
    my ($a1,$a2) = @_;
    #print "$a1 == $a2?\n";
    return 0 unless defined $a1 and defined $a2;
    my $test = abs($a1 - $a2);
    $test /= $a1 unless $a1 == 0;
    abs($test) < 0.01;
}

{
    my $gd = Geo::Raster->new('real',5,10);
    ok(defined($gd), "simple new");
    for ('data/dem.bil') {
	$gd = Geo::Raster->new($_);
	ok(defined($gd),"open");
    }
    $gd = Geo::Raster->new('real',5,10);
    my $gd2 = Geo::Raster::new($gd);
    ok(UNIVERSAL::isa($gd2, 'Geo::Raster'));
}

{
    my $gd = new Geo::Raster(datatype=>'integer',M=>5,N=>10,world=>{minx=>5,miny=>5,maxy=>10});
    my @world = $gd->world();
    ok($world[2]==15,"new with world");
}

{
    my $gd = Geo::Raster->new(5,10);
    eval {
	$gd->nodata_value(999999999);
    };
    ok($@ =~ /out of bounds/,'set too large int as nodata to int grid is an error');
    eval {
	$gd->set(-1,-1,0);
    };
    ok($@ =~ /not on grid/,'set outside is an error');
}

for my $datatype1 ('int','real') {
    my $gd1 = new Geo::Raster($datatype1,5,10);

    my $mem = $gd1->band;

    ok($mem->{XSize} == 10, "GDAL mem dataset and band");

    $gd1->set(5);
    ok(diff($gd1->cell(3,3),5),'set & get');
    for my $datatype2 (undef,'int','real') {
	my $gd2 = new Geo::Raster copy=>$gd1, datatype=>$datatype2;
	ok(diff($gd1->cell(3,3),$gd2->cell(3,3)),'copy');
    }
}

my %dm = (''=>'Integer',int=>'Integer',real=>'Real');
for my $datatype1 ('','int','real') {
    my $gd1 = new Geo::Raster($datatype1,5,10);
    my $dt1 = $gd1->data_type();	
    ok($dt1 eq $dm{$datatype1},"datatype: $dt1 eq $dm{$datatype1}");
    for my $datatype2 ('','int','real') {
	my $gd2 = new Geo::Raster like=>$gd1, datatype=>$datatype2;
	my $dt2 = $gd2->data_type();
	my $cmp = $dm{$datatype2};
	$cmp = $dm{$datatype1} if $datatype2 eq '';
	ok($dt2 eq $cmp,"new like: $datatype2->$dt2 eq $cmp");
    }
}

{
    for my $datatype ('int','real') {
	my $gd = new Geo::Raster($datatype,5,10);
	$gd->set(5);
	$gd->set(4,3,2);
	my($points) = $gd->array();
	$j = 0;
	for (@$points) {
	    $p[$j]="$_->[0],$_->[1] = $_->[2]";
	    $j++;
	}
	ok(($p[17] eq '1,7 = 5' and $p[43] eq '4,3 = 2'),"array");
    }
}

{
    for my $datatype ('int','real') {
	my $gd = new Geo::Raster($datatype,5,10);
	$gd->set(5);
	$a=new Geo::Raster(like=>$gd);
	@sgd = $gd->size();
	@sa = $a->size();
	for (0..1) {
	    ok(diff($sgd[0],$sa[0]),"new like");
	}
	$dump = 'dumptest';
	$gd->dump($dump);
	$a->restore($dump);
	ok(diff($gd->cell(3,3),$a->cell(3,3)),"dump and restore");
	$a = $gd == $a;
	my @nx = $a->value_range();
	ok(diff($nx[0],$nx[1]),"value_range");
	ok(diff($nx[1],1),"value_range");
	my $min = $a->min();
	my $max = $a->max();
	ok(diff($min,$nx[0]),"min from min()");
	ok(diff($max,$nx[1]),"max from max()");
    }
}

{
    my $test_grid = 'test_grid';
    for my $datatype ('int','real') {
	my $gd1 = new Geo::Raster($datatype,5,10);
	$gd1->set(5);
	$gd1->save($test_grid.'.bil');
	my $gd2 = new Geo::Raster filename=>$test_grid.'.bil', load=>1 ;
	ok(diff($gd1->cell(3,3),$gd2->cell(3,3)), 'save/open');
    }
    for ('.hdr','.bil') {unlink($test_grid.$_)};
    
    for my $datatype ('int','real') {
	my $gd = new Geo::Raster($datatype,5,10);
	$gd->set(1,1,1);
	$gd->dump($test_grid);
	$gd->restore($test_grid);
	unlink($test_grid);
	ok(diff($gd->cell(1,1),1),"dump and restore");
    }
}

{
    my $gd1 = new Geo::Raster('i',5,10);
    my %bm = (1 => cell_size,
	      2 => minX,
	      3 => minY,
	      4 => maxX,
	      5 => maxY);
    #valid bounds:
    my %bounds = (cell_size => 1.5,
		  minX => 3.5,
		  minY => 2.5,
		  maxX => 18.5,
		  maxY => 10);
    for my $b ([1,2,3],[1,2,5],[1,3,4],[2,3,4],[2,3,5],[3,4,5]) {
	my %o;
	for (0..2) {
	    my $bm = $bm{$b->[$_]};
	    $o{$bm} = ($bounds{$bm});
	}
	#for (keys %o) {
	#    print STDERR "bo: $_ $o{$_}\n";
	#}
	$gd1->world(%o);
	my @attrib = $gd1->_attributes();
	for (1..5) {
	    ok(diff($bounds{$bm{$_}},$attrib[2+$_]),"setting world");
	}
    }
    my $gd2 = new Geo::Raster(5,10);
    $gd1->copy_world_to($gd2);
    my @attrib1 = $gd1->_attributes();
    my @attrib2 = $gd2->_attributes();
    for (1..5) {
	ok(diff($attrib1[2+$_],$attrib2[2+$_]),"copy world to");
    }
}

{
    my $gd = new Geo::Raster(5,10);
    $gd->world(cell_size=>1.4,minX=>1.2,minY=>2.4);
    my @point = $gd->g2w(3,7);
    my @cell = $gd->w2g(@point);
    ok(($cell[0] == 3 and $cell[1] == 7),"world coordinates <-> grid coordinates");
    ok(not($gd->cell_in(-1,5) and $gd->cell_in(2,13) and 
	   $gd->cell_in(7,5) and $gd->cell_in(2,-1)) and $gd->cell_in(2,5), "cell in");
    ok(not($gd->point_in(10,0) and $gd->point_in(20,4) and 
	   $gd->point_in(10,12) and $gd->point_in(0,5)) and $gd->point_in(10,3), "point in");
    $gd->save('t/data/test.bil');
    $gd = Geo::Raster->new(filename=>'t/data/test.bil',load=>1);
    ok(($cell[0] == 3 and $cell[1] == 7),"world coordinates <-> grid coordinates");
    ok(not($gd->cell_in(-1,5) and $gd->cell_in(2,13) and 
	   $gd->cell_in(7,5) and $gd->cell_in(2,-1)) and $gd->cell_in(2,5), "cell in");
    ok(not($gd->point_in(10,0) and $gd->point_in(20,4) and 
	   $gd->point_in(10,12) and $gd->point_in(0,5)) and $gd->point_in(10,3), "point in");
}

{
    my $gd = new Geo::Raster(5,10);
    my $i = 1;
    my $j = 7;
    my $val = 5;
    $gd->set($i,$j,$val);
    my $check = $gd->cell($i,$j);
    ok((abs($val-$check)<0.01),"set and get");
    
    my ($min,$max) = $gd->value_range();
    ok((abs($min-0)<0.01 and abs($max-5)<0.01),"value range");
}

{
    my $gd = new Geo::Raster('real',10,10);
    $gd->nodata_value(-9999);
    $gd->lt(1);
    my $test = diff(-9999,$gd->nodata_value());
    ok($test, "nodata in lt");
}

{
    for my $datatype ('int','real') {
	my $g = new Geo::Raster($datatype,5,5);
	for $i (0..4) {
	    for $j (0..4) {
		$g->set($i,$j,$i+$j);
	    }
	}
	
	$g->map('*'=>12, [1,3]=>13, [5,7.1]=>56);
	
	ok($g->get(0,0) == 12, "default map $datatype");
	ok($g->get(0,1) == 13, "map $datatype 1");
	ok($g->get(1,4) == 56, "map $datatype 2");
	
    }  
}

{
    my $g1 = new Geo::Raster('int',5,5);
    my $g2 = new Geo::Raster('int',5,5);
    my $g3 = new Geo::Raster('int',1,5);
    my $t1 = $g1->overlayable($g2);
    my $t2 = $g1->overlayable($g3);
    ok($t1 == 1, "overlayability");
    ok($t2 == 0, "overlayability");
}
