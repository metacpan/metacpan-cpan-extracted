use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Geo::Raster' );
}

sub diff {
    my ($a1,$a2) = @_;
    #print "$a1 == $a2?\n";
    return 0 unless defined $a1 and defined $a2;
    my $test = abs($a1 - $a2);
    $test /= $a1 unless $a1 == 0;
    abs($test) < 0.01;
}

# cross, binary, bufferzone tests here

{
    for my $datatype ('int','real') {
	my $gd = new Geo::Raster($datatype,5,10);
	$gd->set(5);
	$gd->set(1,1,0);
	$gd->set(2);
	my %ret = (count=>50,sum=>100,mean=>2,variance=>0);
	for ('count','sum','mean','variance') {
	    my $ret; 
	    $eval = "\$ret = \$gd->$_";
	    eval $eval;
#	    print "$_ = $ret\n";
	    ok(diff($ret{$_},$ret),$_);
	}
    }
}

{
    for my $datatype ('int','real') {
	my $gd = new Geo::Raster($datatype,5,10);
	$gd->set(5);
	my $mask = new Geo::Raster(5,10);
	$mask->circle(3,5,2,1);
	$gd->mask($mask);
	my %ret = (count=>9,sum=>45,mean=>5,variance=>0);
	for ('count','sum','mean','variance') {
	    my $ret; 
	    $eval = "\$ret = \$gd->$_";
	    eval $eval;
#	    print "$_ = $ret\n";
	    ok(diff($ret{$_},$ret),"masked $_");
	}
	$gd->mask();
    }
}

{
    for my $datatype ('int','real') {
	my $gd = new Geo::Raster($datatype,5,10);
	$gd->set(2);
	$gd->circle(3,5,2,3);
#	$gd->print;
	my @bin = (2);
	my @histogram = $gd->histogram(\@bin);
#	print "@histogram\n";
	ok($histogram[0]==41,"histogram");
	ok($histogram[1]==9,"histogram");
    }
}

# test here 

# distances directions 
# clip join transform frame

{
    for my $datatype ('int','real') {
	my %ans = (int=>{0=>1,mean=>1, variance=>0, min=>1, max=>1, count=>100},
		   real=>{0=>1,mean=>1, variance=>0, min=>1, max=>1, count=>'nodata'});
	for my $pick (0,'mean', "variance", "min", "max", "count") {
	    my $gd = new Geo::Raster($datatype,100,100);
	    $gd->set(1);
	    my @tr = (0, 10, 0, 0, 0, 10);
	    $gd->transform(\@tr,10,10,$pick,1);
	    my $ret = $gd->cell(0,0);
	    $ret = 'nodata' if !defined($ret);
	    if ($datatype eq 'real' and $pick eq 'count') {
		ok($ret eq $ans{$datatype}{$pick},"transform (real, count)");
	    } else {
		ok(diff($ans{$datatype}{$pick},$ret),"transform");
	    }
	}
    }
}

{
    for my $dt1 ('int','real') {
	my $g1 = new Geo::Raster($dt1,10,10);
	$g1->set(1);
	for my $dt2 ('int','real') {
	    my $g2 = new Geo::Raster($dt2,2,2);
	    $g1->clip_to($g2);
	    ok(diff($g1->cell(1,0), 1),"clip_to");
	    my $g3 = $g1->clip_to($g2);
	    ok(diff($g3->cell(1,0), 1),"clip_to w ret");
	}
    }
}

{
    my $gd = new Geo::Raster('real',10,10);
    $gd->function('int(10*rand())');
    my $c = $gd->contents;
    my %c;
    for my $i (0..9) {
	for my $j (0..9) {
	    $c{$gd->cell($i,$j)}++;
	}
    }
    for (keys %c) {
	ok(diff($c{$_},$c->{$_}),"contents real");
    }
    $gd = new Geo::Raster(10,10);
    $gd->function('round(10*rand())');
    $c = $gd->contents;
    print "$c\n";
    %c = ();
    for my $i (0..9) {
	for my $j (0..9) {
	    $c{$gd->cell($i,$j)}++;
	}
    }
    for (keys %c) {
	ok(diff($c{$_},$c->{$_}),"contents integer");
    }
}

