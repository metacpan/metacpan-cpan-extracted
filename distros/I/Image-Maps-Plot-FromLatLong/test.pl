# LatLong tests

print "1..11\n";
use Cwd;
use Image::Magick;

print "ok 1\n";

use Image::Maps::Plot::FromLatLong;
print "ok 2\n";


if (not mkdir cwd."/__test__"){
	print "not ok 4\n";
	die "Could not make test dir: dying before messing with files: unlink the __test__ dir manually to prevent errors";
} else {
	print "ok 4\n";
}
chdir cwd."/__test__";
my $cwd = cwd."/";


# Do things with maps
if ($^O =~ /win/ig and $ENV{WINDIR}){
	my $maker = new Image::Maps::Plot::FromLatLong(
		FONT=>$ENV{WINDIR}.'/fonts/arial.ttf',
		THUMB_SIZE => '200',
		PATH	=> cwd."/test.foo",
	);
	if (ref $maker){
		print "ok 3\n";
	} else {
		print "not ok 3\n";
		die;
	}
} else{
	print "skip 3\n";
}

if ($maker){
	if ($maker->all(cwd)){
		print "ok 5\n";
	} else {
		print "no ok 5\n";
	}
	my $i = Image::Magick->new;
	if ($i->BlobToImage( ${$maker->create_blob} )){
		print "not ok 6\n";
	} else {
		print "ok 6\n";
	}
	if ($i->Write($cwd."__test__.jpg")){
		print "not ok 7\n";
	} else {
		print "ok 7\n";
		unlink "__test__.jpg";
	}

	if ($maker->create_imagefile){
		print "ok 8\n";
	} else {
		print "no ok 8\n";
	}
} else {
	for (5..8){
		print "skip $_\n";
	}
}


$maker = new Image::Maps::Plot::FromLatLong(
	# FONT=>$ENV{WINDIR}.'/fonts/arial.ttf',
	THUMB_SIZE => '200',
	PATH	=> cwd."/test.foo",
	DBFILE	=> undef,
);

if (0==scalar keys %Image::Maps::Plot::FromLatLong::locations){
	print "ok 9\n";
} else {
	print "no ok 9\n";
}


%Image::Maps::Plot::FromLatLong::MAPS->{"THE WORLD"}->{FILE} = cwd."/../world.jpg";
# $Image::Maps::Plot::FromLatLong::MAPS{'world.jpg'} = 'world.jpg';

$maker = new Image::Maps::Plot::FromLatLong(
	# FONT=>$ENV{WINDIR}.'/fonts/arial.ttf',
	THUMB_SIZE => '200',
	PATH	=> $cwd."/Two.foo",
	DBFILE	=> undef,
	LOCATIONS => {
          'Lee' => {
			 'LAT' => '51.592423',
			 'PLACE' => 'Leslie Road, London, N2 8BH, United Kingdom',
			 'LON' => '-0.171996'
		   },
          'Lee Again' => {
			'PLACE' => 'Veres Péter U.198, Budapest XVI, H-1165',
			'LAT' => 46,
			'LON' => 16
		  },
	},
);

if($maker->{HTML}){
	die length $maker->{HTML};
}

if (2==scalar keys %Image::Maps::Plot::FromLatLong::locations){
	print "ok 10\n";
} else {
	print "no ok 10 # "
	.(scalar keys %Image::Maps::Plot::FromLatLong::locations)
	."\n";
}
chdir $cwd;
unlink <*.*>;

if ($maker->create_imagefile){
	print "ok 10\n";
} else {
	print "no ok 10\n";
}

chdir $cwd;
unlink <*.*>;
chdir "/";
if (rmdir $cwd){
	print "ok 11\n";
} else {
	print "no ok 11	# $cwd $!\n";
}



# Add a map
$Image::Maps::Plot::FromLatLong::MAPS{"LONDON AREA"} = {
	FILE =>	'C:\PhotoWebServer\Perl\site\lib\Image\Maps\Plot\london_bourghs.jpg',
	DIM	 => [650,640],
	SPOTSIZE => 5,
	ANCHOR_PIXELS => [447,397],		# Greenwich on the pixel map
	ANCHOR_LATLON => [51.466,0],	# Greenwich lat/lon
	ANCHOR_NAME	  => 'Greenwich',
	ANCHOR_PLACE  => 'Observatory',
	ONEMILE		=> 19.5,			# 1 km = .6 miles  (10km=180px = 10miles=108px)
};

# Remove a map
delete $Image::Maps::Plot::FromLatLong::MAPS{"THE UK"};

exit;
1;