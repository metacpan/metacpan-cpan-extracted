=pod

=begin classdoc

Renders map images using a <a href='http://en.wikipedia.org/wiki/Mercator_Projection'>Mercator projection</a>
applied to GIS datasets available from 
<a href='http://www.evl.uic.edu/pape/data/WDB/'>CIA World DataBank II project</a>.
<p>
Copyright&copy; 2008, Dean Arnold, Presicient Corp., USA
<p>
Permission is granted to use, copy, modify, and redistribute this software
under the terms of the <a href='http://perldoc.perl.org/perlartistic.html'>
Perl Artistic License</a>.

@author D. Arnold
@since 2008-Jan-29
@see <cpan>GD::Map</cpan>
@see <cpan>Geo::Mercator</cpan>

=end classdoc

=cut

package GD::Map::Mercator;

use strict;
use warnings;

use GD;
use GD::Polyline;

our $VERSION = '1.03';


#
#	keep map of regions to lat/long bounding boxes,
#	so we can optimize dataset loading
#
our %regions = (
	'africa-bdy' => [ -30.658889, -17.075556, 41.594722,53.089722],
	'africa-cil' => [ -54.462778, -25.360556, 65.650278,77.588889],
	'africa-riv' => [ -34.400278, -16.708611, 42.038056,55.2525],
	'asia-bdy' => [ -9.126944, 19.001389, 54.476667,141.008889],
	'asia-cil' => [ -54.753889, -190.351944, 81.851944,180.0],
	'asia-riv' => [ -46.569722, -179.988056, 74.412222,180.0],
	'europe-bdy' => [ 36.151389, -8.751389, 70.088889,31.586667],
	'europe-cil' => [ 34.808889, -31.29, 71.165000,31.250278],
	'europe-riv' => [ 36.566111, -21.791944, 69.999722,29.468889],
	'namer-bdy' => [ 41.675556, -141.003056, 69.645556,-66.901111],
	'namer-cil' => [ 24.538333, -168.132778, 83.623611,-12.155],
	'namer-pby' => [ 29.706944, -139.047778, 68.900556,-57.1],
	'namer-riv' => [ 25.768333, -166.053056, 74.032222,-54.470833],
	'samer-bdy' => [ -55.556389, -117.1225, 32.718333,-51.682778],
	'samer-cil' => [ -85.470278, -179.987778, 33.003333,179.976111],
	'samer-riv' => [ -52.733333, -117.126111, 32.718333,-34.917222],
);

our %datasets = (
	africa	=> [ 'bdy', 'cil', 'riv' ],
	asia	=> [ 'bdy', 'cil', 'riv' ],
	europe	=> [ 'bdy', 'cil', 'riv' ],
	namer	=> [ 'bdy', 'cil', 'riv', 'pby' ],
	samer	=> [ 'bdy', 'cil', 'riv' ],
);

our %colors = (
	white	=> [255,255,255],
	lgray	=> [191,191,191],
	gray	=> [127,127,127],
	dgray	=> [63,63,63],
	black	=> [0,0,0],
	lblue	=> [0,0,255],
	blue	=> [0,0,191],
	dblue	=> [0,0,127],
	gold	=> [255,215,0],
	lyellow	=> [255,255,0],
	yellow	=> [191,191,0],
	dyellow	=> [127,127,0],
	lgreen	=> [0,255,0],
	green	=> [0,191,0],
	dgreen	=> [0,127,0],
	lred	=> [255,0,0],
	red		=> [191,0,0],
	dred	=> [127,0,0],
	lpurple	=> [255,0,255],
	purple	=> [191,0,191],
	dpurple	=> [127,0,127],
	lorange	=> [255,183,0],
	orange	=> [255,127,0],
	pink	=> [255,183,193],
	dpink	=> [255,105,180],
	marine	=> [127,127,255],
	cyan	=> [0,255,255],
	lbrown	=> [210,180,140],
	dbrown	=> [165,42,42],
	transparent => [1,1,1]
);

my %valid_fmt = qw(png newFromPng gif newFromGif jpg newFromJpeg jpeg newFromJpeg);

=pod

=begin classdoc

@constructor

Create an instance of GD::Map::Mercator. Either creates a 
new basemap image from the specified minimum/maximum latitude/longitude
values, or loads an existing basemap of the given name. Applies
the <a href='http://en.wikipedia.org/wiki/Mercator_projection'>Mercator Projection</a>
to datapoints collected from the 
<a href='http://www.evl.uic.edu/pape/data/WDB/'>CIA World Databank II</a> dataset 
to render a map image.
<p>
The map region to be rendered is specified by providing a set of
minimum/maximum latitude/longitude values (in degrees) defining the
bounding box of the region to be mapped. If the bounding box coordinates
are not specified, this object attempts to load a pre-existing
map image and data. When a map is rendered, an additional file
of configuration data is saved containing the bounding box coordinates
in both latitude/longitude and Mercator distances (in meters).
<p>
Once the base map has been created or loaded, the application may
use this object to

<ul>
<li>access the <cpan>GD</cpan> object to directly manipulate it,
<li>translate latitude/longitude coordinates to pixel coordinates
within the image
<li>convert pixel coordinates back to latitude/longitude coordinates
<li>rescale the image and its associated configuration data
<li>extract sub-images from the map to create new map images
</ul>
<p>

<b>NOTES:</b> 
<ol>
<li>The Mercator projection is subject to severe dimensional
distortions near the poles. Use of map coordinates above 70 degrees or
below -70 degrees latitude is discouraged.

<li>Latitiude values are specified in degrees between
+90 and -90, where negative values are in the southern hemisphere;
longitude values are in degrees between +180 and -180, with negative values
in the western hemisphere.

<li>This package uses the "Mercated" binary datasets generated
by <cpan>wdb2merc</cpan>. These datasets must be generated before
using this package.
</ol>

@optional basemap_path	directory path for basemap image and datafile. If a
	new map is generated, its image and config files will ba saved in this
	path; if using an existing map, its image and config files are loaded
	from this path. Note that, if creating a new map, this parameter is optional.

@optional basemap_name filename of basemap image and data; may contain
	the image format suffix ('.png', '.gif', '.jpg', '.jpeg'); if not
	suffixed, defaults to '.png'. The config data for the map is stored
	in a file of the same name, but with the format suffix replaced by
	'.conf'.  Note that, if creating a new map, this parameter is optional.

@optional data_path	directory path to the WDB data files; required if a new basemap
	is being rendered, or a submap may be extracted/scaled.

@optional min_lat	minimum latitude in degrees; may be fractional. If not specified,
	and no other latitude/longitude values are specified, this object attempts to
	load a pre-existing basemap. Dies if not specified when other lat/long values
	are specified.
@optional min_long	minimum longitude in degrees; same rules apply as for <code>min_lat</code>
@optional max_lat	maximum latitude in degrees; same rules apply as for <code>min_lat</code>
@optional max_long	maximum longitude in degrees; same rules apply as for <code>min_lat</code>
	<b>Note</b> that max_long may be negative, and min_long postitive, in which case
	the rendered basemap will span the antipodal meridian (i.e., where longitude crosses from +180
	to -180)
@optional width	width of the basemap image in pixels; default 400. This
	parameter is actually an upper bound, as the process of rendering adjusts the
	image width and height to properly reflect the scaling of the Mercator
	projection.
@optional height	height of the basemap image in pixels; default 400. This
	parameter is actually an upper bound, as the process of rendering adjusts the
	image width and height to properly reflect the scaling of the Mercator
	projection.
@optional background	background color of basemap image; default 'white'. May be either
	a named color supported by <cpan>GD::Color</cpan>, or an arrayref of RGB values.
@optional foreground	foreground color of basemap image (i.e., color of lines drawn); 
	default 'black'. May be either a named color supported by <cpan>GD::Color</cpan>, 
	or an arrayref of RGB values.
@optional thickness		thickness of lines in pixels; default 2
@optional omit		arrayref of dataset types to omit. Each continent may have
		any of 'bdy' (body), 'cli' (coast/islands), 'pby' (political boundry), or 
		'riv' (rivers) datasets. To omit one or more of them, include them
		in this omit list, e.g., omit => [ 'riv' ] omits rivers.
@optional keep		hashref mapping dataset types to an arrayref of
		latitude, longitude bounding box coordinates. Useful for filtering,
		e.g., all coasts/islands internal to a region, but keeping
		ocean coastal regions.
@optional save_coords	name of file to write pixel coordinates of the rendered
		image segments. Useful for e.g., creating HTML imagemaps, etc.
@optional silent	if true, no progress or diagnostic information is emitted;
		default false

@returns an instance of GD::Map::Mercator

=end classdoc

=cut

sub new {
	my ($class, %opts) = @_;

	if ($opts{data_path}) {
		die "data_path $opts{data_path} not found" 
			unless(-d $opts{data_path});

		$opts{data_path} .= '/' 
			unless (substr($opts{data_path}, -1) eq '/');
	}

	if ($opts{basemap_path}) {
		die "basemap_path $opts{basemap_path} not found." 
			unless(-d $opts{basemap_path});
	
		$opts{basemap_path} .= '/' 
			unless (substr($opts{basemap_path}, -1) eq '/');
	}
	else {
		$opts{basemap_path} = '';
	}

	my ($name, $fmt) = ('', 'png');
	if ($opts{basemap_name}) {
		$opts{basemap_name} .= '.png' 
			unless $opts{basemap_name}=~/\.(?:png|gif|jpg|jpeg)$/;

		($name, $fmt) = ($opts{basemap_name}=~/^(.+)\.(png|gif|jpg|jpeg)$/);
	}
	
	$opts{silent} = 0 unless exists $opts{silent};
	my $self = {
		data_path => $opts{data_path},
		basemap_path => $opts{basemap_path},
		basemap_loc => $opts{basemap_path} . $name,
		imgfmt => $fmt,
		verbose => !$opts{silent},
		thickness => $opts{thickness} || 2,
		foreground => $opts{foreground} || 'black',
		background => $opts{background} || 'white',
		keeps	=> $opts{keep} || {},
		omit	=> $opts{omit},
		save_coords => $opts{save_coords},
	};
	bless $self, $class;
#
#	if min/max info is provided, create a new basemap
#	else attempt to load existing basemap
#
	my $haspts = 0;
	$haspts += defined($opts{$_}) ? 1 : 0
		foreach (qw(min_lat min_long max_lat max_long));

	die "Incomplete latitude/longitude datapoints provided."
		if ($haspts > 0) && ($haspts < 4);
#
#	attempt to load existing basemap; dies on any error
#
	die "No basemap path or coordinates provided."
		unless $haspts || ($self->{basemap_path} && $self->{basemap_loc});

	return $self->_load_basemap()
		unless $haspts;
#
#	create a new basemap (maybe we should go ahead and check for a matching
#	existing basemap ?)
#
	die "No data_path specified."
		unless $self->{data_path};

	my ($minlat, $minlong, $maxlat, $maxlong, $width, $height) = 
		($opts{min_lat}, $opts{min_long}, 
		$opts{max_lat}, $opts{max_long}, 
		$opts{width} || 400, $opts{height} || 400);
	
	my $mercator;
	$self->{mercator} = $mercator = GD::Map::Mercator::Projector->new(
		$minlat, $minlong, $maxlat, $maxlong, $width, $height, $self->{verbose});

	my ($bg, $fg, $linew) = @$self{qw(background foreground thickness)};
	$| = 1 if $self->{verbose};
#
#	create empty image before loading data
#	Note that image dimensions are adjusted by the projector
#
	print "Creating GD image ($width x $height)\n"
		if $self->{verbose};
	($width, $height) = $mercator->dimensions();
	my $img = $self->{image} = GD::Image->new($width, $height);
	$self->{fg} = ref $fg ? $img->colorAllocate(@$fg) : 
		($fg=~/^#([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})$/i)
			? $img->colorAllocate(hex($1), hex($2), hex($3))
			: $img->colorAllocate(@{$colors{$fg}});
	$self->{bg} = ref $bg ? $img->colorAllocate(@$bg) : 
		($bg=~/^#([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})$/i)
			? $img->colorAllocate(hex($1), hex($2), hex($3))
			: $img->colorAllocate(@{$colors{$bg}});
	$img->filledRectangle(0,0,$width-1,$height-1,$self->{bg});
	$img->setThickness($linew);

	my @xy;
	my $seg = [];
#
#	check which of the datasets we need
#
	my @regions = ();
	my %omits = ();
	map $omits{$_} = 1, @{$opts{omit}}
		if $opts{omit};
		
	foreach (keys %regions) {
		if ((!$omits{substr($_, -3)}) &&
			(
				(($regions{$_}[0] <= $minlat) &&
				($regions{$_}[2] >= $minlat)) ||
				(($regions{$_}[0] <= $maxlat) &&
				($regions{$_}[2] >= $maxlat)) ||
				(($regions{$_}[0] >= $minlat) &&
				($regions{$_}[2] <= $maxlat))
			) &&
			(
				(($regions{$_}[1] <= $minlong) &&
				($regions{$_}[3] >= $minlong)) ||
				(($regions{$_}[1] <= $maxlong) &&
				($regions{$_}[3] >= $maxlong)) ||
				(($regions{$_}[1] >= $minlong) &&
				($regions{$_}[3] <= $maxlong))
			)) {
			print "Using $_\n" if $self->{verbose};
			push(@regions, $_);
		}
	}
	# open each of the data files
	my $oldfd = select(STDOUT);
	$| = 1;
	select $oldfd;
	foreach (@regions) {
		my $datapath = "$opts{data_path}$_.bin";
		print "\nLoading datafile $datapath\n" 
			if $self->{verbose};
		my $fd;
		print "Skipping $datapath ($!)\n" and next
			unless open $fd, $datapath;
		binmode $fd;
		$mercator->filter($fd, $self, $_, $self->{keep}{$_});
		close $fd;
	}

	return $self->{basemap_loc}
		? $self->save("$self->{basemap_loc}.$self->{imgfmt}")
		: $self;
}

=pod

=begin classdoc

Return this object's configuration information.

@returnlist a list of the latitude/longitude bounding box coordinates (in degrees),
	the Mercator distance bounding box coordinates (in meters), and the final
	width and height (in pixels) of the associated image, i.e.,
	<pre>
	($minlat, $minlong, $maxlat, $maxlong, 
	$minmerclong, $minmerclat, $maxmerclong, $maxmerclat,
	$width, $height)
	</prev>

=end classdoc

=cut

sub config {
	return $_[0]->{mercator}->config();
}

=pod

=begin classdoc

Extract a submap from this object's basemap.
Given latitude/longitude bounding box coordinates,
creates a new GD::Map::Mercator object with data and
image contained by the specified bounding box. The extracted
map may optionally be scaled. 
<p>
Note that any saved coordinates
will be lost unless a scale operation is applied to regenerate
them.

@param $minlat	minimum latitude of bounding box
@param $minlong	minimum longitude of bounding box
@param $maxlat	maximum latitude of bounding box
@param $maxlong	maximum longitude of bounding box
@optional $scale	any scaling to be applied to the submap

@returns	a new GD::Map::Mercator object

=end classdoc

=cut

sub extract {
	my ($self, $minlat, $minlong, $maxlat, $maxlong, $scale) = @_;

	my @coords = $self->{mercator}->config();
	
	$@ = 'Specified region outside the bounds of this map.',
	return undef
		if ($minlat < $coords[0]) || ($maxlat > $coords[2]) ||
			($minlong < $coords[1]) || ($maxlong > $coords[3]);

	my ($xmin, $ymin, $xminmerc, $yminmerc) = $self->{mercator}->project($minlat, $minlong);
	my ($xmax, $ymax, $xmaxmerc, $ymaxmerc) = $self->{mercator}->project($maxlat, $maxlong);
	my ($width, $height) = (($xmax - $xmin + 1), ($ymax - $ymin + 1));

	my $class = ref $self;
	if ($scale) {
#
#	just create a new map from scratch that scales the selected region
#
		$width *= $scale;
		$height *= $scale;
		
		return ${class}->new(
			data_path => $self->{data_path},
			min_lat => $minlat,
			min_long => $minlong,
			max_lat => $maxlat,
			max_long => $maxlong,
			width => $width,
			height => $height,
			verbose => $self->{verbose},
			thickness => $self->{thickness},
			foreground => $self->{foreground},
			background => $self->{background},
			keep => $self->{keep},
			omit => $self->{omit},
			save_coords => $self->{save_coords},
		);
	}

	my $newmap = {	
		data_path => $self->{data_path},
		min_lat => $minlat,
		min_long => $minlong,
		max_lat => $maxlat,
		max_long => $maxlong,
		width => $width,
		height => $height,
		verbose => $self->{verbose},
		thickness => $self->{thickness},
		foreground => $self->{foreground},
		background => $self->{background},
		keep => $self->{keep},
		omit => $self->{omit},
		save_coords => $self->{save_coords},
	};
	$newmap->{mercator} = GD::Map::Mercator::Projector->new(
		$minlat, $minlong, $maxlat, $maxlong, $width, $height, $self->{verbose});
	($width, $height) = $newmap->{mercator}->dimensions(); 
	my ($fg, $bg) = @$self{qw(foreground background)};
	my $img = $newmap->{image} = GD::Image->new($width, $height);
	$newmap->{fg} = ref $fg ? $img->colorAllocate(@$fg) :
		($fg=~/^#([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})$/i)
			? $img->colorAllocate(hex($1), hex($2), hex($3))
			: $img->colorAllocate(@{$colors{$fg}});
	$newmap->{bg} = ref $bg ? $img->colorAllocate(@$bg) :
		($bg=~/^#([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})$/i)
			? $img->colorAllocate(hex($1), hex($2), hex($3))
			: $img->colorAllocate(@{$colors{$bg}});
	$img->filledRectangle(1,1,$width,$height,$newmap->{bg});
	$img->setThickness($newmap->{thickness});
	$newmap->{image}->copy($self->{image}, 0, 0, $xmax, $ymax, $width, $height);

	return bless $newmap, $class;
}

=pod

=begin classdoc

Create a new scaled map from this object's basemap.
Causes a recalculation/rerendering of the map, in order
to properly render details on zoom-in scaling, or smooth
details on zom-out.

@param $scale	scaling factor; the width and height of
	this object's image are multiplied by this factor
	to generate the new GD::Map::Mercator object

@returns	a new GD::Map::Mercator object

=end classdoc

=cut

sub scale {
	my ($self, $scale) = @_;
	
	my $class = ref $self;
	my @coords = $self->{mercator}->config();
	
	return ${class}->new(
		data_path => $self->{data_path},
		min_lat => $coords[0],
		min_long => $coords[1],
		max_lat => $coords[2],
		max_long => $coords[3],
		width => $coords[-2] * $scale,
		height => $coords[-1] * $scale,
		silent => !$self->{verbose},
		thickness => $self->{thickness},
		foreground => $self->{foreground},
		background => $self->{background},
		keep => $self->{keep},
		omit => $self->{omit},
		save_coords => $self->{save_coords},
	);
}

=pod

=begin classdoc

Return the pixel and Mercator distance coordinates for the 
input latitude/longitude coordinates. Note that the input 
coordinates do not need to
be within the bounding box of this object's map.
<p>
Multiple sets of input coordinates may be supplied, in which
case multiple coordinate results will be returned (4 output values
per input coordinate pair).

@param	$latitude	latitude of coordinate to project (in degrees)
@param	$longitude	longitude of coordinate to project (in degrees)

@returnlist	a list of the (X,Y) pixel coordinate <i>and</i> the
	(X,Y) Mercator distances (in meters) for each set of input
	GIS coordinates.

=end classdoc

=cut

sub project {
	my $self = shift;
	return $self->{mercator}->project(@_);
}

=pod

=begin classdoc

Return the latitude/longitude and Mercator distance coordinates 
for the input pixel coordinates. Note that the input coordinates do not need to
be within the bounding box of this object's map.
<p>
Multiple sets of input coordinates may be supplied, in which
case multiple coordinate results will be returned (4 output values
per input coordinate pair).

@param	$x	horizontal pixel coordinate to translate
@param	$y	vertical pixel coordinate to translate

@returnlist	a list of the latitude/longitude coordinate (in degrees) <i>and</i> the
	(X,Y) Mercator distances (in meters) for each set of input pixel coordinates.

=end classdoc

=cut

sub translate {
	my $self = shift;
	return $self->{mercator}->translate(@_);
}

=pod

=begin classdoc

Return this object's GD::Image object.

@return the GD::Image object for this object's map image 

=end classdoc

=cut

sub image { return $_[0]->{image}; }

=pod

=begin classdoc

Write this object's image, configuration, and optional
coordinates map information
to the specified file. Useful for saving extracted or
scaled maps derived from basemaps.

@param	$outpath	a filepath specification, optionally
		including the image filename with an image type
		suffix of 'png', 'gif', 'jpg', or 'jpeg'.

@return undef on failure, with an error messge in <code>$@</code>;
	this object on success

=end classdoc

=cut

sub save {
	my ($self, $path) = @_;
	
	my $fmt = (substr($path, -4, 1) eq '.') ? substr($path, -3) 
		: (substr($path, -5, 1) eq '.') ? substr($path, -4)
		: undef;
	my ($confpath, $imgpath, $coordpath) = ($path, $path, $path);

	if ($fmt) {
		$@ = "Invalid or unsupported image format $fmt",
		return undef
			unless $valid_fmt{$fmt} && $self->{image}->can($valid_fmt{$fmt});
		$confpath=~s/$fmt$/conf/;
		$coordpath=~s/$fmt$/coords/;
	}
	else {
		$confpath .= '.conf';
		$coordpath .= '.coords';
		$imgpath .= '.png';
		$fmt = 'png';
	}

	die "Cannot open $imgpath: $!" unless open OUTF, ">$imgpath";
	binmode OUTF;
	print "Writing $imgpath\n" 
		if $self->{verbose};
	print OUTF ($fmt eq 'png') ? $self->{image}->png
		: ($fmt eq 'gif') ? $self->{image}->gif 
		: $self->{image}->jpeg;
	close OUTF;

	die "Cannot open $confpath: $!"
		unless open OUTF, ">$confpath";
#
#	save as simple CSV, no D::D madness
#
	print OUTF join(',', $self->{mercator}->config()), "\n";
	close OUTF;

	if ($self->{save_coords}) {
		die "Cannot open $coordpath: $!"
			unless open OUTF, ">$coordpath";
		print OUTF $self->{_coords};
		close OUTF;
	}
	return $self;
}

=pod

=begin classdoc

Return the actual width and height of this object's map image.
Note that the returned values may be different than the originally
requested dimensions, due to scaling for Mercator projection.

@returnlist	the actual width and height (in pixels) of this object's map image

=end classdoc

=cut

sub dimensions {
	return $_[0]->{mercator}->dimensions();
}

############################
# PRIVATE FUNCTIONS
############################

#
#	actually, this might be considered a pucliy overloaded
#	function; its the callback from the Mercator::Projector
#	object to render a segment
#
#	NOTE: need to apply some compress here: reduce adjacent coords
#	to a single pair of coords of equivalent line segment
#
sub add_segment {
	my ($self, $seg, $dataset, $segno) = @_;
	
	print "\rDrawing segment $segno               "
		if $self->{verbose};

	if ($self->{save_coords}) {
		my $coords = $self->{_coords} || '';
		my $area = 0;
		my $i = 0;
		while ($i < @$seg) {
			$i += 2
				while ($i < @$seg) && (!defined $seg->[$i]);
			last unless ($i < @$seg);

			$coords .= "Dataset $dataset Segment $segno Area $area: ";
			$coords .= join(',', $seg->[$i++], $seg->[$i++], '')
				while ($i < @$seg) && (defined $seg->[$i]);

			$coords .= "\n";
			$area++;
		}
		$self->{_coords} = $coords;
	}

	my $fg = $self->{fg};
	my $img = $self->{image};
	my $polyline = GD::Polyline->new();
	my ($lx, $ly) = ($seg->[0], $seg->[1]);
	my $i = 2;
	($lx, $ly) = ($seg->[$i++], $seg->[$i++]) 
		unless defined $lx;
	$polyline->addPt($lx, $ly);
	my $ptcnt = 0;
	while ($i < @$seg) {
		my ($x, $y) = ($seg->[$i++], $seg->[$i++]);
		$polyline->addPt($x, $y),
		$ptcnt++,
		($lx, $ly) = ($x, $y),
		next
			if defined $x;
#
#	if an undef marker, draw current line
#
		$img->polyline($polyline, $fg)
			if ($ptcnt > 2);
		$polyline = GD::Polyline->new();
		($lx, $ly) = (undef, undef);
		$ptcnt = 0;
		next;
	}
#
#	draw any remaining line
#
	$img->polyline($polyline, $fg)
		if ($ptcnt > 1);
	return 1;
}

sub _load_basemap {
	my $self = shift;

	my $pat = $valid_fmt{$self->{imgfmt}};

	my $conf = "$self->{basemap_loc}.conf";
	my $imgfile = "$self->{basemap_loc}.$self->{imgfmt}";
	die "Unsupported image format $self->{imgfmt}; check your GD configuration."
		unless GD::Image->can($pat);

	die "$conf not found."
		unless (-s $conf);

	die "$imgfile not found."
		unless (-s $imgfile);

	die "Cannot open $conf: $!"
		unless open F, $conf;
	my $data = <F>;
	close F;
	chomp $data;
	my @mapdata = split /,/, $data;
	
	die "Invalid map data file" 
		unless (scalar @mapdata == 10);
#
#	only install the lat/long and pixel coords, skip the mercator distances
#
	$self->{mercator} = GD::Map::Mercator::Projector->new(
		@mapdata[0..3], @mapdata[8..9], $self->{verbose});

	my $fd;
	die "Cannot open $imgfile: $!"
		unless open $fd, $imgfile;
	$self->{image} = 
		  ($self->{imgfmt} eq 'gif') ? GD::Image->newFromGif($fd)
		: ($self->{imgfmt} eq 'png') ? GD::Image->newFromPng($fd)
		: GD::Image->newFromJpeg($fd);
	close $fd;

	return $self;
}

1;


package GD::Map::Mercator::Projector;

=pod 

=begin hidden

Translates latitude, longitude datapoints to pixel coordinates
using Mercator Projection.

(Yes, I know Mercator is bad. Really bad. Criminal, even.
But its nice for rasterization. And its good enough for Google, so
its good enough for me.)

To convert to Mercator, we first computes
scales based on min/max lat/long pts.

Longitude is linear, except for some fiddling to deal with
crossing boundry from positive to negative.

Latitude requires some trig:

y = log(tan(lat) + sec(lat)) = log(sin(lat)/cos(lat) + 1/cos(lat))
	= log((sin(lat) + 1)/cos(lat));

(all in radians, of course)

(We should really use UTM...)

=end hidden

=cut

use POSIX;
use Geo::Mercator;

use strict;
use warnings;

sub new {
	my ($class, $minlat, $minlong, $maxlat, $maxlong, $width, $height, $verbose) = @_;

	die "Bad min/max longitude"
		if ($minlong < -180) || ($minlong > 180) ||
			($maxlong < -180) || ($maxlong > 180) ||
			(($maxlong < $minlong) && 
			((($maxlong < 0) && ($minlong < 0)) ||
			(($maxlong > 0) && ($minlong > 0))));
	die "Bad min/max latitude"
		if ($minlat > $maxlat) || ($minlat < -90) || ($minlat > 90) ||
			($maxlat < -90) || ($maxlat > 90);

	my ($xmin, $ymin) = mercate($minlat, $minlong);
	my ($xmax, $ymax) = mercate($maxlat, $maxlong);
	my $longadj = (($xmin > 0) && ($xmax < 0));

	my $hscale = $width/($xmax - $xmin);
	my $vscale = $height/($ymax - $ymin);
#
#	adjust the image dimensions to match best scaling
#
	my $scale = ($hscale < $vscale) ? $hscale : $vscale;
	$height = _round(($ymax - $ymin) * $scale);
	$width = _round(($xmax - $xmin) * $scale);
	
	my ($minmerclong, $minmerclat) = mercate($minlat, $minlong);
	my ($maxmerclong, $maxmerclat) = mercate($maxlat, $maxlong);
	
	return bless {
		minlat => $minlat,
		minlong => $minlong,
		maxlat => $maxlat, 
		maxlong => $maxlong, 
		minmerclat => $minmerclat,
		minmerclong => $minmerclong,
		maxmerclat => $maxmerclat, 
		maxmerclong => $maxmerclong, 
		xmin => $xmin, 
		ymin => $ymin, 
		xmax => $xmax, 
		ymax => $ymax, 
		scale => $scale,
		longadj => $longadj, 
		width => $width,
		height => $height,
		verbose => $verbose}, $class;
}

sub config {
	my $self = shift;
	return (@$self{qw(minlat minlong maxlat maxlong 
		minmerclong minmerclat maxmerclong maxmerclat width height)});
}

sub dimensions { return ($_[0]->{width}, $_[0]->{height}); }
#
#	return pixel coord from input lat/long
#
sub project {
	my $self = shift;
#
#	note: we assume the inputs are in a valid range, but not
#	neccesarily inside our bounding box
#
	my @result = ();
	while (@_) {
		my ($x, $y) = mercate(shift, shift);
		push @result, (($y <= $self->{ymax}) && 
				($y >= $self->{ymin}) && 
				($x >= $self->{xmin}) && 
				($x <= $self->{xmax}))
			? (_round(($x - $self->{xmin}) * $self->{scale}), 
		# lat goes bottom to top, pixels top to bottom
				_round($self->{height} - (($y - $self->{ymin}) * $self->{scale})))
			: ();
	}
	return @result;
}
#
#	return lat/long and mercator distances for input pixel coords
#
sub translate {
	my $self = shift;
#
#	upconvert to meters before demercating
#
	my @result = ();
	my ($xmin, $ymin, $scale, $longadj, $height) =
		@$self{qw(xmin ymin scale longadj height)};
	while (@_) {
		my ($x, $y) = (shift, $height - shift);
		$x /= $scale;
		$x += $xmin;
		$y /= $scale;
		$y += $ymin;
		push @result, demercate($x, $y), $y, $x;
	}
	return @result;
}

sub _round {
	return (ceil($_[0]) - $_[0]) < ($_[0] - floor($_[0]))
		? ceil($_[0])
		: floor($_[0]);
}

sub filter {
	my ($self, $fd, $container, $dataset, $keepers) = @_;
	
	my ($xmin, $ymin, $xmax, $ymax, $scale, $longadj, $width, $height) =
		@$self{qw(xmin ymin xmax ymax scale longadj width height)};
	my ($n, $len, $record, $segno, $rank, $pts);
	my @coords = ();
	my @mercs = ();
	my @keeppx = ();
#
#	convert keep region coords to pixel coords
#
	if ($keepers) {
		my $i = 0;
		my ($keepx, $keepy);
		while ($i < @$keepers) {
			($keepx, $keepy) = mercate($keepers->[$i++], $keepers->[$i++]);
			push @keeppx, 
				(_round(($keepx - $xmin) * $scale),
				_round($height - (($keepy - $ymin) * $scale)));
		}
	}
	while ($n = read($fd, $len, 4)) {
		$len = unpack('L', $len);
		$n = read($fd, $record, $len);
		($segno, $rank, $pts) = unpack('LLL', substr($record, 0, 12));
		$pts *= 2;
#
#	sometimes Perl doesn't believe me the 1st time!
#
		@mercs = unpack("d$pts", substr($record, 12));
		my $retry = 3;
		$retry--,
		@mercs = unpack("d$pts", substr($record, 12))
			while ($retry && (@mercs != $pts));
		die "No coords read!!!!" unless scalar @mercs == $pts;
		print "\n*** Had to reload segment $segno ", 3 - $retry, " times!\n"
			if $self->{verbose} && ($retry < 3);

		my $inside = 0;
		my ($lx, $ly) =
			(_round(($mercs[0] - $xmin) * $scale),
			_round($height - (($mercs[1] - $ymin) * $scale)));
		my $i = 2;
		while ($i < @mercs) {
			my ($x, $y) =
				(_round(($mercs[$i++] - $xmin) * $scale),
				_round($height - (($mercs[$i++] - $ymin) * $scale)));
#
#	scaling causes many pts to overlap, so skip them
#	!!!NOTE need to optimze for pts on the same line segment
#	(ie, no change in x, xor no change in y)
#
			next
				if ($x == $lx) && ($y == $ly);

			if (($y <= $height) && ($y >= 0) && ($x >= 0) && ($x <= $width) && 
				((!$keepers) || _keep(\@keeppx, $x, $y))) {
#
#	if prior point outside, add it w/ a undef marker
#	probably need to compute clipping intersection
#
				push @coords, undef, undef, $lx, $ly
					unless (($ly <= $height) && ($ly >= 0) && ($lx >= 0) && ($lx <= $width));
				push @coords, $x, $y;
				$inside++;
			}
			($lx, $ly) = ($x, $y);
		}
		if ($inside) {
			$container->add_segment(\@coords, $dataset, $segno) 
		}
		elsif ($self->{verbose}) {
			print "\r*** Skipping segment $segno            \r";
		}
		@mercs = ();
		@coords = ();
	}
	print "\n" if $self->{verbose};
	return $self;
}

sub _keep {
	my ($keeppx, $x, $y) = @_;
	my $i = 0;
	$i += 4
		while ($i < @$keeppx) &&
			(($y > $keeppx->[$i+3]) || ($y < $keeppx->[1]) ||
			($x < $keeppx->[$i]) || ($x > $keeppx->[$i+2]));
	return ($i != @$keeppx);
}

1;

__END__
