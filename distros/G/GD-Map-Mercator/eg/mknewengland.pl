use GD::Map::Mercator;

 my $map = GD::Map::Mercator->new(
 	basemap_path => "./basemaps",
	data_path => "./WDBbin",
 	basemap_name => "newengland.png",
	max_long => -69.5,
	min_long => -78.5,
	max_lat => 45.7,
	min_lat => 36,
	silent => 0,
	width => 400,
	height => 480,
	background => 'white',
	foreground => [ 128, 128, 128],
	thickness => 2,
	omit => [ 'riv' ],
	);

