# PolyMap.pm
# 
# Contains the KML backend functions for the Google Earth Census Visualization
# Project. These functions are responsible for taking data from the DB backend
# and turning it into a viewable KML file.
#
# Copyright 2007, Imran Haque (ihaque@cs.stanford.edu)
#
# This code is free software and is licensed under the same terms as Perl itself.
# 

=pod

=head1 NAME

Geo::KML::PolyMap - Generate KML/KMZ-format choropleth (shaded polygonal) maps viewable in Google Earth

=head1 SYNOPSIS

	use Geo::KML::PolyMap qw(generate_kml_file generate_kmz_file);

	# Clusters "Total Population" data for "Foobar City" in $entities into 5 bins;
	# renders using colors from $startcolor to $endcolor;
	# generates a legend; renders output to file handle passed in $kmz_filehandle
	generate_kmz_file(entities => $entities,
                          placename => "Foobar City",
                          data_desc => "Total Population",
                          nbins => 5,
                          kmzfh => $filehandle_for_kmz_output,
                          startcolor => "FFFF0000",
                          endcolor => "FF00FF00");

	# As above, but without a legend
        generate_kml_file(entities => $entities,
                          placename => "Foobar City",
                          data_desc => "Total Population",
                          nbins => 5,
                          kmlfh => $filehandle_for_kml_output,
                          startcolor => "FFFF0000",
                          endcolor => "FF00FF00");

=head1 REQUIRES

=over

=item * Carp

=item * Archive::Zip

=item * GD >=2.0

=item * File::Temp

=item * Statistics::Descriptive

=back

=head1 DESCRIPTION

Geo::KML::PolyMap generates KML or KMZ-formatted maps for Google Earth. Given a set of polygonal regions and a number associated with each
region (for example, city blocks and population counts on each block), Geo::KML::PolyMap generates a choropleth map showing the data value
for each region as a shaded polygon. The polygons are divided into a number of bins, with the color of each bin unique. Optionally,
Geo::KML::PolyMap will generate a legend along with the map file to illustrate the data ranges represented by each color.

=head1 CONFIGURATION

Geo::KML::PolyMap includes two parameters which must be configured by direct code changes.

=head2 Font Selection

To generate legend files with generate_kmz_file(), you must specify the path to a TrueType (.ttf) font file in the variable $FONT_PATH.
This is clearly suboptimal and will change in a future revision.

=head2 Binning Method

The algorithm used to bin data points is also configurable. Please see the section on binning in generate_kml_file() for details.

=head1 DATA STRUCTURES

=head2 Points

A point is defined as a latitude,longitude pair. Since Google Earth uses the WGS-84 coordinate system, you probably should too.

Points are represented in Geo::KML::PolyMap as strings of the following form:

	(latitude,longitude)

So, for example, the following are legal points:

	my $pt = "(24,-12)";
	my $pt = "(123.456,-78.90)"

But the following are not:

	my $pt = "(199,140)";	 # latitude is out of range
	my $pt = "24,-12";	 # missing parentheses

=head2 Polygons

A polygon is defined as a series of at least 4 points in the plane. Consecutive points are joined to form the polygon edges, and the last
point must be the same as the first. The mapping results are undefined if edges in the polygon cross.

Polygons are represented in Geo::KML::PolyMap as strings containing comma-delimited lists of points, wrapped in a pair of parentheses:

	"((lat1,long1),(lat2,long2),(lat3,long3),(lat1,long1))"

The following is an example of a legal polygon:

	my $poly = "((1,2),(3,4),(5,6),(7,8),(1,2))";

The following are examples of illegal polygons:

	my $poly = "((1,2),(3,4),(5,6),(7,8))"; # last point must be the same as the first point
	my $poly = "((1,2),(3,4),(1,2))";	# not enough points; need at least 4
	my $poly = "(1,2),(3,4),(5,6),(1,2)"; 	# missing parentheses

=head2 Entities

Entities are the structure used by Geo::KML::PolyMap to move data into the map generation process. An entity is a very simple polygon/data pair,
stored in a hashref. The polygon must be accessible from key "polygon", and the data point must be a number accessible from key "data":

	my $polygon = "((1,2),(3,4),(5,6),(1,2))";
	my $data = "10";
	my $entity = {	data => $data,
			polygon => $polygon};

Geo::KML::PolyMap functions take references to arrays of entities:

	# Assume we have $entity1,$entity2,$entity3 defined already
	my $mapdata = [$entity1,$entity2,\$entity3];

=head1 METHODS

=cut

package Geo::KML::PolyMap;

use strict;
use warnings;

use Statistics::Descriptive;
use Carp;
use GD;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Temp qw( tempfile );

my $FONT_PATH = "/usr/share/fonts/truetype/freefont/FreeSans.ttf";


BEGIN {
	use Exporter ();
	our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
#	v1.0	ihaque	5/30/06	initial version
#	v1.1	ihaque	5/31/06	added equipartition binning
#	v1.2	ihaque	???	added k-means binning
#	v1.3	ihaque	???	added rendering to disk
#	v 1.31	ihaque	3/1/07	moved from EXPORT to EXPORT_OK
#	v 1.32	ihaque	3/2/07	fixed documentation bug with SYNOPSIS
#	v 1.33	ihaque	6/22/07	added rudimentary support for altitude-mapping data
#				changed default font path to that for FreeSans
#	v 1.34	ihaque	9/19/07	fixed bug relating to spaces in the polygon string passed to kml_polygon
#
	$VERSION = 1.34;
	@ISA = qw(Exporter);
	@EXPORT = ();
	%EXPORT_TAGS = ();
	@EXPORT_OK = qw(&generate_kml_file &generate_kmz_file);
}

# generate_style(string color,OPT string id )
# Returns reference to an array containing KML lines
# representating the polystyle
sub generate_kml_style($;$) {
	my ($color,$id)=@_;
	my @style;
	if (defined $id) {
		push (@style,"<Style id=\"$id\">");
	} else {
		push (@style,"<Style>");
	}
	#push (@style,"\t<PolyStyle>");
	#push (@style,"\t\t<color>$color</color>");
	#push (@style,"\t</PolyStyle>");
	push (@style,"<PolyStyle>");
	push (@style,"<color>$color</color>");
	push (@style,"</PolyStyle>");
	push (@style,"</Style>");

	return \@style;
	#my $kml_style = join("\n",@style);
	#return \$kml_style;
}

# generate_colors(int nbins,OPT string start,OPT string end)
#   start: OBGR hex representation of a color, defaults to ff000000
#   end:   OBGR hex representation of a color, defaults to ffffffff
# Returns reference to an array of nbins OBGR strings, equally spaced between
# start and end
sub generate_colors($;$$) {
	my ($nbins,$start,$end) = @_;
	$start = 'ff000000' if not defined $start;
	$end = 'ffffffff' if not defined $end;

	my @s;
	my @e;
	my @delta;
	for (my $i=0;$i<4;$i++) {
		$s[$i] = hex substr($start,$i*2,2);
		$e[$i] = hex substr($end,$i*2,2);
		$delta[$i]=$e[$i]-$s[$i];
	}
	
	my @colors;
	for (my $i=0;$i<$nbins;$i++) {
		my @thiscolor;
		for (my $j=0;$j<4;$j++) {
			$thiscolor[$j] = int ($s[$j]+($i/$nbins)*$delta[$j]);
			$thiscolor[$j] = 255 if ($thiscolor[$j] > 255);
		}
		push (@colors,sprintf("%02x%02x%02x%02x",@thiscolor));
	}
	return \@colors;
}

# generate_kml_polygon(entity& entity)
# Returns reference to a array containing the lines of the
# KML version of entity->polygon
sub generate_kml_polygon($) {
	my ($entity) = @_;
	carp "Undefined entity" if not defined $entity;
	# Preprocess altitude for concatenations
	my $altitude = $entity->{altitude};
	if (not defined $altitude) {
		$altitude=",0";
	} else {
		$altitude=",".$altitude;
	}
	
	my $polystring = $entity->{polygon};
	#print "in gen_kml_polygon on entity number ".$entity->{number}."\n";
	if (not defined $polystring) {
		warn "Undefined polygon";
		warn "entity->data = ".$entity->{data}."\n";
		warn "entity->number = ".$entity->{number}."\n";
		die;
	}
	# Clear spaces from the polystring
	$polystring =~ s/ //g; 
	# Clear the double parens that postgres gives us
	$polystring =~ s/\(\(/(/;
	$polystring =~ s/\)\)$/)/;
	# Nuke open parens
	$polystring =~ tr/\(//d;
	
	$polystring =~ s/\),/)/g;
	#$polystring =~ s/\)/$altitude\n\t\t/g;
	$polystring =~ s/\)/$altitude /g;
	
	
	# Terribly inefficient - could replace with a here document
	my @kml_poly;
	push(@kml_poly,"<Polygon>");
	push(@kml_poly,"<extrude>1</extrude>");
	#push(@kml_poly,"<tessellate>1</tessellate>");
	push(@kml_poly,"<altitudeMode>relativeToGround</altitudeMode>");
	push(@kml_poly,"<outerBoundaryIs>");
	push(@kml_poly,"<LinearRing>");
	push(@kml_poly,"<coordinates>");
	#push(@kml_poly,split(/\n/,$polystring));
	push(@kml_poly,$polystring);
	push(@kml_poly,"</coordinates>");
	push(@kml_poly,"</LinearRing>");
	push(@kml_poly,"</outerBoundaryIs>");
	push(@kml_poly,"</Polygon>");
	
	return \@kml_poly;
}

# bin_entities(entity[]& entities,int nbins)
# MODIFIES entities - adds/sets 'bin' attribute for each entity
# Returns reference to array of references to struct bin as hashes:
# struct bin {
# 	int[] entityidx
# 	double binbound
# }

sub bin_entities($$) {
	return _bin_kmeans(@_);
}

sub _bin_percentile ($$) {
	my ($entities,$nbins)=@_;
	carp "Number of bins not passed to bin_entities" if not defined $nbins;
	
	my $stat = Statistics::Descriptive::Full->new();
	foreach my $entity (@$entities) {
		$stat->add_data($entity->{data});
	}
	my %stat_bins = $stat->frequency_distribution($nbins);
	my @binbounds = sort {$a <=> $b} keys %stat_bins;
	my @bins;
	for (my $i=0;$i<$nbins;$i++) {
		$bins[$i]={entityidx => [], binbound => $binbounds[$i]};
	}

	for (my $i=0;$i<(scalar @$entities);$i++) {
		my $entity=$entities->[$i];
		my $data=$entity->{data};
		my $bin;
		for (my $j=$#binbounds;$j>=0;$j--) {
			$bin = $j if ($data <= $binbounds[$j]);
		}
		$entity->{bin}=$bin;
		push(@{$bins[$bin]->{entityidx}},$i);
	}

	return \@bins;
	
}
sub _bin_equipartition ($$){ 
	my ($entities,$nbins)=@_;
	carp "Number of bins not passed to bin_entities" if not defined $nbins;
	
	my $stat = Statistics::Descriptive::Full->new();
	foreach my $entity (@$entities) {
		$stat->add_data($entity->{data});
	}
	my @binbounds;
	for (my $i=1;$i<=$nbins;$i++) {
		my $bound=$stat->percentile(($i/$nbins)*100.0);
		# Only take unique bounds
		push(@binbounds,$bound) if (($#binbounds < 0) or ($bound!=$binbounds[$#binbounds]));
	}
	croak "Fewer bins (".(scalar @binbounds).") than requested from equipartition ($nbins)!" if ($nbins != (scalar @binbounds));
	$nbins = (scalar @binbounds);
	
	my %stat_bins = $stat->frequency_distribution(\@binbounds);
	my @bins;
	for (my $i=0;$i<$nbins;$i++) {
		$bins[$i]={entityidx => [], binbound => $binbounds[$i]};
	}

	for (my $i=0;$i<(scalar @$entities);$i++) {
		my $entity=$entities->[$i];
		my $data=$entity->{data};
		my $bin;
		for (my $j=$#binbounds;$j>=0;$j--) {
			$bin = $j if ($data <= $binbounds[$j]);
		}
		$entity->{bin}=$bin;
		push(@{$bins[$bin]->{entityidx}},$i);
	}

	return \@bins;
}
	
	
sub _bin_kmeans($$) {
	my ($entities,$nbins)=@_;
	
	my $rdata = [];
	foreach my $ent (@$entities) {
		push(@$rdata,$ent->{data});
	}
	my $assn = _kmeans($rdata,$nbins,15);
	# This needs to be a hash in kmeans because the bin numbers are not necessarily contiguous
	my %bins = ();
	for (my $i=0;$i<scalar(@$assn);$i++) {
		my $bin = $assn->[$i];
		if (not defined $bins{$bin}) {
			#warn "Assigning new element number $i: ".$rdata->[$i]." to bin $bin";
			$bins{$bin} = {entityidx => [], binbound => $rdata->[$i]}
		}
		$bins{$bin}->{binbound} = _max($bins{$bin}->{binbound},$rdata->[$i]);
		push(@{$bins{$bin}->{entityidx}},$i);
	}
	
	my @sorted_bins = ();
	#foreach my $key (keys %bins) {
	#	my $b = $bins{$key};
	#	if (not defined $b->{binbound}) {
	#		die "Missing binbound in bin $key, with keys ".join(' ',(keys %$b)).".";
	#	} else {
	#		warn "Bin $key has keys ".join(' ',keys(%$b)).".";
	#	}
	#}
	 @sorted_bins = sort {$a->{binbound} <=> $b->{binbound}} (values %bins);
	
	
	return \@sorted_bins;
}

# generate_kml_placemark(entity[]& entities,string placename,string description
#                    string color,fh file)
# Renders KML lines of the placemark
# consisting of a MultiGeometry containing the given entities to the filehandle given
# 
# Sets the default LookAt to the coordinates of the first point in the first
# entity's polygon.
sub generate_kml_placemark($$$$$) {
	my ($entities,$placename,$description,$color,$fh)=@_;

	#print "gen_kml_pm called with entities size ".(scalar @$entities)."\n";
	return if ((scalar @$entities)==0);
	# Default LookAt values
	my $range = 5000;
	my $tilt = 0;
	my $heading = 59;
	
	my @placemark;
	push(@placemark,'<Placemark>');
	push(@placemark,"<name>$placename</name>");
	push(@placemark,"<description><![CDATA[$description]]></description>");
	
	# Get the first polygon, and weed out XML tags
	
	my $first_kml_poly = generate_kml_polygon($entities->[0]);
	my @poly_cords = grep(!/^\t*</,@$first_kml_poly);
	my @coords = split /,/,$poly_cords[0];
	$coords[0] =~ s/^\s*//;
	
	push(@placemark,"<LookAt>");
	push(@placemark,"<longitude>$coords[0]</longitude>");
	push(@placemark,"<latitude>$coords[1]</latitude>");
	push(@placemark,"<range>$range</range>");
	push(@placemark,"<tilt>$tilt</tilt>");
	push(@placemark,"<heading>$heading</heading>");
	push(@placemark,"</LookAt>");

	my $style = generate_kml_style($color);
	push(@placemark,@$style);
	push(@placemark,"");

	push(@placemark,"<MultiGeometry>");

	print $fh join('',@placemark);
	@placemark=();
	
	#my $entity_idx=0;
	#print "entities appears to have ".(scalar @$entities)." entries in g_placemark\n";
	foreach my $entity (@$entities) {
		#print "Processing entity $entity_idx\n" if ($entity_idx>130);
		my $poly = generate_kml_polygon($entity);
		print $fh join('',@$poly);
		#push(@placemark,@$poly);
		#$entity_idx++;
	}
	push(@placemark,"</MultiGeometry>");
	push(@placemark,"</Placemark>");
	
	print $fh join('',@placemark);
	return;
}

=pod

=head2 generate_kml_file() -- generate a KML file (map only)

Renders the data passed in in entities to a KML file, rendered to the filehandle passed in.

Parameters are passed in as named arguments in a hash.

=head3 Example:

	generate_kml_file(entities => $entities,
			  placename => "Foobar City",
			  data_desc => "Total Population",
			  nbins => 5,
			  kmlfh => $filehandle_for_kml_output,
			  startcolor => "FFFF0000",
			  endcolor => "FF00FF00");

=head3 Mandatory arguments

=over

=item * entities

Reference to an array of "entities", the data structure described above, used to store lists of (polygon,data) pairs.

=item * placename

A string containing a textual description (name) of the place represented by the given entities

=item * data_desc

A string describing the sort of data given in the entities

=item * nbins

The maximum number of bins into which to cluster the given data (see "Binning" below)

=item * kmlfh

Handle to an open-for-writing file into which to render the KML data.

=back

=head3 Optional arguments

=over

=item * startcolor

The OBGR color used for the bins with the lowest numerical value in the range provided. Defaults to FF000000. 
See "Colors" below.

=item * endcolor

The OBGR color used for the bins with the highest numerical value in the range provided. Defaults to FFFFFFFF.

=back

=head3 Description

generate_kml_file renders the data provided in the given entities to a KML map suitable for display in Google Earth. To do this,
it first separates the data into a user-configurable number of bins (see "Binning"), then assigns each bin a color. The bin with
lowest numerical value is assigned color "startcolor" and the bin with largest value gets color "endcolor"; bins between these
have their colors calculated by linear interpolation between these two values. The final KML file will have one placemark for
each data bin, so that each bin can be viewed/hidden independently.

=head4 Placemark naming

Each placemark is named "[placename] Bin [n]", where placename is the parameter passed in, and n is the index of the bin which the
placemark represents. Each placemark has a description "[data_desc] less than or equal to [bound]", where data_desc is passed in,
and bound is the upper bound on the data values in that bin.

=head4 Binning

The code makes an attempt to separate the data into nbins separate bins. In some degenerate cases (such as nbins > #data points),
there will be fewer output bins than requested, but there will never be more than nbins bins in the output map. There are three
binning algorithms implemented in the code, as _bin_percentile, _bin_equipartition, and _bin_kmeans. The particular algorithm
used can be modified by changing the function bin_entities (there may be future support for a parameter to change the method).
The default method is _bin_kmeans. The algorithms are detailed below:

=over 

=item * _bin_percentile

This method calculates a histogram of the data values, then divides the bins equally by percentile. For example, with nbins=5,
the bins will contain the [0,20), [20,40), [40,60), [60,80), [80,100] 'th percentiles of the data. This method is fast but has
several drawbacks. The most serious is that the raw percentile boundaries are often not helpful in the presence of outliers.

=item * _bin_equipartition

This method calculates a histogram of the data values, then divides the histogram into nbins sections such that each bin
has an (almost) equal number of data points within it. This also suffers the problem that outliers can induce highly artificial
bin boundaries.

=item * _bin_kmeans

This method performs a k-means clustering on the data, with k=nbins. In theory, this should separate the data points into
"natural" groupings; in practice it seems to work quite well. Its major disadvantage is that it is much more computationally
intensive than the other two methods, a problem which is exacerbated when the number of data points becomes large.

=back

=head4 Colors

Colors for this library are represented in the same OBGR format used by KML files. This format represents each color as a 32-bit
hexadecimal number, with 8 bits each for opacity (transparency), blue, green, and red. Note that the ordering of values is
different from usual web color specifications, which are RGB. Examples:

	FFFF0000 = pure blue
	80FF0000 = blue, 50% transparency
	00FF0000 = blue, fully transparent
	FF00FF00 = pure green
	FF0000FF = pure red

Colors for each bin are constructed by linear interpolation between the optional parameters startcolor and endcolor. The
interpolation is not weighted by bin values; it is just a simple interpolation along the line between start and end in RGB space.

=cut

sub generate_kml_file {
	my %args = @_;
	return _generate_kml_file($args{entities},$args{placename},$args{data_desc},
				  $args{nbins},$args{kmlfh},$args{startcolor},$args{endcolor});
}

# _generate_kml_file(entity[]& entities,string placename,string data_desc,
#                   int nbins,fh filehandle,OPT string startcolor,OPT string endcolor);
# Fills filehandle with the lines of a KML file constituting a display
# for the given entities, split into nbins placemarks.
sub _generate_kml_file($$$$$;$$) {
	my ($entities,$placename,$datadesc,$nbins,$fh,$startcolor,$endcolor) = @_;

	# Refactored to expose bins and colors for legend generation in KMZ
	my $bins_colors = _generate_bins_colors($entities,$nbins,
						$startcolor,$endcolor);

	# Map data parameter in entities to altitude
	altitude_map($entities,"data");
	
	return _generate_kml($entities,$placename,$datadesc,$nbins,
			     $bins_colors->[0],$bins_colors->[1],$fh);
}

# _generate_kml(entity[]& entities,string placename,string data_desc,
# 		int nbins,bin[]& bins,string[]& colors,fh file
# 		OPT string legend_file_name)
# Internal function taking in entities, bins, and colors, and generating
# the associated KML file to the filehandle file
# Return as specified in (user-visible) generate_kml_file
sub _generate_kml($$$$$$$;$) {
	my ($entities,$placename,$datadesc,$nbins,$bins,$colors,$fh,$legend_file_name) = @_;

	my @kml_file;

	push(@kml_file,"<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
	push(@kml_file,"<kml xmlns=\"http://earth.google.com/kml/2.0\">");
	push(@kml_file,"<Document>");

	if (defined $legend_file_name) {
		push(@kml_file,"<ScreenOverlay>");
		push(@kml_file,"<description>$placename $datadesc</description>");
		push(@kml_file,"<name>Legend</name>");
		push(@kml_file,"<Icon>");
		push(@kml_file,"<href>$legend_file_name</href>");
		push(@kml_file,"</Icon>");
		push(@kml_file,"<overlayXY x=\"0\" y=\"1\" xunits=\"fraction\" yunits=\"fraction\"/>");
		push(@kml_file,"<screenXY x=\"0\" y=\"1\" xunits=\"fraction\" yunits=\"fraction\"/>");
		push(@kml_file,"<rotationXY x=\"0\" y=\"0\" xunits=\"fraction\" yunits=\"fraction\"/>");
		push(@kml_file,"<size x=\"0\" y=\"0\" xunits=\"pixels\" yunits=\"pixels\"/>");
		push(@kml_file,"<rotation>0</rotation>");
		push(@kml_file,"</ScreenOverlay>");
	}
	print $fh join('',@kml_file);
	@kml_file=();
	
	for (my $i=0;$i<(scalar @$bins);$i++) {
		my $bin = $bins->[$i];
		my $entityidx = $bin->{entityidx};
		#carp $entityidx."\n";
		#carp @$entityidx."\n";
		# Fold singletons into a list
		#print "Bin $i contains ".join(',',@$entityidx)."\n";
		my @selected_entities = ( @$entities[@$entityidx] );
		generate_kml_placemark(
			\@selected_entities,
			$placename." bin ".($i+1),
			$datadesc." less than/equal to ".$bin->{binbound},
			$colors->[$i],
			$fh);
		#my $placemark=[""];
		#push(@kml_file,@$placemark);
	}
		   
	push(@kml_file,"</Document>");
	push(@kml_file,"</kml>");
	print $fh join('',@kml_file);
	return;
}

# altitude_map(entity[]& entities,string fieldname)
# MODIFIES entities - adds altitude attribute based on data value in fieldname for each entity
# returns none

sub altitude_map($$) {
	my ($ents,$fname) = @_;
	my $minval = $ents->[0]->{$fname};	
	my $maxval = $ents->[0]->{$fname};	
	foreach my $ent (@$ents) {
		if ($ent->{$fname} < $minval) {
			$minval = $ent->{$fname};
		} elsif ($ent->{$fname} > $maxval) {
			$maxval = $ent->{$fname};
		}
	}
	# Use a 3km altitude scale
	my $alt_scale = 3000;
	# Place bottom of range 50m above ground to avoid artifacting
	my $min_height = 50;

	my $multiplier = $alt_scale/($maxval-$minval);
	my $offset = $minval - $min_height;

	foreach my $ent (@$ents) {
		$ent->{altitude} = ($ent->{$fname}-$offset) * $multiplier;
	}

	return;
}

# _generate_bins_colors(entity[]& entities,int nbins,OPT string startcolor
# 			OPT string endcolor)
# Internal function which generates bins and bin colors for a KML file
# Returns arrayref [$bins $colors]

sub _generate_bins_colors($$;$$) {

	my ($entities,$nbins,$startcolor,$endcolor) = @_;

	my $bins = bin_entities($entities,$nbins);
	$nbins = (scalar @$bins);
	my $colors = generate_colors($nbins,$startcolor,$endcolor);

	return [$bins,$colors];
}

# generate_legend(bin[]& bins,color[]& colors,string font_path,OPT int font_size,OPT int patch_size)
# Returns a reference to a PNG file with a legend for the given bins
sub generate_legend($$$;$$) {
	my ($bins,$colors,$font_path,$text_size,$patch_size) = @_;
	$text_size = 12 if not defined $text_size;
	$patch_size = 30 if not defined $patch_size;
	my $hmargin = 5;
	my $vmargin = $patch_size/6;

	my $format = "%.3f - %.3f";

	my @bounds = ( 0 );
	for (my $i=0;$i < (scalar @$bins);$i++) {
		my $bin = $bins->[$i];
		push @bounds,$bin->{binbound};
	}
	# Find the max size required by the description text
	my $maxtextwidth = 0;
	my $maxtextheight = 0;
	for (my $i = 0; $i < $#bounds; $i++) {
		my @loopbound = 
			GD::Image->stringFT(0,$font_path,$text_size,0,0,0,
			sprintf($format,$bounds[$i],$bounds[$i+1]));
		$maxtextwidth = 
			_max($loopbound[2]-$loopbound[0],
			$loopbound[4]-$loopbound[6],
			$maxtextwidth);
		# Coordinates increase as you go down and to the right...
		$maxtextheight = 
			_max($loopbound[1]-$loopbound[7],
			$loopbound[3]-$loopbound[5],
			$maxtextheight);
	}
	my $rowheight = _max($patch_size,$maxtextheight);
	my $imagewidth = $patch_size + $hmargin + $maxtextwidth;
	my $imageheight = $rowheight * $#bounds;

	my $im = new GD::Image($imagewidth,$imageheight,1);

	my $white = $im->colorAllocate(255,255,255);
	my $black = $im->colorAllocate(0,0,0);
	my @bincolors;
	for (my $i=0;$i < (scalar @$colors);$i++) {
		my @vals = split //,$colors->[$i];
		#Colors are OBGR, GD expects RGBA with half range
		my $color = 
			$im->colorAllocate(hex(join('',@vals[6..7])),
				hex(join('',@vals[4..5])),
				hex(join('',@vals[2..3])));
		push @bincolors,$color;
	}
	# BUG ALERT - this will break things maybe if the user picks black as a color..
	$im->transparent($black);
	$im->filledRectangle(0,0,$imagewidth,$imageheight,$black);

	for (my $i = 0; $i < $#bounds; $i++) {
		$im->filledRectangle(0,
			$i*$rowheight,
			$patch_size,
			$i*$rowheight+$patch_size - 1,
			$bincolors[$i]);

		$im->stringFT($white,
			$font_path,
			$text_size,
			0,
			$patch_size+$hmargin,
			$i*$rowheight + $patch_size - 1 - $vmargin,
			sprintf($format,$bounds[$i],$bounds[$i+1]));
			#"$bounds[$i] - $bounds[$i+1]");
	}

	my $pngdata = $im->png;
	return \$pngdata;
		
}

sub _max {
	my $themax = shift;
	my $elt;
	while ($elt = shift) {
		$themax = $elt if (defined($elt) and ($elt > $themax));
	}
	return $themax;
}

=pod

=head2 generate_kmz_file() -- generate a KMZ file (KML map + PNG legend)

Renders the data passed in in entities to a KML file. Generates appropriate legend, and combines the legend and KML file into a KMZ file
stored into the filehandle passed as a parameter.

Parameters are passed in as named arguments in a hash.

=head3 Example:

	generate_kmz_file(entities => $entities,
			  placename => "Foobar City",
			  data_desc => "Total Population",
			  nbins => 5,
			  kmzfh => $filehandle_for_kmz_output,
			  startcolor => "FFFF0000",
			  endcolor => "FF00FF00");

=head3 Mandatory arguments

=over

=item * entities

Reference to an array of "entities", the data structure described above, used to store lists of (polygon,data) pairs.

=item * placename

A string containing a textual description (name) of the place represented by the given entities

=item * data_desc

A string describing the sort of data given in the entities

=item * nbins

The maximum number of bins into which to cluster the given data (see "Binning" below)

=item * kmzfh

Handle to an open-for-writing file into which to render the KML data.

=back

=head3 Optional arguments

=over

=item * startcolor

The OBGR color used for the bins with the lowest numerical value in the range provided. Defaults to FF000000. 
See "Colors" under generate_kml_file().

=item * endcolor

The OBGR color used for the bins with the highest numerical value in the range provided. Defaults to FFFFFFFF.

=back

=head3 Description

generate_kmz_file first generates a KML map for the given data, as described in generate_kml_file. It then generates a PNG legend
containing a color swatch for each data bin and the range of values represented in each bin. The KML map and PNG legend are
put together into a ZIP archive known as a KMZ file, ready for viewing in Google Earth. This KMZ file is written out to the
filehandle passed in as a parameter.

Please see generate_kml_file for additional details on the rendered KML map.

This version of generate_kmz_file renders temporary data (the KML map) to a tempfile to reduce memory footprint.

=cut

sub generate_kmz_file {
	my %args = @_;
	return _generate_kmz_file($args{entities},$args{placename},$args{data_desc},
				  $args{nbins},$args{kmzfh},$args{startcolor},$args{endcolor});
}

# _generate_kmz_file(entity[]& entities,string placename,string data_desc,
#                   int nbins,fh kmzfh, OPT string startcolor,
#                   OPT string endcolor);
# Returns void 
# File 'kmzfh' will be a KMZ file containing the
# KML source and the legend diagram

sub _generate_kmz_file($$$$$;$$) {
	my ($entities,$placename,$datadesc,$nbins,$kmzfh,$startcolor,$endcolor) = @_;

	my $legend_name = "legend.png";
	

	my $bins_colors = _generate_bins_colors($entities,$nbins,
						$startcolor,$endcolor);
	
	# Map data parameter in entities to altitude
	altitude_map($entities,"data");

	# OK to render the legend to RAM - it's small
	my $legend = generate_legend($bins_colors->[0],$bins_colors->[1],$FONT_PATH);

	# KML must be rendered to disk
	my ($tmp_fh,$tmp_fn) = tempfile();
	_generate_kml($entities,$placename,$datadesc,$nbins,
		      $bins_colors->[0],$bins_colors->[1],$tmp_fh,$legend_name);
	close($tmp_fh);

	# Construct the KMZ/ZIP archive and add the kml and legend files
	my $kmz = Archive::Zip->new();
	#my $kml_member = $kmz->addString(join("",@$kml),"generated_map.kml");
	my $kml_member = $kmz->addFile($tmp_fn,"generated_map.kml");
		$kml_member->desiredCompressionMethod( COMPRESSION_DEFLATED );
	my $leg_member = $kmz->addString($$legend,$legend_name);
		$leg_member->desiredCompressionMethod( COMPRESSION_STORED );
	
	# Dump the zip data to the file
	#my $kmz_fh;
	#open($kmz_fh,">$kmzname") or die "Couldn't create output file in generate_kmz";
	if ($kmz->writeToFileHandle($kmzfh) != AZ_OK) {
		die "Couldn't write to output file in generate_kmz";
	}
	#close($kmzfh);
	unlink($tmp_fn);
	return;
}
sub _kmeans {
	my ($data,$clusters,$npass) = @_;
	if ($clusters > scalar(@$data)) {
		warn "More clusters ($clusters) than data points (".scalar(@$data).")!";
		my @result;
		for (my $i=0;$i < scalar(@$data); $i++) {
			push (@result,$i);
		}
		return \@result;
	}
	
	my %cluster_centroids = ();
	for (my $i=0; $i < $clusters; $i++) {
		my $idx;
		do {
			$idx = int(rand(scalar(@$data)));
		} while (defined($cluster_centroids{$idx}));
		$cluster_centroids{$idx} = 1;
	}
	
	my $rcenters = [];
	foreach my $cent (keys %cluster_centroids) {
		push (@$rcenters,$data->[$cent]);
	}
	
	#Assign points to clusters
	my $assn = assign_clusters($data,$rcenters);
	
	for (;$npass>0;$npass--) {
		#Recalculate centroids
		$rcenters = recalculate_centroids($data,$rcenters,$assn);
		#Assign points to clusters
		my $newassn = assign_clusters($data,$rcenters);
		
		# End the iterations if the assignments don't change		
		my $done = 1;
		for (my $i = 0;$i<scalar(@$newassn) and $done; $i++) {
			$done = ($assn->[$i] == $newassn->[$i])
		}
		if ($done) {
			$npass = 0;
		} else {
			$assn = $newassn;
		}
	}
	return $assn;
}

sub assign_clusters {
	my ($data,$centroids) = @_;
	my @assn=();
	$#assn = scalar(@$data)-1;
	for (my $di = 0; $di < scalar(@$data); $di++) {
		my $pt = $data->[$di];
		my $dist = abs($pt-$centroids->[0]);
		my $idx = 0;
		for (my $i=1;$i<scalar(@$centroids);$i++) {
			my $d2 = abs($pt-$centroids->[$i]);
			if ($d2 < $dist) {
				$dist = $d2;
				$idx = $i;
			}
		}
		$assn[$di] = $idx;
	}
	
	# This inverted loop loses on performance
	#my @dists;
	#for (my $c=0;$c<scalar(@$centroids);$c++) {
	#	for (my $i=0;$i<scalar(@$data);$i++) {
	#		my $dist = abs($data->[$i]-$centroids->[$c]);
	#		if (not defined($dists[$i]) or ($dists[$i] > $dist)) {
	#			$dists[$i] = $dist;
	#			$assn[$i] = $c;
	#		}
	#	}
	#}
	
	return \@assn;
}

sub recalculate_centroids {
	my ($data,$centroids,$assignments) = @_;
	
	my @means;
	my @counts;
	for (my $c=0;$c<scalar(@$centroids);$c++) {
		push(@means,0);
		push(@counts,0);
	}
	for (my $i = 0;$i < scalar(@$data);$i++) {
		my $t = $assignments->[$i];
		$means[$t] += $data->[$i];
		$counts[$t]++;
	}
	for (my $i=0;$i<scalar(@means);$i++) {
		$means[$i] /= $counts[$i] if ($counts[$i]!=0);
	}
	return \@means;
}

END {}
1;


=pod

=head1 TIPS

=head2 Chunk size in Archive::Zip

I've found that changing the chunk size ($ChunkSize) in the Archive::Zip module from the default 32K (32768) to around 128K (131072)
can really speed up KMZ generation, especially for really big maps. To do this, change the line

	$ChunkSize=32768;

in Zip.pm to:

	$ChunkSize=131072;

=head1 AUTHOR

Imran Haque, ihaque@cs.stanford.edu

=head1 COPYRIGHT AND LICENSE

This module is Copyright 2007, Imran Haque, ihaque@cs.stanford.edu.

You may modify and/or redistribute this module under the same terms as Perl itself.

=cut
