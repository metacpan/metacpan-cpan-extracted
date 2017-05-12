=head1 NAME

Geo::Google - Perform geographical queries using Google Maps

=head1 SYNOPSIS

  use strict;
  use Data::Dumper;
  use Geo::Google;

  #Allen's office
  my $gonda_addr = '695 Charles E Young Dr S, Los Angeles, Los Angeles, California 90024, United States';
  #Stan's Donuts
  my $stans_addr = '10948 Weyburn Ave, Westwood, CA 90024';
  #Roscoe's House of Chicken and Waffles
  my $roscoes_addr = "5006 W Pico Blvd, Los Angeles, CA 90019";

  #Instantiate a new Geo::Google object.
  my $geo = Geo::Google->new();

  #Create Geo::Google::Location objects.  These contain
  #latitude/longitude coordinates, along with a few other details
  #about the locus.
  my ( $gonda ) = $geo->location( address => $gonda_addr );
  my ( $stans ) = $geo->location( address => $stans_addr );
  my ( $roscoes ) = $geo->location( address => $roscoes_addr );
  print $gonda->latitude, " / ", $gonda->longitude, "\n";
  print $stans->latitude, " / ", $stans->longitude, "\n";
  print $roscoes->latitude, " / ", $roscoes->longitude, "\n";

  #Create a Geo::Google::Path object from $gonda to $roscoes
  #by way of $stans.
  my ( $donut_path ) = $geo->path($gonda, $stans, $roscoes);

  #A path contains a series of Geo::Google::Segment objects with
  #text labels representing turn-by-turn driving directions between
  #two or more locations.
  my @segments = $donut_path->segments();

  #This is the human-readable directions for the first leg of the
  #journey.
  print $segments[0]->text(),"\n";

  #Geo::Google::Segment objects contain a series of
  #Geo::Google::Location objects -- one for each time the segment
  #deviates from a straight line to the end of the segment.
  my @points = $segments[1]->points;
  print $points[0]->latitude, " / ", $points[0]->longitude, "\n";

  #Now how about some coffee nearby?
  my @coffee = $geo->near($stans,'coffee');
  #Too many.  How about some Coffee Bean & Tea Leaf?
  @coffee = grep { $_->title =~ /Coffee.*?Bean/i } @coffee;

  #Still too many.  Let's find the closest with a little trig and
  #a Schwartzian transform
  my ( $coffee ) = map { $_->[1] }
                   sort { $a->[0] <=> $b->[0] }
                   map { [ sqrt(
                            ($_->longitude - $stans->longitude)**2
                              +
                            ($_->latitude - $stans->latitude)**2
                           ), $_ ] } @coffee;

  # Export a location as XML for part of a Google Earth KML file
  my $strStansDonutsXML = $stans->toXML();
 
  # Export a location as JSON data to use with Google Maps
  my $strRoscoesJSON = $roscoes->toJSON();

=head1 DESCRIPTION

Geo::Google provides access to the map data used by the popular
L<Google Maps|http://maps.google.com> web application.

=head2 WHAT IS PROVIDED

=over

=item Conversion of a street address to a 2D Cartesian point
(latitude/longitude)

=item Conversion of a pair of points to a multi-segmented path of
driving directions between the two points.

=item Querying Google's "Local Search" given a point and one or more
query terms.

=back

=head2 WHAT IS NOT PROVIDED

=over

=item Documentation of the Google Maps map data XML format

=item Documentation of the Google Maps web application API

=item Functionality to create your own Google Maps web page.

=back

=head1 AUTHOR

Allen Day E<lt>allenday@ucla.eduE<gt>, Michael Trowbridge 
E<lt>michael.a.trowbridge@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2007 Allen Day.  All rights
reserved. This program is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=head1 BUGS / TODO

Report documentation and software bugs to the author, or better yet,
send a patch.  Known bugs/issues:

=over

=item Lack of documentation.

=item JSON exporting is not exactly identical to the original Google 
JSON response.  Some of the Google Maps-specific data is discarded 
during parsing, and the perl JSON module does not allow for bare keys 
while exporting to a JSON string.  It should still be functionally 
interchangeable with a Google JSON reponse.

=back

=head1 SEE ALSO

  http://maps.google.com
  http://www.google.com/apis/maps/
  http://libgmail.sourceforge.net/googlemaps.html

=cut

package Geo::Google;
use strict;
our $VERSION = '0.05';

#this gets a javascript page containing map XML
use constant LQ => 'http://maps.google.com/maps?output=js&v=1&q=%s';

#this gets a javascript page containing map XML.  special for "nearby" searches
use constant NQ => 'http://maps.google.com/maps?output=js&v=1&near=%s&q=%s';

#used in polyline codec
use constant END_OF_STREAM => 9999;

#external libs
use Data::Dumper;
use Digest::MD5 qw( md5_hex );
use HTML::Entities;
use JSON;
use LWP::Simple;
use URI::Escape;

#our libs
use Geo::Google::Location;
use Geo::Google::Path;
use Geo::Google::Segment;

sub version { return $VERSION }

=head1 CONSTRUCTOR

=cut

=head2 new()

 Usage    : my $geo = Geo::Google->new();
 Function : constructs and returns a new Geo::Google object
 Returns  : a Geo::Google object
 Args     : n/a

=cut

sub new {
  return bless {}, __PACKAGE__;
}

=head1 OBJECT METHODS

=cut

=head2 error()

 Usage    : my $error = $geo->error();
 Function : Fetch error messages produced by the Google Maps XML server.
            Errors can be produced for a number of reasons, e.g. inability
            of the server to resolve a street address to geographical
            coordinates.
 Returns  : The most recent error string.  Calling this method clears the
            last error.
 Args     : n/a

=cut

sub error {
  my ( $self, $msg ) = @_;
  if ( !defined($msg) or ! $self->isa(__PACKAGE__) ) {
    my $error = $self->{error};
    $self->{error} = undef;
    return $error;
  }
  else {
    $self->{error} = $msg;
  }
}

=head2 location()

 Usage    : my $loc = $geo->location( address => $address );
 Function : creates a new Geo::Google::Location object, given a
            street address.
 Returns  : a Geo::Google::Location object, or undef on error
 Args     : an anonymous hash:
            key       required?   value
            -------   ---------   -----
            address   yes         address to search for
            id        no          unique identifier for the
                                  location.  useful if producing
                                  XML.
            icon      no          image to be used to represent
                                  point in Google Maps web
                                  application
            infoStyle no          unknown.  css-related, perhaps?

=cut

sub location {
  my ( $self, %arg ) = @_;
  my @result = ();

  my $address   = $arg{'address'} or ($self->error("must provide an address to location()") and return undef);

  my $json = new JSON (skipinvalid => 1, barekey => 1, quotapos => 1, unmapping => 1 );
  my $response_json = undef;
  # I'm using an an array here because I might need to parse several pages if Google suggests a different address
  my @pages = ( get( sprintf( LQ, uri_escape($address) ) ) );
  
  # See if google returned no results
  if ( $pages[0] =~ /did\snot\smatch\sany\slocations/i ) {
    $self->error( "Google couldn't find any locations matching $address." ) and return undef;
  }
  # See if Google was unable to resolve the address, but suggested other addresses
  # To see this, run a query for 695 Charles E Young Dr S, Westwood, CA 90024
  elsif ( $pages[0] =~ m#Did you mean:#is ) {
    # Extract the queries from all the http get queries for alterate addresses
    # \u003cdiv class=\"ref\"\u003e\u003ca href=\"/maps?v=1\u0026amp;q=695+Charles+E+Young+Drive+East,+Los+Angeles,+Los+Angeles,+California+90024,+United+States\u0026amp;ie=UTF8\u0026amp;hl=en\u0026amp;oi=georefine\u0026amp;ct=clnk\u0026amp;cd=2\" onclick=\"return loadUrl(this.href)\"\u003e
    # We need it to fit the LQ query 'http://maps.google.com/maps?output=js&v=1&q=%s'
    my @queries = $pages[0] =~ m#\\u003cdiv class=\\"ref\\"\\u003e\\u003ca href=\\"/maps\?v=1\\u0026amp;q=(.+?)\\u0026amp;#gsi;
    # clear the $pages array so we can fill it with the pages from the @urls
    @pages = ();
    foreach my $suggested_query (@queries) {
      push( @pages, get( sprintf( LQ, $suggested_query ) ) );
    }
  }
  # Verify that we actually retrieved pages to parse
  if ( scalar(@pages) > 0 ) {
    foreach my $page (@pages) {
      # attempt to locate the JSON formatted data block
      if ($page =~ m#loadVPage\((.+), "\w+"\);}//]]>#is) { $response_json = $json->jsonToObj($1); }
      else {
	$self->error( "Unable to locate the JSON format data in google's response.") and return undef;
      }
      if ( scalar(@{$response_json->{"overlays"}->{"markers"}}) > 0 ) {	
        foreach my $marker (@{$response_json->{"overlays"}->{"markers"}}) {
	  my $loc = $self->_obj2location($marker, %arg);
	  push @result, $loc;
        }		
      }
      else {
	$self->error("Found the JSON Data block and was able to parse it, but it had no location markers "
	  . "in it.  Maybe Google changed their JSON data structure?.") and return undef;
      }
    }
  }
  else {
    $self->error("Google couldn't resolve the address $address but suggested alternate addresses.  "
      . "I attempted to download them but failed.") and return undef;
  }
  return @result;
}

=head2 near()

 Usage    : my @near = $geo->near( $loc, $phrase );
 Function : searches Google Local for records matching the
            phrase provided, with the constraint that they are
            physically nearby the Geo::Google::Location object
            provided.  search phrase is passed verbatim to Google.
 Returns  : a list of Geo::Google::Location objects
 Args     : 1. A Geo::Google::Location object
            2. A search phrase.

=cut

sub near {
  my ( $self, $where, $query ) = @_;
  my $page = get( sprintf( NQ, join(',', $where->lines ), $query ) );
  
  my $json = new JSON (skipinvalid => 1, barekey => 1, 
			quotapos => 1, unmapping => 1 );
  my $response_json = undef;

  # See if google returned no results
  if ( $page =~ /did\snot\smatch\sany\slocations/i ) {
    $self->error( "Google couldn't find a $query near " . $where->title) and return undef;
  }
  # attempt to locate the JSON formatted data block
  elsif ($page =~ m#loadVPage\((.+), "\w+"\);}//]]>#is) {
    my $strJSON = $1;
    $response_json = $json->jsonToObj($strJSON);
  }
  else {
    $self->error( "Unable to locate the JSON format data in Google's response.") and return undef;
  }

  if ( scalar(@{$response_json->{"overlays"}->{"markers"}}) > 0 ) {
    my @result = ();
    foreach my $marker (@{$response_json->{"overlays"}->{"markers"}}) {
      my $loc = $self->_obj2location($marker);
      push @result, $loc;
    }		
    return @result;
  }
  else {
    $self->error("Found the JSON Data block and was "
      . "able to parse it, but it had no location markers"
      . "in it.  Maybe Google changed their "
      . "JSON data structure?") and return undef;
  }
}

=head2 path()

 Usage    : my $path = $geo->path( $from, $OptionalWaypoints, $to );
 Function : get driving directions between two points
 Returns  : a Geo::Google::Path object
 Args     : 1. a Geo::Google::Location object (from)
	    2. optional Geo::Google::Location waypoints
            3. a Geo::Google::Location object (final destination)

=cut

sub path {
  my ( $self, @locations ) = @_;
  my $json = new JSON (skipinvalid => 1, barekey => 1, 
			quotapos => 1, unmapping => 1 );
  my $response_json = undef;

  if(scalar(@locations) < 2) {
    $self->error("Less than two locations were passed to the path function");
    return undef;
  }
  #check each @locations element to see if it is a Geo::Google::Location
  for (my $i=0; $i<=$#locations; $i++) {
	if(!$locations[$i]->isa('Geo::Google::Location')) {
	    $self->error("Location " . ($i+1)
			. " passed to the path function is not a "
			. "Geo::Google::Location"
			. " object, or subclass thereof");
	    return undef;
	}
  }

  # construct the google search text
  my $googlesearch = "from: " . join(', ', $locations[0]->lines);
  for (my $i=1; $i<=$#locations; $i++){
	$googlesearch .= " to:" . join(', ', $locations[$i]->lines);
  }
  my $page = get( sprintf( LQ, uri_escape( $googlesearch ) ) );

  # See if google returned no results
  if ( $page =~ /did\snot\smatch\sany\slocations/i ) {
    $self->error( "Google couldn't find one of the locations you provided for your directions query") and return undef;
  }
  # See if google didn't recognize an input, but suggested
  # a correction to the input that it does recognize
  elsif ( $page =~ m#didyou#s )
  {
    # Parse the JSON to unescape the escaped unicode characters in the URLs we need to parse
    my ( $strJSON ) = $page =~ m#loadVPage\((.+), "\w+"\);}//]]>#s;
    my $suggestion_json = $json->jsonToObj($strJSON);
    # Did you mean:</span><div class="ref"><a href="/maps?v=1&amp;ie=UTF8&amp;hl=en&amp;ct=clnk&amp;cd=1&amp;saddr=695+Charles+E+Young+Dr+S,+Los+Angeles,+Los+Angeles,+California+90024,+United+States&amp;daddr=10948+Weyburn+Ave,+Los+Angeles,+CA+90024+to:5006+W+Pico+Blvd,+Los+Angeles,+CA+90019&amp;f=d" onclick="return loadUrl(this.href)"><b><i>695 Charles E Young Dr S, Los Angeles, Los Angeles, California 90024, United States</i></b>
    my ( $first_suggestion ) = $suggestion_json->{panel} =~ m#(saddr=.+?)" onclick#s;
    # Get the directions using google's first suggestion
    $page = get ( _html_unescape("http://maps.google.com/maps?output=js&$1") );

    # warn the user using the error method, but don't return undef.
    $self->error("Google suggested a different address for your query.  Using the google suggestion instead.");
  }
  # attept to locate the JSON formatted data block
  if ($page =~ m#loadVPage\((.+), "\w+"\);}//]]>#s) {
    # Extract the JSON data structure from the response.
    $response_json = $json->jsonToObj( $1 );
  }
  else {
    $self->error( "Unable to locate the JSON format data in Google's response.") and return undef;
  }

  my @points;
  my @enc_points;
  for (my $i = 0; $i<=$#{$response_json->{"overlays"}->{"polylines"}}; $i++) {
    $enc_points[$i] = $response_json->{"overlays"}->{"polylines"}->[$i]->{"points"};
    $points[$i] = [ _decode($enc_points[$i]) ];
  }

  # extract a series of directions from HTML inside the panel 
  # portion of the JSON data response, stuffing them in @html_segs
  my @html_segs;
  my $stepsfound = 0;

  my $panel = $response_json->{'panel'};
  $panel =~ s/&#160;/ /g;

  my @subpaths = $panel =~ m#(<table class="(ddrsteps(?: pw)?|ddwpt_table|dirsegment)".+?</table>\s*</div>)#gs; #ddspt_table
  #my ( $subpanel ) = $response_json->{'panel'} =~ m#<table class="ddrsteps pw">(.+)</table>#s;

  foreach my $subpath ( @subpaths ) {
    my @segments = split m#</tr>\s*<tr#s, $subpath;
    foreach my $segment ( @segments ) {
      #skip irrelevant waypoint rows
      if ( $subpath =~ m#ddwpt_table#s && $segment !~ m#ddptlnk#s ) { next }

      my ( $id, $pointIndex ) = $segment =~ m#id="(.+?)" polypoint="(.+?)"#s;
      my ( $html )       = $segment =~ m#"dirsegtext_\d+_\d+">(.+?)</td>#s;
      my ( $distance )   = $segment =~ m#"sxdist".+?>(.+?)<#s;
      my ( $time )       = $segment =~ m#"segtime nw pw">(.+?)<#s;

      if ( ! defined( $id ) ) {
        if ( $subpath =~ m#waypoint="(.+?)"#s ) {
          $id = "waypoint_$1";
	  $html = $locations[$1]->title();
          ($pointIndex)  = $segment =~ m#polypoint="(.+?)"#s;
        }
      }

      next unless $id;

      if ( ! $time ) {
        #some segments are different (why? what is the pattern?)
        my ( $d2, $t2 ) = $segment =~ m#timedist ul.+?>(.+?)\(about&\#160;(.+?)\)</td>#s;
        $time = $t2;
        $distance ||= $d2;
      }

      #some segments have no associated point, e.g. when there are long-distance driving segments

      #some segments have time xor distance (not both)
      $distance   ||= ''; $distance = decode_entities( $distance ); $distance =~ s/\s+/ /g;
      $time       ||= ''; $time     = decode_entities( $time     ); $time =~ s/\s+/ /g;

      push (@html_segs, {
        distance   => $distance,
        time       => $time,
        pointIndex => $pointIndex,
        id         => $id,
        html       => $html
      });
      $stepsfound++;
    }
  }

  if ($stepsfound == 0) {
    $self->error("Found the HTML directions from the JSON "
      . "reponse, but was not able to extract "
      . "the driving directions from the HTML") and return undef;
  }
  my @segments = ();
  # Problem:  When you create a Geo::Google::Location by
  # looking it up on Google from an address, it returns coordinates
  # with millionth of a degree precision.  Coordinates that come out 
  # the polyline string only have hundred thousandth of a degree
  # precision.  This means that the correlation algorithm won't find
  # the start, stop or waypoints in the polyline unless we round
  # start, stop and waypoint coordinates to the hundred-thousandth
  # degree precision.
  foreach my $location (@locations) {
    $location->{'latitude'} = sprintf("%3.5f", $location->{'latitude'} );
    $location->{'longitude'} = sprintf("%3.5f", $location->{'longitude'} );
  }

  #  Correlate the arrays of lats and longs we decoded from the 
  # JSON object with the segments we extracted from the panel 
  # HTML and put the result into an array of
  # Geo::Google::Location objects
  my @points_subset = ( $locations[0] );
  push (@segments, Geo::Google::Segment->new(
        pointIndex => $html_segs[0]{'pointIndex'},
        id         => $html_segs[0]{'id'},
        html       => $html_segs[0]{"html"},
        distance   => $html_segs[0]{'distance'},
        time       => $html_segs[0]{'time'},
        from       => $locations[0],
        to         => $locations[0],
        points     => [@points_subset])
	);
  shift @html_segs;
  for (my $i = 0; $i <= $#points; $i++) {
    # start/points cause us problems because they're often the same
    # the same pointindex as the first segment of the directions
    # pulling the first html_seg off the stack now makes the next
    # control loop easier to maintain.
    @points_subset = ();

    my $m = 0;
    my @pointset = @{$points[$i]};
    while ( @pointset ) {
      my $lat = shift @pointset;
      my $lon = shift @pointset;
      $m++;
      my %html_seg;

      # Check to see if the lat and long belong to a start, stop or waypoint
      my $pointislocation = -1;
      for (my $j=0; $j <= $#locations; $j++) {
	if ( ( $lat == $locations[$j]->latitude() ) && ( $lon == $locations[$j]->longitude() ) ) { $pointislocation = $j; last; }
      }
      # If the point that just came off the pointset array is a start, stop or waypoint, use that start/stop/waypoint.
      # otherwise, create a new point for the lat/long that just came off the pointset array.
      my $point;
      if ( $pointislocation >= 0 ){ $point = $locations[$pointislocation]; }
      else			  { $point = Geo::Google::Location->new( latitude  => $lat, longitude => $lon ); }

      push @points_subset, $point;

      if ( $html_segs[1] ) { 
	# There's a segment after the one we're working on
	# This tests to see if we need to wrap up the current segment
        if ( defined( $html_segs[1]{'pointIndex'} ) ) {
          next unless ((($m == $html_segs[1]{'pointIndex'}) && ($#html_segs > 1) ) || (! @pointset) );
        }
        %html_seg = %{shift @html_segs};
        push @segments, Geo::Google::Segment->new(
          pointIndex => $html_seg{'pointIndex'},
          id         => $html_seg{'id'},
          html       => decode_entities($html_seg{"html"}),
          distance   => $html_seg{'distance'},
          time       => $html_seg{'time'},
          from       => $points_subset[0],
          to         => $point,
          points     => [@points_subset]
        );
        @points_subset = ();
      } elsif ($html_segs[0]) { # We're working on the last segment
	# This tests to see if we need to wrap up the last segment
         next unless (! $pointset[0]);
         %html_seg = %{shift @html_segs};

	 # An attempt to get the last point in the last segment
	 # set.  Google doesn't include it in their polylines.
	 push @points_subset, $locations[$i+1];
         push @segments, Geo::Google::Segment->new(
            pointIndex => $html_seg{'pointIndex'},
            id         => $html_seg{'id'},
            html       => decode_entities($html_seg{"html"}),
            distance   => $html_seg{'distance'},
            time       => $html_seg{'time'},
            from       => $points_subset[0],
            to         => $locations[$i+1],
            points     => [@points_subset]
          );
          @points_subset = ();
      } else { # we accidentally closed out the last segment early
          push @{ $segments[$#segments]->{points} }, $point;
      }
    }
  }
  # Dirty:  add the final waypoint
  push (@segments, Geo::Google::Segment->new(
          pointIndex => $html_segs[0]{'pointIndex'},
          id         => $html_segs[0]{'id'},
          html       => $html_segs[0]{"html"},
          distance   => $html_segs[0]{'distance'},
          time       => $html_segs[0]{'time'},
          from       => $locations[$#locations],
          to         => $locations[$#locations],
          points     => [ ($locations[$#locations]) ])
	);
  # Extract the total information using a regex on the panel hash.  At the end of the "printheader", we're looking for:
  # <td class="value">9.4&#160;mi &#8211; about 17 mins</td></tr></table>
  # Replace XML numeric character references with spaces to make the next regex less dependent upon Google's precise formatting choices
  $response_json->{"printheader"} =~ s/&#\d+;/ /g;
  if ( $response_json->{"printheader"} =~ m#(\d+\.?\d*)\s*(mi|km|m)\s*about\s*(.+?)</td></tr></table>$#s ){
    return Geo::Google::Path->new(
      segments  => \@segments,
      distance  => $1 . " " . $2,
      time      => $3,
      polyline  => [ @enc_points ],
      locations => [ @locations ],
      panel     => $response_json->{"panel"},
      levels    => $response_json->{"overlays"}->{"polylines"}->[0]->{"levels"} );
  } else {
      $self->error("Could not extract the total route distance and time from google's directions") and return undef;
  }

#$Data::Dumper::Maxdepth=6;
#warn Dumper($path);
 
#<segments distance="0.6&#160;mi" meters="865" seconds="56" time="56 secs">
#  <segment distance="0.4&#160;mi" id="seg0" meters="593" pointIndex="0" seconds="38" time="38 secs">Head <b>southwest</b> from <b>Venice Blvd</b></segment>
#  <segment distance="0.2&#160;mi" id="seg1" meters="272" pointIndex="6" seconds="18" time="18 secs">Make a <b>U-turn</b> at <b>Venice Blvd</b></segment>
#</segments>
}

=head1 INTERNAL FUNCTIONS AND METHODS

=cut

=head2 _decode_word()

 Usage    : my $float = _decode_word($encoded_quintet_word);
 Function : turn a quintet word into a float for the _decode() function
 Returns  : a float
 Args     : one data word made of ASCII characters carrying
            a five-bit number per character from an encoded 
	    Google polyline string

=cut

sub _decode_word {
  my $quintets = shift;
  my @quintets = split '', $quintets;
  my $num_chars = scalar(@quintets);
  my $i = 0;
  my $final_number = 0;
  my $ordinal_offset = 63;
  
  while ($i < $num_chars ) {
    if ( ord($quintets[$i]) < 95 ) { $ordinal_offset = 63; }
    else { 		             $ordinal_offset = 95; }
    my $quintet = ord( $quintets[$i] ) - $ordinal_offset;
    $final_number |= $quintet << ( $i * 5 );
    $i++;
  }
  if ($final_number % 2 > 0) { $final_number *= -1; $final_number --; }
  return $final_number / 2E5;
}

=head2 _decode()

 Usage    : my @points = _decode($encoded_points);
 Function : decode a polyline into its composite lat/lon pairs
 Returns  : an array of floats (lat1, long1, lat2, long2 ... )
 Args     : an encoded google polyline string

=cut

sub _decode {
  # Each letter in the polyline is a quintet (five bits in a row).
  # A grouping of quintets that makes up a number we'll use
  # to calculate lat and long will be called a "word".
  my $quintets = shift;
  return undef unless defined $quintets;
  my @quintets = split '', $quintets;
  my @locations = ();
  my $word = "";

  # Extract the first lat and long.
  # The initial latitude word is the first five quintets.
  for (my $i=0; $i<=4; $i++) { $word .= $quintets[$i]; }
  push ( @locations, _decode_word($word) );
  my $lastlat = 0;

  # The initial longitude is the next five quintets.
  $word = "";
  for (my $i=5; $i<10; $i++) { $word .= $quintets[$i]; }
  push ( @locations, _decode_word($word) );
  my $lastlong = 1;

  # The remaining quintets form words that represent 
  # delta coordinates from the last coordinate.  The only
  # way to identify them is that they are at least one
  # character long and end in a ASCII character between
  # ordinal 63 and ordinal 95.  Latitude first, then
  # longitude.
  $word = "";
  my $i = 10;
  while ($i <= $#quintets) {
    $word .= $quintets[$i];
    if ( (length($word) >= 1) && ( ord($quintets[$i]) <= 95 ) ) {
      if ( $lastlat > $lastlong ) {
        push @locations, _decode_word($word) + $locations[$lastlong];
	$lastlong = $#locations; 
      }
      else {
        push @locations, _decode_word($word) + $locations[$lastlat];
	$lastlat = $#locations; 
      }
      $word = "";
    }
    $i++;
  }
  # Prettify results
  return map {sprintf("%3.5f",$_)} @locations;
}

=head2 _encode()

 Usage    : my $encoded_points = _encode(@points);
 Function : encode lat/lon pairs into a polyline string
 Returns  : a string
 Args     : an array of coordinates [38.47823, -118.48571, 38.47845, -118.48582, ...]

=cut

sub _encode {
  my @points = @_;
  my $polyline;
  for (my $i = 0; $i <= $#points; $i++) {
    # potential pitfall: pass the correct floating point precision
    # to the _encode_word() function or 34.06694 - 34.06698 will give you
    # -3.999999999999999057E-5 which doesn't encode properly. -4E-5 encodes properly.
    if ( $i > 1 ) { # All points after the first lat/long pair are delta coordinates
      $polyline .= _encode_word( sprintf("%3.5f", $points[$i] - $points[$i-2] ) );
    }
    else {
      $polyline .= _encode_word( sprintf("%3.5f", $points[$i] ) );
    }
  }
  return $polyline;
}

=head2 _encode_word()

 Usage    : my $encoded_quintet_word = _encode_word($signed_floating_point_coordinate);
 Function : turn a signed float (either a full coordinate 
	    or a delta) for the _encode() function
 Returns  : a string containing one encoded coordinate that
	    will be added to a polyline string
 Args     : one data word made of ASCII characters carrying
            a five-bit number per character from an encoded 
	    Google polyline string

=cut

sub _encode_word {
  my $coordinate = shift;
  # Convert the floating point coordinate into a doubled signed integer.  -38.45671 turns into -7691342
  # This looks quirky cos when I used int(-0.00015 * 2E5) I got -29 (should have been -30).  Suspect this is a perl 5.8.8 bug (MAT).
  my $signed_int = int( sprintf("%8.0f", $coordinate * 2E5) );
  # If the signed integer is negative, add one then lose the sign.  -7691342 turns into 7691341
  my $unsigned_int;
  if ($signed_int < 0) { $unsigned_int = -($signed_int + 1); }
  else		       { $unsigned_int = $signed_int;	     }
  
  # Quintets get created in reverse order (least signficant quintet first, most significant quintet last)
  my $ordinal_offset;
  my $quintet;
  
  # This do...while structure allows me to properly encode the coordinate 0
  do {
    if ( $unsigned_int < 32 ) { $ordinal_offset = 63; } #last quintet
    else { 		        $ordinal_offset = 95; }
    my $quintet_mask = ( $unsigned_int >> 5 ) << 5;
    $quintet .= chr( ( $unsigned_int ^ $quintet_mask ) + $ordinal_offset );
    $unsigned_int = $unsigned_int >> 5;
  } while ( $unsigned_int > 0 );
  return $quintet;
}

=head2 _html_unescape()

 Usage    : my $clean = _html_unescape($dirty);
 Function : does HTML unescape of & > < " special characters
 Returns  : an unescaped HTML string
 Args     : an HTML string.

=cut

sub _html_unescape {
  my ( $raw ) = shift;

  while ( $raw =~ m!&(amp|gt|lt|quot);!) {
    $raw =~ s!&amp;!&!g;
    $raw =~ s!&gt;!>!g;
    $raw =~ s!&lt;!<!g;
    $raw =~ s!&quot;!"!g;
  }
  return $raw;
}

=head2 _obj2location()

 Usage    : my $loc = _obj2location($obj);
 Function : converts a perl object generated from a Google Maps 
		JSON response to a Geo::Google::Location object
 Returns  : a Geo::Google::Location object
 Args     : a member of the $obj->{overlays}->{markers}->[] 
		anonymous array that you get when you read google's 
		JSON response and parse it using JSON::jsonToObj()

=cut

sub _obj2location {
  my ( $self, $marker, %arg ) = @_;

  my @lines;
  my $title;
  my $description;
  # Check to make sure that the info window contents are HTML
  # and that google hasn't changed the format since I wrote this
  if ( $marker->{"infoWindow"}->{"type"} eq "html" ) {
    if ($marker->{"laddr"} =~ /\((.+)\)\s\@\-?\d+\.\d+,\-?\d+\.\d+$/s){
      $title = $1;
    }
    else {
      $title = $marker->{"laddr"};
    }

    $description = decode_entities($marker->{"infoWindow"}->{"basics"});
    # replace </P>, <BR>, <BR/> and <BR /> with newlines
    $description =~ s/<\/p>|<br\s?\/?>/\n/gi;
    # remove all remaining markup tags
    $description =~ s/<.+>//g;
  }
  else {
    # this is a non-fatal nuisance error, only lat/long are 
    # absolutely essential products of this function
    $title = "Could not extract a title or description from "
	. "google's response.  Have they changed their format since "
	. "this function was written?";
  }  

  my $loc = Geo::Google::Location->new(
    title     => $title,
    latitude  => $marker->{"lat"},
    longitude => $marker->{"lng"},
    lines     => [ @{ $marker->{"addressLines"} } ],
    id        => $marker->{"id"}
                 || $arg{'id'}
                 || md5_hex( localtime() ),
    infostyle => $arg{'icon'}
                 || 'http://maps.google.com/mapfiles/marker.png',
    icon      => "http://maps.google.com" . $marker->{"image"}
                 || $arg{'infoStyle'}
                 || 'http://maps.google.com/mapfiles/arrow.png'
  );
  return $loc;

qq(
    <location id="H" infoStyle="/maps?file=li&amp;hl=en">
      <point lat="34.036003" lng="-118.477652"/>
      <icon class="local" image="/mapfiles/markerH.png"/>
      <info>
        <title xml:space="preserve"><b>Starbucks</b> Coffee: Santa Monica</title>
        <address>
          <line>2525 Wilshire Blvd</line>
          <line>Santa Monica, CA 90403</line>
        </address>
        <phone>(310) 264-0669</phone>
        <distance>1.2 mi SW</distance>
        <references count="5">
          <reference>
            <url>http://www.hellosantamonica.com/YP/c_COFFEESTORES.Cfm</url>
            <domain>hellosantamonica.com</domain>
            <title xml:space="preserve">Santa Monica California Yellow Pages. COFFEE STORES <b>...</b></title><shorttitle xml:space="preserve">Santa Monica California Yel...</shorttitle>
          </reference>
        </references>
        <url>/local?q=Starbucks+Coffee:+Santa+Monica&amp;near=Santa+Monica,+CA+90403&amp;latlng=34047451,-118462143,1897416402105863377</url>
      </info>
    </location>
);
}

=head2 _JSONrenderSkeleton()

 Usage    : my $perlvariable = _JSONrenderSkeleton();
 Function : creates the skeleton of a perl data structure used by 
		the Geo::Google::Location and Geo::Google::Path for 
		rendering to Google Maps JSON format
 Returns  : a mildly complex multi-level anonymous hash/array 
		perl data structure that corresponds to the Google 
		Maps JSON data structure
 Args     : none

=cut

sub _JSONrenderSkeleton{
	# This data structure is based on a sample query
	# performed on 27 Dec 06 by Michael Trowbridge
	return {
          'urlViewport' => 0,
          'ei' => '',
          'form' => {
                      'l' => {
                               'q' => '',
                               'near' => ''
                             },
                      'q' => {
                               'q' => ''
                             },
                      'd' => {
                               'saddr' => '',
                               'daddr' => '',
                               'dfaddr' => ''
                             },
                      'selected' => ''
                    },
          'overlays' => {
                          'polylines' => [],
                          'markers' => [],
                          'polygons' => []
                        },
          'printheader' => '',
          'modules' => [
                         undef
                       ],
          'viewport' => {
                          'mapType' => '',
                          'span' => {
                                      'lat' => '',
                                      'lng' => ''
                                    },
                          'center' => {
                                        'lat' => '',
                                        'lng' => ''
                                      }
                        },
          'panelResizeState' => 'not resizeable',
          'ssMap' => {
                       '' => ''
                     },
          'vartitle' => '',
          'url' => '/maps?v=1&q=URI_ESCAPED_QUERY_GOES_HERE&ie=UTF8',
          'title' => ''
        };
}

1;

#http://brevity.org/toys/google/google-draw-pl.txt

__END__
