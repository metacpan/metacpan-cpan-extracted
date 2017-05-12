package GD::Map;

use strict;
use GD;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

our $VERSION = '1.00';

sub new {
	my %opts = @_;

	# what do we need?
	# well, the path of the basemaps (required)
	# and the output path (required)

	die "basemap_path not defined" unless($opts{basemap_path});
	die "output_path not defined" unless($opts{output_path});

	die "could not find basemap_path [$opts{basemap_path}]" unless(-d $opts{basemap_path});
	
	unless(-d $opts{output_path}) {
		# try and create it
		mkdir $opts{output_path}, 0775;
		die "could not find output_path [$opts{output_path}]" unless(-d $opts{ouput_path});
	}

	my $m = {
		output_path => _pathstr($opts{output_path}),
		basemap_path => _pathstr($opts{basemap_path}),
		verbose => $opts{verbose},
		};
	bless $m, __PACKAGE__;

	return $m;
}

sub dump {
	my $m = shift;

	print Data::Dumper->Dump([$m]);
}

sub add_data {
	my $m = shift;
	my %data = @_;

	push @{$m->{data}}, { %data };
}

sub add_object {
	my $m = shift;
	my %opts = @_;

	die "id not defined" unless($opts{id});
	my %tmp;
	$tmp{id} = $opts{id};
	foreach my $t (qw(line circle text rectangle dot image)) {
		$tmp{type} = $t if ($opts{type} eq $t);
	}
	die "type [$opts{type}] not defined or is not valid" unless($tmp{type});

	# transfer some other options to the tmp variable
	foreach my $t (qw(color filled fillcolor)) {
		$tmp{$t} = $opts{$t} if ($opts{$t});
	}

	# make sure this object type does not yet exist
	foreach my $or (@{$m->{objects}}) {
		die "$opts{id} object is already defined"
			if ($or->{id} eq $opts{id});
	}

	# otherwise push it into the object types
	push @{$m->{objects}}, { %tmp };
}

sub create_basemap {
	my $m = shift;
	my %opts = @_;

	# We need

	# map name
	die "map_name not defined" unless($opts{map_name});

	# data_path (location of CIA map data)
	die "data_path not defined" unless($opts{data_path});

	die "could not find data_path [$opts{data_path}]" unless(-d $opts{data_path});
	$opts{data_path} = _pathstr($opts{data_path});

	my ($my,$ny,$mx,$nx,$scale);
	if ($opts{scale}) {
		# scale and min lat/long and max lat/long

		# we need to shrink by 25% when done
		# to get that "soft" look
		$scale = $opts{scale}*4; 

		# make sure we have min and max lat and long
		foreach my $mm (qw(min max)) {
			foreach my $ll (qw(lat long)) {
				die unless(defined($opts{"${mm}_${ll}"}));
			}
		}
		print "Setting size from scale information\n" if ($m->{verbose});
		$my = $opts{max_lat}*$scale;
		$ny = $opts{min_lat}*$scale;
		$mx = $opts{max_long}*$scale;
		$nx = $opts{min_long}*$scale;
		print "max_y = $my, min_y = $ny, max_x = $mx, min_x = $nx\n" if ($m->{verbose});
	} else {
		# height and width in pixels and either a start and end lat and start long
		#  or a start and end long and start lat

		die "scale not provided";
	}

	# we also need a background color (default to white)
	# and a line color (default to black)

	my @xy;
	my @seg;

	# open each of the data files
	opendir D, $opts{data_path};
	while (my $f = readdir D) {
		next unless(-f "$opts{data_path}$f");
		open F, "$opts{data_path}$f";
		print "Reading datafile $opts{data_path}$f\n" if ($m->{verbose});
		while (my $l = <F>) {
			if ($l =~ m/^segment/) {
				push @xy, [ @seg ] if (scalar @seg);
				undef @seg;
				next;
			} else {
				$l =~ s/^\s+//;
				my ($y,$x) = split /\s+/, $l;
				next if ($y > $opts{max_lat});
				next if ($y < $opts{min_lat});
				next if ($x > $opts{min_long}*-1);
				next if ($x < $opts{max_long}*-1);
				$x = int($x*$scale*-1);
				$y = int($y*$scale);
				push @seg, "$x,$y";
			}
		}
	
		push @xy, [ @seg ] if (scalar @seg);
		close F;
	}
	close D;

	die "No data information loaded" unless(scalar @xy);

	my $width = $mx-$nx;
	my $height = $my-$ny;
	print "Setting up GD Image ($width x $height)\n" if ($m->{verbose});
	my $im = new GD::Image($width,$height);
	my $fg = $im->colorAllocate(100,100,100);
	my $bg = $im->colorAllocate(255,255,255);
	$im->setThickness(2);
	$im->fill(1,1,$bg);

	print "Drawing basemap\n" if ($m->{verbose});
	foreach my $seg (@xy) {
		my ($lx,$ly);
		foreach my $xy (@{$seg}) {
			my ($x,$y) = split ',', $xy;
			$x = $mx-$x;
			$y = $my-$y;
			if (defined($lx)) {
				if ($x < $width/10 && $lx > $width-($width/10)) {
					1;
				} else {
					$im->line($x,$y,$lx,$ly,$fg);
				}
			}
			$lx = $x;
			$ly = $y;
		}
	}

	my $outputf = "$m->{basemap_path}$opts{map_name}.png";
	print "Writing $outputf\n" if ($m->{verbose});
	open F, ">$outputf";
	binmode F;
	print F $im->png;
	close F;

	# make sure the file was written
	unless (-s $outputf) {
		die "$outputf was not created (maybe a permission problem?)"
	}

	# update data file
	_read_basemap_data($m);
	$m->{basemap}->{$opts{map_name}}{scale} = $opts{scale};
	$m->{basemap}->{$opts{map_name}}{min_long} = $opts{min_long};
	$m->{basemap}->{$opts{map_name}}{max_long} = $opts{max_long};
	$m->{basemap}->{$opts{map_name}}{min_lat} = $opts{min_lat};
	$m->{basemap}->{$opts{map_name}}{max_lat} = $opts{max_lat};
	_write_basemap_data($m);
}

sub set_basemap {
	my $m = shift;
	my $map_name = shift;

	# load the basemap config file
	_read_basemap_data($m);

	# then check and see if we can find the basemap information in the file
	die "Sorry, $map_name is not a valid basemap" 
		unless(defined($m->{basemap}{$map_name}));

	# and then see if we can find the file itself
	die "Sorry, could not find $m->{basemap_path}$map_name"
		unless(-s "$m->{basemap_path}$map_name.png");

	$m->{use_basemap} = $map_name;

}

sub map_scale {
	my $m = shift;

	die "Sorry, basemap not defined" unless($m->{use_basemap});
	die "Sorry, no scale for basemap $m->{use_basemap}"
		unless(defined($m->{basemap}{$m->{use_basemap}}{scale}));

	return $m->{basemap}{$m->{use_basemap}}{scale};
}

sub draw {
	my $m = shift;
	my $d = shift;
	
	$m->{data} = $d if (defined($d));
	die "No data to draw" unless(scalar @{$m->{data}});

	die "Please set_basemap before calling draw" unless($m->{use_basemap});
	my $b = $m->{basemap}{$m->{use_basemap}};

	$m->{map_width} = int(($b->{max_long}-$b->{min_long})*$b->{scale});
	$m->{map_height} = int(($b->{max_lat}-$b->{min_lat})*$b->{scale});
	my $max_x = $m->{map_width};
	my $max_y = $m->{map_height};

	# create an md5 of the $m->object which we will use as the unique file name
	$m->{filename} = md5_hex(Data::Dumper->Dump([$m]));

	#$m->dump();

	print "Creating GD Image\n" if ($m->{verbose});
	my $im = new GD::Image->new("$m->{basemap_path}$m->{use_basemap}.png");

	# loop through the objects and then draw all of them in the correct order
	# so they get layered depending on how the objects where created
	foreach my $or (@{$m->{objects}}) { 
		print "Drawing object $or->{id} [$or->{type}]\n" if ($m->{verbose});

		# allocate object colors
		foreach my $t (qw(color fillcolor)) {
			if (defined($or->{$t})) {
				my ($r,$g,$b) = split ',', $or->{$t};
				$or->{$t} = $im->colorAllocate($r,$g,$b);
			}
		}

		foreach my $dr (@{$m->{data}}) {
			next unless($dr->{id} eq $or->{id});
			if ($or->{type} eq "line") {
				my ($x1,$y1,$x2,$y2) = _latlong_to_xy($m,$dr);
				print "Drawing line from $x1,$y1 to $x2,$y2\n" if ($m->{verbose});
				$im->line($x1,$y1,$x2,$y2,$or->{color});
			} elsif ($or->{type} eq "dot") {
				my $size = $dr->{size} || 4;
				my ($x1,$y1) = _latlong_to_xy($m,$dr);
				print "Drawing dot at $x1,$y1 size $size\n" if ($m->{verbose});
				$im->filledArc($x1,$y1,$size,$size,0,360,$or->{color});
			} elsif ($or->{type} eq "circle") {
				my $size = $dr->{size} || 4;
				my ($x1,$y1) = _latlong_to_xy($m,$dr);
				print "Drawing circle at $x1,$y1 size $size\n" if ($m->{verbose});
				$im->arc($x1,$y1,$size,$size,0,360,$or->{color});
			} elsif ($or->{type} eq "image") {
				die "Could not find file $dr->{image_path}"
					unless(-f $dr->{image_path});
				
				foreach my $t (qw(image_height image_width)) {
					die "Invalid or missing $t" unless($dr->{$t});
				}

				my $img = new GD::Image->new($dr->{image_path});
				my $h = $dr->{image_height};
				my $w = $dr->{image_width};
				my $dx = int($h/2);
				my $dy = int($w/2);
				my ($x1,$y1) = _latlong_to_xy($m,$dr);
				$im->copy($img,$x1-$dx,$y1-$dy,0,0,$h,$w);
			}
		}
	}

	open(IMG, ">$m->{output_path}$m->{filename}.png");
	binmode IMG;
	print IMG $im->png;
	close IMG;

	die "Map file did not get created correctly"
		unless(-s "$m->{output_path}$m->{filename}.png");

	print "$m->{output_path}$m->{filename}.png created\n" if ($m->{verbose});
}

############################
# PRIVATE FUNCTIONS
############################
sub _latlong_to_xy {
	my $m = shift;
	my $data = shift;

	my $b = $m->{basemap}{$m->{use_basemap}};

	my $x1 = int(($b->{max_long}-$data->{start_long})*$b->{scale});
	my $y1 = int(($b->{max_lat}-$data->{start_lat})*$b->{scale});
	my $x2 = int(($b->{max_long}-$data->{end_long})*$b->{scale})
		if (defined($data->{end_long}));
	my $y2 = int(($b->{max_lat}-$data->{end_lat})*$b->{scale})
		if (defined($data->{end_lat}));

	return ($x1,$y1,$x2,$y2);
}

sub _read_basemap_data {
	my $m = shift;

	$m->{basemap} = {};
	return unless(-s "$m->{basemap_path}mapdata.conf");
	open F, "$m->{basemap_path}mapdata.conf";
	my $data;
	while (my $l = <F>) {
		$data .= $l;
	}
	close F;

	eval $data;
}

sub _write_basemap_data {
	my $m = shift;

	open F, ">$m->{basemap_path}mapdata.conf";
	print F Data::Dumper->Dump([\%{$$m{basemap}}],['$$m{basemap}']);
	close F;

	unless (-s "$m->{basemap_path}mapdata.conf") {
		die "$m->{basemap_path}mapdata.conf was not created (maybe a permission problem?)"
	}
}

sub _pathstr {
	my $path = shift;

	return (($path =~ m/\/$/) ? $path : "$path/");
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

GD::Map - Perl extension for creating geographic map files with GD

=head1 SYNOPSIS

  use GD::Map;
  my $m = GD::Map:new(
  	basemap_path => "[required]",
	output_path => "[required]",
	verbose => 1,
	);
  $m->set_basemap("northamerica");
  $m->add_object(id => "route", type => "line", color => "255,0,0");
  $m->add_data(
  	id => "route",
	start_long => 123.1,
	end_long => 124.7,
	start_lat => 49.3,
	end_lat => 37.5,
	);
  $m->draw();

  my $filename = "$m->{filename}.png";
  my $w = $m->{map_width};
  my $h = $m->{map_height};

=head1 ABSTRACT

  Perl extension for creating geographic map files with GD

=head1 HISTORY

This library came out of work I did/do for iFLOOR.com.  In our systems we have
lots of information about customers that come to our website.  If they provide us
with a zip/postal code, we have database lookup tables that can translate that
into a lattitude and longitude value.  We use this data for supplier selection logic,
but it could also be used for other interesting things.  We also have lookup tables
that give approximate lattitude and longitude values for network subnets.

Anyway, we had a wealth of data, but I had never gotten around to putting any of this
data on a map.  I had done a lot of dynamic graphing, and drawing with GD, but Mapping
seemed to be too hard, or at least I thought so.

I looked into GIS type things, and map projection logic, which all became waaay to
complicated.  I wasn't that interested in map projections, I just wanted to have a flat 
grid, that raw lattitude and longitude values translated easily onto.  

The thing I had a problem with was where to get the basemap.  Then I came across:

 http://www.evl.uic.edu/pape/data/WDB/ - CIA World DataBank II

The files that Dave Pape created gave me exactly what I needed.  These files are also
needed to make this module work.

=head1 DESCRIPTION

=head2 CREATING BASEMAPS

The first thing you need to do is download the WDB files and unzip them somewhere.  
For example /usr/local/wdb/.  There should be a number of large text files (11 I think).

Then you need to create one (or multiple), basemaps.

 use GD::Map;

 my $m = GD::Map::new(
 	basemap_path => "/data/basemaps",
	output_path => "/data/maps",
	);

 $m->create_basemap(
 	map_name => "testing",
	data_path => "/usr/local/wdb",
	scale => 8,
	max_long => 162,
	min_long => 65,
	max_lat => 70,
	min_lat => 14,
	);

This will create a testing.png file in /data/basemaps.

Making scale bigger will zoom in, smaller will zoom out.

A mapdata.conf file will also be created in /data/basemaps.  This is crutial for 
GD::Map to function.  The create_basemap function modifies this file.

NOTE!!!.  Once the basemap file has been created, you need to scale it down 25%.
You can do this in whatever editor you want, but the initial drawing is a little 
crunchy, so I usually use gimp or something to smooth things out.  This seemed
better than trying to incorporate Image::Magick in here, which sometimes gets cranky.
Plus, basemaps do not get created very often so it is not much work.  Maybe in the
future I will add an option to do this for you if you have Image::Magick installed.

=head2 CREATING MAPS

 my $m = GD::Map::new(
 	basemap_path => "/data/basemaps",
	output_path => "/data/maps",
	);

To create maps, after getting your map object, you need to define object types.
They can be thought of as groups of similar objects and the order in which they
are defined, determines the order in which they are drawn.

 $m->add_object(id => "travel", type => "line", color => "128,128,128");
 $m->add_object(id => "source", type => "dot", color => "0,0,0");
 $m->add_object(id => "dest", type => "dot", color => "255,0,0");

This will setup 3 different things.  First we draw all the "travel" lines, then 
we draw the "source" dots, and finally the "dest" dots.  This will make sure that
the "source" dots are over top of the lines, and that the "dest" dots are on top
of everything else, just in case there is some overlapping.

Finally we add the actual data.  The order in which the data is drawn depends on
the order of the objects, and then the order in which the data was added.

 $m->add_data(id => "travel", 
 	start_long => 125, end_long => 90,
 	start_lat => 62, end_lat => 55);
 $m->add_data(id => "travel", 
 	start_long => 85, end_long => 90,
 	start_lat => 30, end_lat => 55);

Since the travel objects are of type line, they need a start and end lat and long.

 $m->add_data(id => "source", start_long => 125, start_lat => 62);
 $m->add_data(id => "source", start_long => 85, start_lat => 30);
 $m->add_data(id => "dest", start_long => 90, start_lat => 55);

And since the source and dest objects are of type dot, they only need start lat and long.

Then we need to set our basemap.

 $m->set_basemap("testing");

And finally we draw!

 $m->draw();

GD::Map creates a unique filename using the data provided.  Draw writes the
file into the output_path you specified (in our example /data/maps).

Once draw() is done, you can find the filename, and height and width of the image
in the map object.

 my $filename = "$m->{filename}.png";
 my $w = $m->{map_width};
 my $h = $m->{map_height};

If you have any questions or suggestions about this module please feel free to
send me an email.

=head2 add_object

 $m->add_object(
 	id => whatever you want,
	type => line|dot|circle|image
	color => "r,g,b",
	);

=head2 add_data

 $m->add_data(
 	id => should match add object id otherwise it will not draw,
	start_long => required,
	start_lat => required,
	end_long => required for line type things,
	end_lat => required for line type things,
	size => size (diameter) of circle or dot in pixels (default 4),
	image_path => path to image file if object type is "image",
	image_width => width of image at image_path,
	image_height => width of image at image_path,
	);

=head2 EXPORT

None by default.

=head1 SEE ALSO

http://www.evl.uic.edu/pape/data/WDB/ - CIA World DataBank II

=head1 AUTHOR

Chris Sutton, E<lt>chriskate@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Chris Sutton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
