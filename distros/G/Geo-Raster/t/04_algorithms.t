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

# growzones interpolate dijkstra map neighbors colored_map applytempl thin borders areas connect number_areas 

for my $e ('dbf','prj','shp','shx') {
    unlink "v_test.$e";
}

{
#    my $grid = Geo::Raster->new(filename=>'vt.bil',load=>1);
    my $grid = Geo::Raster->new(50,50);
    $grid->circle(25,25,10,1);
    eval {
	require Geo::Vector;
    };
    if ($@) {
      SKIP: {
	  skip 'No Geo::Vector', 1;
      }
    } else {
	my $vector = $grid->polygonize();
    }
}

{
    my @args; 
    $args[0] = {growzones=>['new Geo::Raster(10,10)','4'],interpolate=>['method=>"nn"'],
		dijkstra=>['4,5'],map=>['{0=>1,3=>5,4=>3}'],
		applytempl=>['[0,1,0,0,1,0,1,1,1],2'],
		ca_step=>[1,1,1,0,0,0,0],
		thin=>['quiet=>1'],borders=>['method=>"simple"'],
		areas=>[],
		neighbors=>[],
		colored_map=>[],
		connect=>[],
		number_areas=>[]};

    $args[1] = {borders=>['method=>"recursive"']};

    my %for_real = (interpolate=>1,dijkstra=>1);

    for my $datatype ('int','real') {

	for my $method ('ca_step','grow_zones','interpolate','dijkstra','map','neighbors',
			'colored_map','applytempl','thin','borders','areas','connect','number_areas') {

	
	    next if $method eq 'applytempl';
	    next if $method eq 'thin';
	    next if $datatype eq 'real' and !$for_real{$method};

	    my $gd = new Geo::Raster($datatype,10,10);
	    $gd->set(2,2,3);
	    
	    for my $cv (0,1) {

		next unless $args[$cv]->{$method};
	  
		my $agd = new Geo::Raster($datatype,10,10);

		my @as;
		for my $a (@{$args[$cv]{$method}}) {
		    if ($a eq 'grid') {
			push @as,"\$agd";
		    } elsif ($a eq 'int') {
			push @as,4;
		    } else {
			push @as,$a;
		    }
		}
		my $arg_list = join(',',@as);

		for (1,0) {
		    my $lvalue = '';
		    $lvalue = '$lvalue=' if $_;
		    my $eval = "$lvalue\$gd->$method($arg_list);";
		    eval $eval;
		    ok(!$@, "$method, $@");
		}
	    }
	}
    }
}

