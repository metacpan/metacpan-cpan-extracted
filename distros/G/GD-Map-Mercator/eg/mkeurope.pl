use GD::Map::Mercator;

 my $map = GD::Map::Mercator->new(
 	basemap_path => "./basemaps",
	data_path => "./WDBbin",
 	basemap_name => "europe.png",
	max_long => 70,
	min_long => -12.5,
	max_lat => 70,
	min_lat => 33,
	silent => 1,
	width => 800,
	height => 800,
	background => 'white',
	foreground => [ 128, 128, 128],
	thickness => 2,
	omit => [ 'riv' ],
	);

