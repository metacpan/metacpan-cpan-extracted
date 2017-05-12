=head1 NAME

HTML::GoogleMaps - a simple wrapper around the Google Maps API

=head1 SYNOPSIS

  use HTML::GoogleMaps

  $map = HTML::GoogleMaps->new(key => $map_key);
  $map->center("1810 Melrose St, Madison, WI");
  $map->add_marker(point => "1210 W Dayton St, Madison, WI");
  $map->add_marker(point => [ 51, 0 ] );   # Greenwich
 
  my ($head, $map_div) = $map->onload_render;

=head1 NOTE

This version is not API compatable with HTML::GoogleMaps versions 1
and 2.  The render method now returns three values instead of two.

=head1 DESCRIPTION

HTML::GoogleMaps provides a simple wrapper around the Google Maps
API.  It allows you to easily create maps with markers, polylines and
information windows.  Thanks to Geo::Coder::Google you can now look
up locations around the world without having to install a local database.

=head1 CONSTRUCTOR

=over 4

=item $map = HTML::GoogleMaps->new(key => $map_key);

Creates a new HTML::GoogleMaps object.  Takes a hash of options.  The
only required option is I<key>, which is your Google Maps API key.
You can get a key at http://maps.google.com/apis/maps/signup.html .
Other valid options are:

=over 4

=item height => height (in pixels or using your own unit)

=item width => width (in pixels or using your own unit)

=back

=back

=head1 METHODS

=over 4

=item $map->center($point)

Center the map at a given point.

=item $map->v2_zoom($level)

Set the new zoom level (0 is corsest)

=item $map->controls($control1, $control2)

Enable the given controls.  Valid controls are: B<large_map_control>,
B<small_map_control>, B<small_zoom_control> and B<map_type_control>.

=item $map->dragging($enable)

Enable or disable dragging.

=item $map->info_window($enable)

Enable or disable info windows.

=item $map->map_type($type)

Set the map type.  Either B<normal>, B<satellite> or B<hybrid>.  The
v1 API B<map_type> or B<satellite_type> still work, but may be dropped
in a future version.

=item $map->map_id($id)

Set the id of the map div

=item $map->add_icon(name => $icon_name,
                     image => $image_url,
                     shadow => $shadow_url,
                     icon_size => [ $width, $height ],
                     shadow_size => [ $width, $height ],
                     icon_anchor => [ $x, $y ],
                     info_window_anchor => [ $x, $y ]);

Adds a new icon, which can later be used by add_marker.  All args
are required except for info_window_anchor.

=item $map->add_marker(point => $point, html => $info_window_html)

Add a marker to the map at the given point. A point can be a unique
place name, like an address, or a pair of coordinates passed in as
an arrayref: [ longituded, latitude ].

If B<html> is specified,
add a popup info window as well.  B<icon> can be used to switch to
either a user defined icon (via the name) or a standard google letter
icon (A-J).

Any data given for B<html> is placed inside a 350px by 200px div to
make it fit nicely into the Google popup.  To turn this behavior off 
just pass B<noformat> => 1 as well.

=item $map->add_polyline(points => [ $point1, $point2 ])

Add a polyline that connects the list of points.  Other options
include B<color> (any valid HTML color), B<weight> (line width in
pixels) and B<opacity> (between 0 and 1).

=item $map->render

B<DEPRECATED -- please use onload_render intead, it will give you
better javascript.>

Renders the map and returns a three element list.  The first element
needs to be placed in the head section of your HTML document.  The
second in the body where you want the map to appear.  The third (the 
Javascript that controls the map) needs to be placed in the body,
but outside any div or table that the map lies inside of.

=item $map->onload_render

Renders the map and returns a two element list.  The first element
needs to be placed in the head section of your HTML document.  The
second in the body where you want the map to appear.  You will also 
need to add a call to html_googlemaps_initialize() in your page's 
onload handler.  The easiest way to do this is adding it to the body
tag:

    <body onload="html_googlemaps_initialize()">

=back

=head1 SEE ALSO

L<http://www.google.com/apis/maps>
L<http://geocoder.us>

=head1 AUTHORS

Nate Mueller <nate@cs.wisc.edu>

=cut

package HTML::GoogleMaps;

use strict;
use Geo::Coder::Google;

our $VERSION = 10;

sub new {
  my ($class, %opts) = @_;

  die "Need a map key?  Go to http://www.google.com/apis/maps/signup.html\n"
    unless $opts{key};

  if ($opts{db}) {
    require Geo::Coder::US;
    Geo::Coder::US->set_db($opts{db});
  }
    
  bless {
    %opts,
    points => [],
    poly_lines => [],
    geocoder => Geo::Coder::Google->new(apikey => $opts{key}),
  }, $class;
}

sub _text_to_point {
  my ($this, $point_text) = @_;

  # IE, already a long/lat pair
  return [reverse @$point_text] if ref($point_text) eq "ARRAY";

  # US street address
  if ($this->{db}) {
    my ($point) = Geo::Coder::US->geocode($point_text);
    if ($point->{lat}) {
      return [$point->{lat}, $point->{long}];
    }
  } else {
    my $location = $this->{geocoder}->geocode(location => $point_text);
    return [
      $location->{Point}{coordinates}[1],
      $location->{Point}{coordinates}[0],
    ];
  }
  
  # Unknown
  return 0;
}

sub _find_center {
  my ($this) = @_;

  # Null case
  return unless @{$this->{points}};

  my $total_lat;
  my $total_long;
  my $total_abs_long;
  foreach my $point (@{$this->{points}}) {
    $total_lat += $point->{point}[0];
    $total_long += $point->{point}[1];
    $total_abs_long += abs($point->{point}[1]);
  }
    
  # Latitude is easy, just an average
  my $center_lat = $total_lat/@{$this->{points}};
    
  # Longitude, on the other hand, is trickier.  If points are
  # clustered around the international date line a raw average
  # would produce a center around longitude 0 instead of -180.
  my $avg_long = $total_long/@{$this->{points}};
  my $avg_abs_long = $total_abs_long/@{$this->{points}};
  return [ $center_lat, $avg_long ] # All points are on the
    if abs($avg_long) == $avg_abs_long; # same hemasphere

  if ($avg_abs_long > 90) {      # Closer to the IDL
    if ($avg_long < 0 && abs($avg_long) <= 90) {
      $avg_long += 180;
    } elsif (abs($avg_long) <= 90) {
      $avg_long -= 180;
    }
  }

  return [$center_lat, $avg_long];
}

sub center {
  my ($this, $point_text) = @_;

  my $point = $this->_text_to_point($point_text);
  return 0 unless $point;
    
  $this->{center} = $point;
  return 1;
}

sub zoom {
  my ($this, $zoom_level) = @_;

  $this->{zoom} = 17-$zoom_level;
}

sub v2_zoom {
  my ($this, $zoom_level) = @_;

  $this->{zoom} = $zoom_level;
}

sub controls {
  my ($this, @controls) = @_;

  my %valid_controls = map { $_ => 1 } qw(large_map_control
    small_map_control
    small_zoom_control
    map_type_control);
  return 0 if grep { !$valid_controls{$_} } @controls;

  $this->{controls} = [ @controls ];
}

sub dragging {
  my ($this, $dragging) = @_;

  $this->{dragging} = $dragging;
}

sub info_window {
  my ($this, $info) = @_;

  $this->{info_window} = $info;
}

sub map_type {
  my ($this, $type) = @_;

  my %valid_types = (map_type => 'G_NORMAL_MAP',
    satellite_type => 'G_SATELLITE_MAP',
    normal => 'G_NORMAL_MAP',
    satellite => 'G_SATELLITE_MAP',
    hybrid => 'G_HYBRID_MAP');
  return 0 unless $valid_types{$type};

  $this->{type} = $valid_types{$type};
}

sub map_id {
  my ($this, $id) = @_;
  $this->{id} = $id;
}

sub add_marker {
  my ($this, %opts) = @_;
    
  return 0 if $opts{icon} && $opts{icon} !~ /^[A-J]$/
    && !$this->{icon_hash}{$opts{icon}};

  my $point = $this->_text_to_point($opts{point});
  return 0 unless $point;

  push @{$this->{points}}, { point => $point,
    icon => $opts{icon},
    html => $opts{html},
    format => !$opts{noformat} };
}

sub add_icon {
  my ($this, %opts) = @_;

  return 0 unless $opts{image} && $opts{shadow} && $opts{name};
    
  $this->{icon_hash}{$opts{name}} = 1;
  push @{$this->{icons}}, \%opts;
}

sub add_polyline {
  my ($this, %opts) = @_;

  my @points = map { $this->_text_to_point($_) } @{$opts{points}};
  return 0 if grep { !$_ } @points;

  push @{$this->{poly_lines}}, { points => \@points,
    color => $opts{color} || "\#0000ff",
    weight => $opts{weight} || 5,
    opacity => $opts{opacity} || .5 };
}

sub onload_render {
  my ($this) = @_;

  # Add in all the defaults
  $this->{id} ||= 'map';
  $this->{height} ||= '400px';
  $this->{width} ||= '600px';
  $this->{dragging} = 1 unless defined $this->{dragging};
  $this->{info_window} = 1 unless defined $this->{info_window};
  $this->{type} ||= "G_NORMAL_MAP";
  $this->{zoom} ||= 13;
  $this->{center} ||= $this->_find_center;

  if ( $this->{width} =~ m/^\d+$/ ) {
      $this->{width} .= 'px';
  }
  if ( $this->{height} =~ m/^\d+$/ ) {
      $this->{height} .= 'px';
  }

  my $header = sprintf(
    '<script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=%s" '
      . 'type="text/javascript"></script>',
    $this->{key},
  );
  my $map = sprintf(
    '<div id="%s" style="width: %s; height: %s"></div>',
    $this->{id},
    $this->{width},
    $this->{height},
  );

  $header .= <<SCRIPT;
<script type=\"text/javascript\">
    //<![CDATA[
  function html_googlemaps_initialize() {    
    if (GBrowserIsCompatible()) {
      var map = new GMap2(document.getElementById("$this->{id}"));
SCRIPT
  $header .= "      map.setCenter(new GLatLng($this->{center}[0], $this->{center}[1]));\n"
    if $this->{center};
  $header .= "      map.setZoom($this->{zoom});\n"
    if $this->{zoom};

  $header .= "      map.setMapType($this->{type});\n";

  if ($this->{controls}) {
    foreach my $control (@{$this->{controls}}) {
      $control =~ s/_(.)/uc($1)/ge;
      $control = ucfirst($control);
      $header .= "      map.addControl(new G${control}());\n";
    }
  }
  unless ($this->{dragging}) {
    $header .= "      map.disableDragging();\n";
  }

  # Add in "standard" icons
  my %icons = map { $_->{icon} => 1 } 
    grep { defined $_->{icon} && $_->{icon} =~ /^([A-J])$/; } 
      @{$this->{points}};
  foreach my $icon (keys %icons) {
    $header .= "      var icon_$icon = new GIcon();
      icon_$icon.shadow = \"http://www.google.com/mapfiles/shadow50.png\";
      icon_$icon.iconSize = new GSize(20, 34);
      icon_$icon.shadowSize = new GSize(37, 34);
      icon_$icon.iconAnchor = new GPoint(9, 34);
      icon_$icon.infoWindowAnchor = new GPoint(9, 2);
      icon_$icon.image = \"http://www.google.com/mapfiles/marker$icon.png\";\n\n"
  }

  # And the rest
  foreach my $icon (@{$this->{icons}}) {
    $header .= "      var icon_$icon->{name} = new GIcon();\n";
    $header .= "      icon_$icon->{name}.shadow = \"$icon->{shadow}\"\n"
      if $icon->{shadow};
    $header .= "      icon_$icon->{name}.iconSize = new GSize($icon->{icon_size}[0], $icon->{icon_size}[1]);\n"
      if ref($icon->{icon_size}) eq "ARRAY";
    $header .= "      icon_$icon->{name}.shadowSize = new GSize($icon->{shadow_size}[0], $icon->{shadow_size}[1]);\n"
      if ref($icon->{shadow_size}) eq "ARRAY";
    $header .= "      icon_$icon->{name}.iconAnchor = new GPoint($icon->{icon_anchor}[0], $icon->{icon_anchor}[1]);\n"
      if ref($icon->{icon_anchor}) eq "ARRAY";
    $header .= "      icon_$icon->{name}.infoWindowAnchor = new GPoint($icon->{info_window_anchor}[0], $icon->{info_window_anchor}[1]);\n"
      if ref($icon->{info_window_anchor}) eq "ARRAY";
    $header .= "      icon_$icon->{name}.image = \"$icon->{image}\";\n\n";
  }

  my $i;
  foreach my $point (@{$this->{points}}) {
    $i++;

    my $icon = '';
    if (defined $point->{icon}) {
      $point->{icon} =~ s/(.+)/icon_$1/;
      $icon = ", $point->{icon}";
    }

    my $point_html = $point->{html};
    if ($point->{format} && $point->{html}) {
      $point_html = sprintf(
        '<div style="width:350px;height:200px;">%s</div>',
        $point->{html},
      );
    }

    $header .= "      var marker_$i = new GMarker(new GLatLng($point->{point}[0], $point->{point}[1]) $icon);\n";
    if ( $point->{html} ) {
        $point_html =~ s/'/\\'/g;
    $header .= "      GEvent.addListener(marker_$i, \"click\", function () {  marker_$i.openInfoWindowHtml('$point_html'); });\n"
    }
    $header .= "      map.addOverlay(marker_$i);\n";
  }

  $i = 0;
  foreach my $polyline (@{$this->{poly_lines}}) {
    $i++;
    my $points = "[" . join(", ", map { "new GLatLng($_->[0], $_->[1])" } @{$polyline->{points}}) . "]";
    $header .= "      var polyline_$i = new GPolyline($points, \"$polyline->{color}\", $polyline->{weight}, $polyline->{opacity});\n";
    $header .= "      map.addOverlay(polyline_$i);\n";
  }

  $header .= "    }
  }
    //]]>
    </script>";

  return ($header, $map);
}

sub render {
  my ($this) = @_;
  my ($header, $map) = $this->onload_render;
  ($header, my $text) = split(/\n/, $header, 2);
  $text =~ s/(.*})/$1\n  html_googlemaps_initialize();/s;

  return ($header, $map, $text);
}

1;
