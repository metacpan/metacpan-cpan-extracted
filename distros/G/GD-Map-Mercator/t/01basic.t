use Test::More tests => 11;
BEGIN { use_ok('GD::Map::Mercator') };

#
#	make a map image
#	get the image
#	get the dimanesion
#	get the config
#	extract a submap
#	scale a map
#	project some pts
#	translate some pts
#	save a map
#	cleanup (unlink the map files)
#
my $bindir = $ENV{WDB_BIN} || "./WDBbin";
SKIP:
{
	my $ok = (-d $bindir) ? 1 : 0;
	if ($ok) {
		foreach (qw(asia-bdy.bin
			asia-cil.bin
			asia-riv.bin
			namer-bdy.bin
			namer-cil.bin
			namer-pby.bin
			namer-riv.bin
			samer-bdy.bin
			samer-cil.bin
			samer-riv.bin)) {
			$ok = 0, last unless -f "$bindir/$_";
		}
	}
	skip "Binary GIS data not found.
	(Have you run wdb2merc yet ? 
	Did you set the WDB_BIN environment variable to 
		the WDB binary data directory ?)", 10 unless $ok;
	skip "basemaps directory not found.", 10
		unless -d "./basemaps";

my $map = GD::Map::Mercator->new(
 	basemap_path => "./basemaps",
	data_path => $ENV{WDB_BIN} || "./WDBbin",
 	basemap_name => "usa.png",
	background => 'white',
	foreground => [ 128, 128, 128],
	thickness => 2,
	omit => [ 'riv' ],
	silent => 1,
);

ok($map && $map->isa('GD::Map::Mercator'), 'construct from existing map');

my $img = $map->image();

ok($img && $img->isa('GD::Image'), 'image()');

my ($w, $h) = $map->dimensions();

ok($w && $h && ($w == 800) && ($h == 433), 'dimensions()');

my @config = $map->config();

ok(@config && (scalar @config == 10) &&
	($config[0] == 24) &&
	($config[1] == -126) &&
	($config[2] == 50) &&
	($config[3] == -65) &&
	($config[4] > -14026255.84) && 
	($config[4] < -14026255.83)&&
	($config[5] > 2736034.985) && 
	($config[5] < 2736034.986) &&
	($config[6] > -7235766.902) &&
	($config[6] < -7235766.901) &&
	($config[7] > 6413524.594) &&
	($config[7] < 6413524.595) &&
	($config[8] == 800) &&
	($config[9] == 433),	'config()');

my $submap = $map->extract(30, -87, 40, -70);
ok($submap && $submap->isa('GD::Map::Mercator'), 'extract()');

my ($x, $y) = $map->project(42.23, -83.33);
ok($x && $y && ($x > 558) && ($x < 560) && ($y > 146) && ($y < 148), 'project()');

my ($lat, $long, $latmerc, $longmerc) = $map->translate($x,$y);
ok($lat && ($lat > 42.2) && ($lat < 42.3) &&
	$long && ($long < -83.3) && ($long > -83.4) &&
	$latmerc && ($latmerc < 5165046.6) && ($latmerc > 5165046.5) &&
	$longmerc && ($longmerc < -9278642.23) && ($longmerc > -9278642.24), 'translate()');

#print STDERR " *** NOTE: scale() test takes a long time to complete.\n";
my $smallmap = $map->scale(0.5);
ok($smallmap && $smallmap->isa('GD::Map::Mercator'), 'scale()');

#print STDERR " *** NOTE: new map constructor test takes a long time to complete.\n";
$map = GD::Map::Mercator->new(
 	basemap_path => "./basemaps",
	data_path => $ENV{WDB_BIN} || "./WDBbin",
 	basemap_name => "test.png",
	max_long => -65,
	min_long => -126,
	max_lat => 50,
	min_lat => 24,
	width => 800,
	height => 800,
	background => '#800033',
	foreground => [ 128, 128, 128],
	thickness => 2,
	omit => [ 'riv' ],
	silent => 1,
);
ok($map && $map->isa('GD::Map::Mercator'), 'construct new map');

ok($map->save('./basemaps/test.png'), "save");
}
