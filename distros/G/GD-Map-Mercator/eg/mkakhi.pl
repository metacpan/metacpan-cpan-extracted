use GD::Map::Mercator;
#
#	make Alaska map
#
my $map = GD::Map::Mercator->new(
 	basemap_path => "./basemaps",
	data_path => "./WDBbin",
 	basemap_name => "alaska.png",
	max_long => -135,
	min_long => -172,
	max_lat => 71.9,
	min_lat => 51,
	silent => 0,
	width => 140,
	height => 140,
	background => 'white',
	foreground => [ 128, 128, 128],
	thickness => 2,
	omit => [ 'riv' ],
	);

#
#	make Hawaii map
#
my $map = GD::Map::Mercator->new(
 	basemap_path => "./basemaps",
	data_path => "./WDBbin",
 	basemap_name => "hawaii.png",
	max_long => -154,
	min_long => -161,
	max_lat => 23,
	min_lat => 18.5,
	silent => 0,
	width => 100,
	height => 100,
	background => 'white',
	foreground => [ 128, 128, 128],
	thickness => 2,
	omit => [ 'riv' ],
	);
