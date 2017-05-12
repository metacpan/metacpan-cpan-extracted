use GD::Map::Mercator;

 my $map = GD::Map::Mercator->new(
 	basemap_path => "./basemaps",
	data_path => "./WDBbin",
 	basemap_name => "americas.png",
	max_long => -30,
	min_long => -172,
	max_lat => 73,
	min_lat => -57,
	silent => 1,
	width => 800,
	height => 800,
	background => 'white',
	foreground => [ 128, 128, 128],
	thickness => 2,
	omit => [ 'riv' ],
	);

