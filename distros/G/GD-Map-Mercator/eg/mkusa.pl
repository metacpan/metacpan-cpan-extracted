use GD::Map::Mercator;

 my $map = GD::Map::Mercator->new(
 	basemap_path => "./basemaps",
	data_path => "./WDBbin",
 	basemap_name => "usa.png",
	max_long => -65,
	min_long => -126,
	max_lat => 50,
	min_lat => 24,
	width => 800,
	height => 800,
	background => 'white',
	foreground => [ 128, 128, 128],
	thickness => 2,
	omit => [ 'riv' ],
	silent => 1,
	);

