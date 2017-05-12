use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Geo::Raster' );
}

sub diff {
    my ($a1,$a2) = @_;
    #print STDERR "$a1 == $a2?\n";
    return 0 unless defined $a1 and defined $a2;
    my $test = abs($a1 - $a2);
    $test /= $a1 unless $a1 == 0;
    abs($test) < 0.01;
}

# line rect circle floodfill 

{
    for my $datatype ('int','real') {
	my $gd1 = new Geo::Raster($datatype,5,5);
	my $gd2 = new Geo::Raster($datatype,5,5);
	my $a;
	$gd2->set(1);
	$gd1->line(0,2,3,4,1);
	$a = $gd2->line(0,2,3,4);
	for (@$a) {
	    ok(diff($gd1->cell($_->[0],$_->[1]),$_->[2]),'get line');
	}

	$gd1 = new Geo::Raster($datatype,5,5);
	$gd1->rect(0,2,3,4,1);
	$a = $gd2->rect(0,2,3,4);
	for (@$a) {
	    ok(diff($gd1->cell($_->[0],$_->[1]),$_->[2]),'get rect');
	}

	$gd1 = new Geo::Raster($datatype,5,5);
	$gd1->circle(2,2,2,1);
	$a = $gd1->circle(2,1,2);
	for (@$a) {
	    ok(diff($gd1->cell($_->[0],$_->[1]),$_->[2]),'get circle');
	}

    }

    my $gd1 = new Geo::Raster('int',5,5);
    my $gd2 = new Geo::Raster('real',5,5);
    for ('line','rect','circle','floodfill') {
	$eval = "\$gd1->$_(2,3,4,4,3);\$gd2->$_(2,3,4,4,3);";
	eval $eval;
	if (0) {
	    $gd->print;
	    my $ret = $gd->sum();
	    print "$_ $ret\n";
	}
	ok(diff($gd1->sum(),$gd2->sum()),$_);
    }
}

