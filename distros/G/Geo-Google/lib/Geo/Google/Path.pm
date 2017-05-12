package Geo::Google::Path;
use strict;
use warnings;
use Data::Dumper;
use URI::Escape;
use Geo::Google;
our $VERSION = '0.04-rc3';

use constant FMT => <<_FMT_;
<segments distance="%s" time="%s">
%s</segments>
_FMT_

#<segments distance="0.6&#160;mi" meters="865" seconds="56" time="56 secs">
#  <segment distance="0.4&#160;mi" id="seg0" meters="593" pointIndex="0" seconds="38" time="38 secs">Head <b>southwest</b> from <b>Venice Blvd</b></segment>
#  <segment distance="0.2&#160;mi" id="seg1" meters="272" pointIndex="6" seconds="18" time="18 secs">Make a <b>U-turn</b> at <b>Venice Blvd</b></segment>
#</segments>

sub new {
  my $class = shift;
  my %arg = @_;
  my $self = bless \%arg, $class;
}

sub distance { return shift->{'distance'} }
sub polyline { return shift->{'polyline'} }
sub segments { my $self = shift; return $self->{'segments'} ? @{ $self->{'segments'} } : () }
sub time     { return shift->{'time'} }
sub locations { my $self = shift; return $self->{'locations'} ? @{ $self->{'locations'} } : () }
sub panel    { return shift->{'panel'} }
sub levels   { return shift->{'levels'} }

sub toXML {
  my $self = shift;
  my $content = join "", map { $_->toXML } @{ $self->{segments} };
  return sprintf( FMT,
    $self->distance(),
    $self->time(),
    $content,
  );
}

sub toJSON {
	my $self = shift;
	my $json = new JSON (barekey => 1);

	# Construct the shell of a new perl data structure that we
	# can pass off to the JSON module for rendering to a string
	my $preJSON = Geo::Google::_JSONrenderSkeleton();

	# Fill the perl data structure with information from this
	# location
	my @locations = $self->locations();
	$preJSON->{"form"}->{"l"}->{"near"} = 
				$locations[$#locations]->title();
	$preJSON->{"form"}->{"q"}->{"q"} = "from:" . 
					$locations[0]->title();
	for (my $i=1; $i<=$#locations; $i++) {
		$preJSON->{"form"}->{"q"}->{"q"} .= " to:" .
			$locations[$i]->title();
	}
	$preJSON->{"form"}->{"d"}->{"saddr"} = $locations[0]->title();
	$preJSON->{"form"}->{"d"}->{"daddr"} = $locations[1]->title();
	for (my $i=2; $i<=$#locations; $i++) {
		$preJSON->{"form"}->{"d"}->{"daddr"} .= " to:" .
			$locations[$i]->title();
	}
	$preJSON->{"form"}->{"selected"} = "q";
	$preJSON->{"panelStyle"} = "";
	# Generate the markers
	for (my $i=0; $i<=$#locations; $i++) {
		my $image = "/mapfiles/dd-pause.png";
		my $id = "pause";
		if ($i == 0 ) {
			$image = "/mapfiles/dd-start.png";
			$id = "start";
		}
		elsif ($i == $#locations) {
			$image = "/mapfiles/dd-stop.png";
			$id = "stop";
		}
		push( @{$preJSON->{"overlays"}->{"markers"}}, {
			"laddr" => "",
			"svaddr" => "",
			"lat" => $locations[$i]->latitude(),
			"lng" => $locations[$i]->longitude(),
			"id" => $id,
			"image" => $image,
			"elms" => [()],
			"llcid" => "",
			"fid" => "",
			"cid" => "",
			"sig" => "",
			"infoWindow" => {
				"type" => "map",
				"_" => 0
				}
			});
	}
	$preJSON->{"overlays"}->{"polylines"}->[0]->{"levels"} =
		$self->levels();
	$preJSON->{"overlays"}->{"polylines"}->[0]->{"points"} =
		$self->polyline();	
	$preJSON->{"overlays"}->{"polylines"}->[0]->{"outline"} = undef;
	$preJSON->{"overlays"}->{"polylines"}->[0]->{"opacity"} = undef;
	$preJSON->{"overlays"}->{"polylines"}->[0]->{"color"} = undef;
	$preJSON->{"overlays"}->{"polylines"}->[0]->{"weight"} = undef;
	$preJSON->{"overlays"}->{"polylines"}->[0]->{"id"} = "d";
	$preJSON->{"overlays"}->{"polylines"}->[0]->{"numLevels"} = 4;
	$preJSON->{"overlays"}->{"polylines"}->[0]->{"zoomFactor"} = 16;
	$preJSON->{"printheader"} = sprintf("Directions from %s to %s"
					. "<BR />Travel time: %s", 
					$locations[0]->title(),
					$locations[$#locations]->title(),
					$self->time());
	$preJSON->{"modules"} = [(undef, "multiroute")];
	$preJSON->{"panelResizeState"} = "open";
	# step through all points in the directions and determine
	# the maximum and minimum lat/longs
	my $maxlat = -90;
	my $minlat = 90;
	my $maxlng = -180;
	my $minlng = 180;
	foreach my $segment ($self->segments()) {
		foreach my $point ($segment->points()) {
			if ($point->latitude() > $maxlat) 
				{ $maxlat = $point->latitude(); }
			if ($point->latitude() < $minlat) 
				{ $minlat = $point->latitude(); }
			if ($point->longitude() > $maxlng) 
				{ $maxlng = $point->longitude(); }
			if ($point->longitude() < $minlng) 
				{ $minlng = $point->longitude(); }
		}
	}
	$preJSON->{"viewport"}->{"span"}->{"lat"} = sprintf("%.6f",
		( ($maxlat-$minlat) * 1.1) );
	$preJSON->{"viewport"}->{"span"}->{"lng"} = sprintf("%.6f", 
		( ($maxlng-$minlng) * 1.1) );		
	$preJSON->{"viewport"}->{"center"}->{"lat"} = sprintf("%.6f", 
		( ($maxlat+$minlat) / 2) );
	$preJSON->{"viewport"}->{"center"}->{"lng"} = sprintf("%.6f",
		( ($maxlng+$minlng) / 2) );
	$preJSON->{"viewport"}->{"mapType"} = undef;
	$preJSON->{"url"} = "/maps?v=1&q=" . 
				uri_escape(sprintf("from:%s to:%s",
					$locations[0]->title(), 
					$preJSON->{"form"}->{"d"}->{"daddr"}))
				. "&ie=UTF8";
	$preJSON->{"title"} = sprintf("From:%s to:%s", 
				$locations[0]->title(),
				$preJSON->{"form"}->{"d"}->{"daddr"});
	$preJSON->{"panel"} = $self->panel();

	# Render the data structure to a JSON string and return it
	return $json->objToJson($preJSON);
}

1;
__END__
 Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Geo::Google::Path - A path, by automobile, between two loci.

=head1 SYNOPSIS

  use Geo::Google::Path;
  # you shouldn't need to construct these yourself,
  # have a Geo::Google object do it for you.

=head1 DESCRIPTION

Google Maps is able to serve up directions between two points.  Directions
consist of two types of components:

  1. a series of points along a "polyline".
  2. a series of annotations, each of which applies to a contiguous
  range of points.

In the Geo::Google object model, directions are available by calling path()
on a Geo::Google instance.  The return value is a Geo::Google::Path object,
which is a composite of Geo::Google::Segment objects, which are in turn
composites of Geo::Google::Location objects.

=head1 OBJECT METHODS

Geo::Google::Path objects provide the following accessor methods

 Method      Description
 ------      -----------
 distance    length of the segment, in variable, human friendly units.
 polyline    a string encoding the points in the path.
 levels      a string containing information used for rendering the 
             polyline in an application like Google Maps.
 panel       HTML+JavaScript version of the driving directions for
             use in an AJAX application.  Google Maps uses this
             data in the left hand panel of a directions search.
 segments    a list of Geo::Google::Segment segments along the path.
             a segment has 0..1 driving directions associated with it.
 time        a time estimate, in variable, human-friendly units for how long
             the segment will take to travel by automobile.
 locations   an array of Geo::Google::Location objects containing 
             the start point (element 0 of the array), the final
             destination (the last element of the array), and any 
             waypoints between them that were used in the directions
             query.  There will always be at least two elements in
             this array (start point and final destination).  
 toXML       a method that renders the path in XML that could be used as 
             part of a Google Earth KML file.
 toJSON      a method that renders the path in JSON that could be used 
             with Google Maps.

=head1 SEE ALSO

L<Geo::Google>

=head1 AUTHOR

Allen Day E<lt>allenday@ucla.eduE<gt>, Michael Trowbridge 
E<lt>michael.a.trowbridge@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2007 Allen Day.  All rights
reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
