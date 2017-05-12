package Geo::Google::MapObject;

use warnings;
use strict;
use Carp;

=head1 NAME

Geo::Google::MapObject - Code to help with managing the server side of the Google Maps API

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use HTML::Template::Pluggable;
    use HTML::Template::Plugin::Dot;
    use Geo::Google::MapObject;
    my $map = Geo::Google::MapObject->new(
        key => 'ABQFbHAATHwok56Qe3MBtg0s7lgkHBS9HKneet7v0OIFhIwnBhTEGCHLTRRRBa_lUOCy1fDamS5PQt8qULYfYQ',
        zoom => 13,
        size => '512x400',
        maptype => 'terrain',
        markers=>
        [
                {
			location=>'51.242844,0.011716',
			color=>'green',
			label=>'P',
			title=>'Periapt Technologies',
			href=>'http://www.periapt.co.uk'
		},
                {
			location=>'51.243757,0.006051',
			color=>'red',
			label=>'C',
			title=>'Crown Roast Butchers',
			href=>'http://www.crownroast.co.uk/'
		},
        ]
    );
    my $template = HTML::Template::Pluggable->new(file=>'map.tmpl');
    $template->param(map=>$map);
    return $template->output;
  
=head1 DESCRIPTION

This module is intended to provide a server side solution to working with the Google Maps API.
In particular an object of this class encapsulates a "map" object that provides support
for the static maps API, the javascript maps API, AJAX calls and non-javascript fallback data;
but without making many assumptions about the surrounding framework.
We do assume that a template framework with support for a "dot" notation is being used, for example L<HTML::Template::Pluggable>.
An important commitment of the module is support for graceful and consistent fallback to a functional non-javascript web page.

The javascript and static Google map APIs do not behave in quite the same way when zoom and center are not specified.
Specifically it works quite well with the static maps (L<http://code.google.com/apis/maps/documentation/staticmaps/#ImplicitPositioning>)
but not so well with the javascript API.
To compensate for this the module gives a choice between: specifying the center and zoom levels; allowing the APIs and client side code to
do whatever they think best; using a built in algorithm to calculate a sensible zoom and center; and finally supplying ones
own algorithm to calculate a sensible zoom and center.

=head1 INTERFACE 

=head2 new

Supported arguments are

=over

=item autozoom 

If no center and/or zoom is specified this parameter can be used to calculate suitable
values by a process of averaging the markers. If this parameter is an integer between 0
and 21 then that number is taken as a maximum zoom level and the builtin
algorithm, C<< calculate_zoom_and_center >>, is used with that maximum zoom level.
If the parameter is a CODE ref, then that function is used instead. The CODE ref must
take an ARRAY ref of marker specifications as an input, and must return a pair consisting of the zoom
level as an integer followed by a latitude-longitude string representing the center.
Finally if the argument is blessed and has a C<< calculate_zoom_and_center >> method,
that will be used.  For AUTO calculation of the center or zoom all
the markers must be in the form "decimal,decimal". The C<< json >> method will delete this
as it has no meaning once the zoom level and center have been determined.

=item center

This must be a location that would be recognized by the Google maps API.
If absent, and if no autozoom has been set, the Google maps API and client side javascript code 
must between them work out a center.

=item zoom

This represents the zoom level (L<http://code.google.com/apis/maps/documentation/staticmaps/#Zoomlevels>), which
is a number between 0 and 21 inclusive. If absent (with no autozoom set) the API and client will need to set it. 

=item size

The size (L<http://code.google.com/apis/maps/documentation/staticmaps/#Imagesizes>) must either be a string
consisting of two numbers joined by the symbol C<x>, or a hash ref with width and height parameters. In either
case the first number is the width and the second the height. If absent the Google API will be allowed to set
the size as it sees fit.

=item format

The optional format (L<http://code.google.com/apis/maps/documentation/staticmaps/#ImageFormats>) must be one of 
'png8',  'png', 'png32', 'gif', 'jpg', 'jpg-baseline'. If absent the Google API will be allowed to set
the format as it sees fit. Note that although the C<< json >> method will pass this on, it seems to have no meaning
in the dynamic API.

=item maptype

This must be one of the following: 'roadmap', 'satellite', 'terrain', 'hybrid's described in L<http://code.google.com/apis/maps/documentation/staticmaps/#MapTypes>. The C<< json >> method will translate these into numerical codes roadmap => 0, satellite => 1, terrain => 2 and hybrid => 3
as this makes it easy for the javascript code (L<http://code.google.com/apis/maps/documentation/reference.html#GMapType.Constants>) to translate this numerical code into the client side codes. For example:

  var mapping = new Array(G_NORMAL_MAP, G_SATELLITE_MAP, G_PHYSICAL_MAP, G_HYBRID_MAP);
  var maptype = mapping[data.maptype];

=item mobile

This parameter should be either the string 'true' or 'false' and defaults to 'false'. The static API uses it to provide more
robust tiles as described in L<http://code.google.com/apis/maps/documentation/staticmaps/#Mobile>. However it seems to have no meaning 
for the dynamic API.

=item key

The mandatory API key. You can sign up for one at L<http://code.google.com/apis/maps/signup.html>.

=item sensor

This parameter should be either the string 'true' or 'false' and defaults to 'false'. Both versions of the Google API
require it (L<http://code.google.com/apis/maps/documentation/staticmaps/#Sensor>) and this is reflected in this module
by it being used by the C<< static_map_url >> and C<< javascript_url >> methods.

=item markers

If present the markers should be an array ref of marker specifications so that it can be used in a TMPL_LOOP.
Each marker specification should be a hash ref and may contain whatever keys are required
by the javascript client side code. It must however have a C<< location >> field which must be interpretable
by the Google API as a location. In general this means the location must be a string of the form "decimal,decimal",
where the first decimal is the latitude and the second longitude.
Other fields might include for example: id, title, href, icon. Generally these just get passed through by the C<< json >>
method and should be used by the client side code as it sees fit.
Three fields that have a special meaning, C<< color >>, C<< size >>, C<< label >> are those described by the static maps API
(L<http://code.google.com/apis/maps/documentation/staticmaps/#MarkerStyles>). 
The GIcon class (L<http://code.google.com/apis/maps/documentation/reference.html#GIcon>) contains lots of ways of specialising
the look and feel of the markers in the dynamic API; but I can find no easy way of consistently replicating the 
the static marker styles in the dynamic API. The only other field which gets special treatment is C<< title >>. The C<< json >>
method will encode the title field. So for example if a marker has a title field of C<< 'Sclo&szlig;' >>, then
if the javascript code uses this as the title attribute when creating a GMarker, then hovering the mouse over that marker
will display the German word for castle.

=item hl

This parameter specifies the language to be used. If absent the API will select the language. Only the dynamic javascript API
seems to use this parameter as described in L<http://code.google.com/apis/maps/documentation/#Localization>. As such this
is used in the C<< javascript_url >> method.

=back

=cut

my %MAPTYPE = (
        roadmap=>0,
        satellite=>1,
        terrain=>2,
        hybrid=>3,
);

sub new {
    my $class = shift;
    my %args = @_;
    $args{mobile} = 'false' unless exists $args{mobile} && $args{mobile} eq 'true';
    $args{sensor} = 'false' unless exists $args{sensor} && $args{sensor} eq 'true';
    if (exists $args{markers}) {
        croak "markers should be an ARRAY" unless ref($args{markers}) eq "ARRAY";
    }
    croak "no API key" unless exists $args{key};
    if (exists $args{markers} && exists $args{autozoom}) {
	my ($zoom, $center) = _autocalculate(%args);
	$args{zoom} ||= $zoom;
	$args{center} ||= $center;
	delete $args{autozoom};
    }
    if (exists $args{zoom}) {
        croak "zoom not a number: $args{zoom}" unless ($args{zoom} =~ /^\d{1,2}$/) && $args{zoom} < 22;
    }
    if (exists $args{maptype}) {
	croak "maptype $args{maptype} not recognized" unless exists $MAPTYPE{$args{maptype}};
    }
    if (exists $args{size}) {
	my ($width, $height) = _parse_size($args{size});
	$args{size} = {width=>$width,height=>$height};
    }
    return bless \%args, $class;
}

sub _parse_size {
    my $size = shift;
    my ($width, $height);
    if (ref($size) eq "HASH") {
        $width = $size->{width} || croak "no width";
        $height = $size->{height} || croak "no height";
    }
    elsif($size =~ /^(\d{1,3})x(\d{1,3})$/) {
        $width = $1;
        $height = $2;
    }
    else {
        croak "cannot recognize size";
    }
    croak "width should positive and be no more than 640" unless ($width > 0 && $width <= 640);
    croak "height should positive and be no more than 640" unless ($height > 0 && $height <= 640);
    return ($width, $height);
}

sub _autocalculate {
    my %args = @_;
    my $autozoom = $args{autozoom};
    my $markers = $args{markers} || croak "cannot calculate autozoom without markers";
    use Scalar::Util qw(blessed looks_like_number);
    if (looks_like_number($autozoom) && $autozoom >= 0 && $autozoom <= 21) {
	return calculate_zoom_and_center($markers, $autozoom);
    }
    elsif (ref($autozoom) eq "CODE") {
	return &$autozoom($markers);
    }
    elsif (blessed($autozoom) && $autozoom->can('calculate_zoom_and_center')) {
	return $autozoom->calculate_zoom_and_center($markers);
    }
    croak "$autozoom not recognized as autozoom";
}

=head2 calculate_zoom_and_center

This function tales a reference to an array of marker specifications
and a maximum zoom level and returns a pair consisting of a suggested zoom level
and a center.

The algorithm works by iteratively building the following objects:

=over

=item A set of points, starting with the first element of the array and adding the next one at each iteration.

Actually we don't actually have a variable for this, but without thinking about this set conceptually
I cannot state the algorithm. The set starts of consisting of just the first marker location.

=item C<< ($ctheta, $cphi) >>

These numbers represent a central point of the set of points represented as radians. The algorithm does not guarantee 
that the point is the true centre but we treat it as the centre of a circle. This starts of by taking the first element
and converting its latitude and longitude to radians.

=item C<< $radius >>

This variable is initialised to 0.

=item The contract

The algorithm requires that at each iteration all the points in the set are at most $radius radians from 
($ctheta, $cphi).

=item The iteration

We look at the next point. We look at the distance (C<< $distance >>) between the new point and C<< ($ctheta, $cphi) >>. If this is less than or 
equal to C<< $radius >> the iteration is over. Otherwise the following happens:

  ($ctheta, $cphi)	= mid point of ($ctheta, $cphi) and the new point
  $radius 		= $radius + 0.5 * distance between ($ctheta, $cphi) and the new point

=item At the end 

We convert C<< ($ctheta, $cphi) >> back to latitude and longitude and logarithmically convert the radius to a zoom level.

=back

I doubt that this algorithm is optimal but it seems quick, uses only one pass through the markers and can be seen in action
at L<http://testmaps.periapt.co.uk>. Also if you have a better one you can specify it by passing a suitable CODE ref or blessed
scalar to the C<< autozoom >> parameter of the constructor.

=cut

sub calculate_zoom_and_center {
    my $markers = shift;
    my $maxautozoom = shift;

    use Math::Trig qw(deg2rad great_circle_distance great_circle_midpoint rad2deg);
    # At the end we guarantee that any two points are less than $distance apart
    # and that ($ctheta, $cphi) is (more or less) in the middle.
    my ($ctheta, $cphi);
    my $distance = 0; # 2*$radius
    my $firstpoint = 1;

    foreach my $l (@{$markers}) {
	croak "location missing" unless exists $l->{location};
	if ($l->{location} =~  /^(\-?\d+\.?\d*),(\-?\d+\.?\d*)$/) {
		my $phi = deg2rad(90-$1);
		my $theta = deg2rad($2);

		if ($firstpoint) {
			$cphi = $phi;
			$ctheta = $theta;
			$firstpoint = 0;
		}
		else {
			my $new_distance = great_circle_distance($theta, $phi, $ctheta, $cphi);
			if ($new_distance > $distance) {
				$distance = $new_distance + $distance/2;
				my ($mtheta, $mphi) = great_circle_midpoint($theta, $phi, $ctheta, $cphi);
				if (defined $mtheta  && defined $mphi ) {
					$ctheta = $mtheta;
					$cphi = $mphi;
				}
				else {
					return (0, "0,0");
				}
			}
		}
	}
    }
    my $zoom = $maxautozoom;
    $zoom = int -(log $distance)/(log 2)  if $distance > 0;  ## no cr itic
    $zoom = 0 if $zoom < 0;
    $zoom = $maxautozoom if $zoom > $maxautozoom;
    my $longitude = rad2deg($ctheta);
    my $latitude = 90-rad2deg($cphi);
    return ($zoom, "$latitude,$longitude");
}

=head2 static_map_url

Returns a URL suitable for use with the static maps API based upon the arguments passed to the constructor.

=cut

sub static_map_url {
    my $self = shift;
    my $url = "http://maps.google.com/maps/api/staticmap?";
    my @params;

    # First the easy parameters
    foreach my $i (qw(center zoom format mobile key sensor)) {
        push @params, "$i=$self->{$i}" if exists $self->{$i};
    }
    push @params, "size=$self->{size}->{width}x$self->{size}->{height}" if exists $self->{size};

    if (exists $self->{markers}) {
        # Now sort the markers
        my %markers;
        foreach my $m (@{$self->{markers}}) {
                my @style;
                push @style, "color:$m->{color}" if exists $m->{color} && $m->{color} =~
				/^0x[A-F0-9]{6}|black|brown|green|purple|yellow|blue|gray|orange|red|white$/;
                push @style, "size:$m->{size}" if exists $m->{size} && $m->{size} =~ /^tiny|mid|small$/;
                push @style, "label:$m->{label}" if exists $m->{label} && $m->{label} =~ /^[A-Z0-9]$/;
                my $style = join "|", @style;
                push @{$markers{$style}},  $m->{location} || croak "no location for $style";
        }
        foreach my $m (sort keys %markers) {
                my $param = "markers=";
                $param .= "$m|" if $m;
                $param .= join '|', @{$markers{$m}};
                push @params, $param;
        }
    }

    $url .= join "&amp;", @params;
    return $url;
}

=head2 javascript_url

Returns a URL suitable for use in loading the dynamic map API.

=cut

sub javascript_url {
   my $self = shift;
   my $url = "http://maps.google.com/maps?file=api&amp;v=2&amp;key=$self->{key}&amp;sensor=$self->{sensor}";
   $url .= "&amp;hl=$self->{hl}" if exists $self->{hl};
   return $url;
}

=head2 markers

This returns the marker array ref.

=cut

sub markers {
    my $self = shift;
    return $self->{markers} || [];
}

=head2 json

This function uses the L<JSON> module to return a JSON representation of the object.
It removes the API key as that should not be required by any javascript client side code.
If any marker object has a title attribute, then that attribute is encoded so it will display
correctly during mouse overs.

=cut

sub json {
    my $self = shift;
    use JSON;
    my %args = %$self;
    delete $args{key};
    use HTML::Entities;
    $args{maptype} = $MAPTYPE{$args{maptype}} if exists $args{maptype};
    foreach my $i (0..$#{$args{markers}}) {
        $args{markers}[$i]->{title} = decode_entities($args{markers}[$i]->{title}) if exists $args{markers}[$i]->{title};
    }
    return to_json(\%args, {utf8 => 1, allow_blessed => 1});
}

=head2 width

This returns the width of the image or undef if none has been set.

=cut

sub width {
    my $self = shift;
    return undef unless exists $self->{size};
    return $self->{size}->{width};
}

=head2 height

This returns the height of the image or undef if none has been set.

=cut

sub height {
    my $self = shift;
    return undef unless exists $self->{size};
    return $self->{size}->{height};
}

=head1 TUTORIAL

This module only covers the server side of a two way conversation between server and a talkative client.
As such the tutorial must also consider HTML and javascript.
Also to understand this tutorial we assume at least passing familiarity with the following:

=over

=item L<HTML::Template::Pluggable> or some other templating framework using the "dot" notation.

=item The Google maps API: L<http://code.google.com/apis/maps/documentation/reference.html>.

=item The static Google maps API: L<http://code.google.com/apis/maps/documentation/staticmaps/>

=item Javascript, AJAX. Specifically we are using the yui framework (L<http://developer.yahoo.com/yui/2/>) though any other framework will do.

=back

=head2 The markup

We probably have a template file, map.tmpl, some thing like the following:

  
  <html>
    <head>
      <title>Test Map Tutorial</title>

      <!-- This way we tell the javascript what URL to contact the server with. -->
      <link href="/map_json" id="get_init_data"/>

      <!-- This will be filled in with the correct URL to load the Google maps javascript API. -->
      <script type="text/javascript" src="<TMPL_VAR NAME="maps.javascript_url()">"></script>

      <!-- This will load the yui API. If you use a different javascript API this would obviously change. -->
      <script type="text/javascript" src="http://yui.yahooapis.com/2.8.0r4/build/yahoo-dom-event/yahoo-dom-event.js"></script>
      <script type="text/javascript" src="http://yui.yahooapis.com/2.8.0r4/build/connection/connection.js"></script>
      <script type="text/javascript" src="http://yui.yahooapis.com/2.8.0r4/build/json/json-min.js"></script>

      <!-- This loads our javascript code. -->
      <script type="text/javascript" src="/js/maps.js"></script>
    </head>
    <body>

      <!-- This div will be completely replaced by the Google API and is identified by #map_canvas. -->
      <div id="map_canvas">

	<!-- This image will be loaded by the static Google map API. It will be available whilst the
		javascript based map is loading and if javascript is turned off
	-->
        <div><img
		alt="Test map"
		src="<TMPL_VAR NAME="maps.static_map_url()">"
		width="<TMPL_VAR NAME="maps.width()">"
		height="<TMPL_VAR NAME="maps.height()">"
		/>
	</div>

	<!-- The following will be used if javascript is disabled. 
	     We can use it display information that would normally be obtained by
	     hovering over or clicking on markers on the dynamic map display.
	-->
        <noscript>
             <table>
               <TMPL_LOOP NAME="maps.markers()">
                 <tr>
                   <td class="google_<TMPL_VAR NAME="this.color">"><TMPL_VAR NAME="this.label"></td>
                   <td>
                      <TMPL_IF NAME="this.href">
                      <a href="<TMPL_VAR NAME="this.href">">
                      </TMPL_IF>
                      <TMPL_VAR NAME="this.title">
                      <TMPL_IF NAME="this.href">
                      </a>
                      </TMPL_IF>
                    </td>
                 </tr>
               </TMPL_LOOP>
             </table>
        </noscript>

      </div> <!-- end of #map_canvas -->

    </body>
  </html>

=head2 The perl

The code to actually produce the web page must look something like this:

	use HTML::Template::Pluggable;
 	use HTML::Template::Plugin::Dot;
	use Geo::Google::MapObject;
 	my $t = HTML::Template::Pluggable->new(filename => 'map.tmpl');
	my $map = Geo::Google::MapObject->new(....);
	$t->param(maps=>$map);
	print $t->output;

This is all that would be needed in a javascript free environment. With javascript
enabled the client is going to ask for the same data in a JSON format (at least
we are only supporting JSON). The code to service that request will look something like:

	use Geo::Google::MapObject;
	my $map = Geo::Google::MapObject->new(....);
	print $map->json;

=head2 The javascript

As indicated in the markup above we are expecting the javascript to be in a file called maps.js.
We expect it to look something like the following:

  function mapInitialize() {

      /* Read the "link" element that tells us how to contact the server. See markup above. */
      var get_init_data = YAHOO.util.Dom.get('get_init_data').href;

      /* Build the AJAX callback object consisting of three parts.  */
      var callback =
      {

	  /* Part I: Function called in the event of a successful call. */
          success: function(o) {

		/* Convert the JSON response into a javascript object.
		   This structure corresponds to the Geo::Google::MapObject in perl
		   as intermediated by its "json" method.
		 */
                var data = YAHOO.lang.JSON.parse(o.responseText);

                if (GBrowserIsCompatible()) {

			/* Build up the Map object which will replace #map_canvas in the above markup. */
                        var mapopt = {};
                        if (data.size) {
                                mapopt.size = new GSize(parseInt(data.size.width), parseInt(data.size.height));
                        }
                        var markers = data.markers;
                        var map = new GMap2(YAHOO.util.Dom.get("map_canvas"), mapopt);
                        var maptype = null;
                        if (data.maptype) {
                                maptype = o.argument[parseInt(data.maptype)];
                        }
                        var zoom = null;
                        if (data.zoom) {
                                zoom = parseInt(data.zoom);
                        }
                        var center = markers[0].location;
                        if (data.center) {
                                center = data.center;
                        }
                        map.setCenter(GLatLng.fromUrlValue(center), zoom, maptype);
                        map.setUIToDefault();

			/* Now for each marker build and add a GMarker object */
                        for(var i = 0; i < markers.length; i++) {
	
                                var opt = {title: markers[i].title};
                                if (!markers[i].href) {
                                        opt.clickable = false;
                                }
                                if (markers[i].icon) {
                                        opt.icon = new GIcon(G_DEFAULT_ICON, markers[i].icon);
                                        if (markers[i].shadow) {
                                                opt.icon.shadow = markers[i].shadow;
                                        }
                                }
                                var mark = new GMarker(GLatLng.fromUrlValue(markers[i].location), opt);
                                if (markers[i].href) {
                                        mark.href = markers[i].href;
                                        GEvent.addListener(mark, "click", function(){window.location=this.href;});
                                }
                                map.addOverlay(mark);
                        }
                }
          },  /* End of Part I */

	  /* Part II: Function called in the event of failure */
	  failure: function(o) {alert(o.statusText);},

	  /* Part III: Data that is passed to the success function.
	     We are using this to map from numerical maptypes that Geo::Google::MapObject has passed us to the 
	     forms used in Google maps API. 
	   */
	  argument: [G_NORMAL_MAP, G_SATELLITE_MAP, G_PHYSICAL_MAP, G_HYBRID_MAP]

      }; /* End of constructing the AJAX callback object. */

      /* This calls the server which should hopefully kick off callback.success with lots of lovely data. */
      var transaction = YAHOO.util.Connect.asyncRequest('GET', get_init_data, callback, null);

  } /* end of mapInitialize function */

  /* This will make sure that we call the above function at a good time. */
  YAHOO.util.Event.onDOMReady(mapInitialize);

  /* We still have to do the memory cleanup ourselves. */
  YAHOO.util.Event.addListener(window, 'unload', 'GUnload');

=head2 Taking it further

There are lots of variations that can be done with this. The Geo::Google::MapObject object will pass
on all fields it does not recognize via the C<< json >> function and these can be used by the javascript
in whatever way required. Similarly fields added to the marker specification will be passed by the C<< markers >>
function and can be used in the template in whatever way required.

You can also make the markers draggable and have the act of dragging a marker update data on the server.
There is an example of where this has been done at L<http://testmaps.periapt.co.uk>.
The details of how this is done depend intrinsically on the implementation of the data storage on the server.
I would suggest that in general the steps required to make the markers draggable might be as follows:

=over 

=item Clean interface to the data storage.

I think this is a clear case where an ORM (L<http://en.wikipedia.org/wiki/Object-relational_mapping>) offers some advantages.
You could look at L<DBIx::Class> or write your own interface using L<DBI>.

=item Derive a class from Geo::Google::MapObject.

Your derived class constructor should get the data you need from the data storage interface layer, use it to
create a Geo::Google::MapObject and bless that into your derived class.

=item Provide URLs that update the data underlying your map objects.

These will probably be POST methods and need not return anything other than an "OK" string.
They should probably call the data storage interface layer directly to update the data.
There is no point creating a map object merely to update the underlying data.

=item Add link elements to your markup indicating which URL is needed to update the marker data.

  <link href="/move_marker" id="move_marker"/>

An advantage of using these link elements is that you might have multiple maps to manage.
By using the link elements to communicate with the client side, a lot more code and templates can be reused.

=item Get the javascript side to read your new link elements.

  var move_marker = YAHOO.util.Dom.get('move_marker').href;

=item Add a C<< draggable >> flag to the GMarker constructor

  var opt = {title: markers[i].title, draggable: true};

=item Make sure your GMarkers are labelled in a way that your server can understand

Just after the GMarker object, mark, has been created add

  mark.label = markers[i].label;
 
=item Make your GMarker object subscribe to the C<< dragend >> event.

  GEvent.addListener(mark,
		     "dragend",
		     function(latlng) {
                             var location = latlng.toUrlValue(12);
                             var postdata = "id="+this.label+"&location="+location;
                             YAHOO.util.Connect.asyncRequest('POST',
							     move_marker,
							     {
								success: function(o){},
								failure: function(o) {alert(o.statusText);},
								argument: []
							     },
							     postdata);
                     });

=back

=head1 DIAGNOSTICS

=over

=item C<< markers should be an ARRAY >>

The markers parameter of the constructor must be an ARRAY ref of marker configuration data.

=item C<< no API key >>

To use this module you must sign up for an API key (http://code.google.com/apis/maps/signup.html) and supply it as
the key parameter.

=item C<< zoom not a number: %s >>

There must be a zoom parameter which is a number from 0 to 21.

=item C<< maptype %s  not recognized >>

The maptype must be one of roadmap, satellite, terrain, hybrid.

=item C<< no width >>

=item C<< no height >>

=item C<< width should be positive and no more than 640 >>

=item C<< height should be positive and no more than 640 >>

=item C<< cannot recognize size >>

The size parameter must either be a string like "300x500" or a hash array like {width=>300,height=>500}.
And both width and height must be between 1 and 640 inclusive.

=item C<< cannot calculate autozoom without markers >>

If you pass an C<< autozoom >> parameter to the constructor you must also pass at least one marker.

=item C<< % not recognized as autozoom >>

An autozoom parameter was passed to the constructor that was not recognized as such.

=item C<< location missing >>

A marker specification was missing a location during autozoom calculation.

=item C<< no location for %s >>

Every marker object must have a location.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Geo::Google::MapObject requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over 

=item Templating framework

We assume the use of L<HTML::Template::Pluggable> and L<HTML::Template::Plugin>
though other template frameworks may work.

=item Google Maps API

You need to have one of these which can be obtained from L<http://code.google.com/apis/maps/signup.html>.

=item Javascript and AJAX

We assume a degree of familiarity with javascript, AJAX and client side programming.
For the purposes of documentation we assume YUI: L<http://developer.yahoo.com/yui/>, but this
choice of framework is not mandated.

=item L<Math::Trig>

The autozoom algorithm optionally used by this module depends upon the L<Math::Trig> for its mathematical
calculations. Since alternative algorithms or no algorithm at all can be used, I think it might be better to have this as a separate module.

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

=over

=item paths etc

Currently there is no support for paths, polygons or viewports.

=item version 3

We are currently only supporting version 2 of the API.

=item testing

We encode the title attributes of markers in the C<< json >> function as this seems to be necessary.
However I have not yet managed to get a decent test script for this behaviour.
There are many other cases that should be tested though I think the most critical cases 
have been tested.

=item character encoding 

This module is only tested against UTF-8 web pages. I have no intention
of changing this as I cannot think of why anyone would consciously choose to encode
web pages in any other way. I am open to persuasion however.

=back

Please report any bugs or feature requests to
C<bug-geo-google-mapobject@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 ACKNOWLEDGEMENTS

Thanks to Andreas Koenig for pointing out that this module had an issue with C<< Build.PL >>. 

=head1 AUTHOR

Nicholas Bamber  C<< <nicholas@periapt.co.uk> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Nicholas Bamber C<< <nicholas@periapt.co.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1; # End of Geo::Google::MapObject
