use GD::Map::Mercator;

 my $map = GD::Map::Mercator->new(
 	basemap_path => "./basemaps",
	data_path => "./WDBbin",
 	basemap_name => "africa.png",
	max_long => 65,
	min_long => -22,
	max_lat => 40,
	min_lat => -37,
	silent => 0,
	width => 800,
	height => 800,
	background => 'white',
	foreground => [ 128, 128, 128],
	thickness => 2,
	omit => [ 'riv' ],
	);

