#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 72;
BEGIN {
  use_ok('JSON', 1.12); #JSON 1.11 and earlier don't handle mixes of ' and " for field delimiters
  use_ok('Geo::Google');
  use_ok('LWP::Simple');
};

########################

use strict;
use Data::Dumper;
use Geo::Google;
use JSON;
use constant TOLERANCE => "%3.5f"; # only test lat/long coordinates to the nearest hundred-thousandth of a degree

ok( my $geo  = Geo::Google->new()                            , "Instantiated a new Geo::Google object" );
is( ref( $geo ), 'Geo::Google'                               , "Object type okay" );
is( $geo->version(), '0.05'                              , "Check Geo::Google version number" );

is( Geo::Google::_encode_word(34.06698), "su|nE"	     , "_encode_word static unit test: 34.06698 encodes to 'su|nE'" );
is( Geo::Google::_encode_word(-118.44442), "rt|qU"	     , "_encode_word static unit test: -118.44442 encodes to 'rt|qU'" );
is( Geo::Google::_decode_word("su|nE"), 34.06698 	     , "_decode_word static unit test: 'su|nE' decodes to 34.06698" );
is( Geo::Google::_decode_word("rt|qU"), -118.44442  	     , "_decode_word static unit test: 'rt|qU' decodes to -118.44442" );
my @points_array = (34.06698, -118.44442, 34.06694, -118.44512);
my $polyline = "su|nErt|qUFjC";
my @decoded_array = Geo::Google::_decode($polyline); 
is( Geo::Google::_encode( @points_array ), $polyline	     , "_encode static unit test: (34.06698, -118.44442, 34.06694, -118.44512) encodes to '$polyline'");
is_deeply( \@decoded_array, \@points_array		     , "_decode static unit test: '$polyline' decodes to (34.06698, -118.44442, 34.06694, -118.44512)");

# Check to see if we're properly extracting Google's suggested alternate addresses when it can't resolve an address
ok( my $bad_address = '695 Charles E Young Dr S, Westwood, CA 90024', "An address Google suggests alternate addresses for" );
ok( my @suggested_locations = $geo->location( address => $bad_address ), "Executed a Google query for the bad address" );
isnt( $suggested_locations[0], undef,			     , "The \$geo->location() query for the bad address didn't error out" );
warn $geo->error() unless defined( $suggested_locations[0] ); # print the specific reason it errored out
is( scalar( @suggested_locations ), 2			     , "Google suggested exactly two alternate addresses" );
is( sprintf( TOLERANCE, $suggested_locations[0]->latitude() ) ,   34.06698, "...first suggested alternate address latitude okay"    );
is( sprintf( TOLERANCE, $suggested_locations[0]->longitude() ), -118.44442, "...first suggested alternate address longitude okay"   );

ok( my $add1 = '695 Charles E Young Dr S, Los Angeles, Los Angeles, California 90024, United States', "Dept. of Human Genetics, UCLA" );
ok( my $add2 = '10948 Weyburn Ave, Westwood, CA 90024'       , "Stan's Donuts"  );
ok( my $add3 = '5006 W Pico Blvd, Los Angeles, CA 90019'     , "Roscoe's House of Chicken and Waffles" );

#Create Geo::Google::Location objects.  These contain latitude/longitude coordinates,
#along with a few other details about the locus.
ok( my ($loc1) = $geo->location( address => $add1 )          , "loc1 on the map"     );
isnt( $loc1, undef                                           , "...and defined"      );
is( sprintf( TOLERANCE, $loc1->latitude()  ),   34.06698     , "...latitude okay"    );
is( sprintf( TOLERANCE, $loc1->longitude() ), -118.44442     , "...longitude okay"   );
ok( my ($loc2) = $geo->location( address => $add2 )          , "loc2 on the map"     );
isnt( $loc2, undef                                           , "...and defined"      );
is( sprintf( TOLERANCE, $loc2->latitude()  ),   34.06251     , "...latitude okay"    );
is( sprintf( TOLERANCE, $loc2->longitude() ), -118.44712     , "...longitude okay"   );
ok( my ($loc3) = $geo->location( address => $add3 )          , "loc3 on the map"     );
isnt( $loc3, undef                                           , "...and defined"      );
is( sprintf( TOLERANCE, $loc3->latitude()  ),   34.04777     , "...latitude okay"    );
is( sprintf( TOLERANCE, $loc3->longitude() ), -118.34615     , "...longitude okay"   );

#Create a Geo::Google::Path object from $loc1 to $loc3 via waypoint $loc2
#A path contains a series of Geo::Google::Segment objects with text labels representing
#turn-by-turn driving directions between two or more locations.
ok( my ( $path ) = $geo->path( $loc1, $loc2, $loc3 )         , "Instantiated a new Geo::Google::Path with one waypoint" );
isnt($path, undef                                            , "directions from gonda to stans to roscoes and make a path object from the JSON response");
warn $geo->error() unless defined( $path ); # print the specific reason it errored out
ok( my @segments = $path->segments()                         , "Path contains segments" );
is( scalar( @segments ), 17                                  , "Correct number of segments on the path" );

# Perform a dynamic test on _decode and _encode using a polyline that came with the directions we just retrieved from Google
is( Geo::Google::_encode( Geo::Google::_decode( @{$path->polyline()}[0] ) ), @{$path->polyline()}[0], "_decode() and _encode() dynamic unit test: Google polyline to pointsarray to generated polyline: Google's polyline should equal our polyline" );

#Test directions
my $segment = undef;

ok( $segment = $segments[1] );
is ( $segment->id(), 'panel_0_0'			     , 'segment id okay'       );
is ( $segment->pointIndex(), '0'                             , 'point index okay'       );
is ( $segment->distance(), '213 ft'                          , 'segment distance okay' );
is ( $segment->text(), 'Head west on Charles E Young Dr S toward Westwood Plaza'         , 'segment text okay'     );

ok( $segment = $segments[6] );
is ( $segment->id(), 'panel_1_0'			     , 'segment id okay'       );
is ( $segment->pointIndex(), '0'                             , 'segment id okay'       );
is ( $segment->distance(), '322 ft'                          , 'segment distance okay' );
is ( $segment->text(), 'Head southwest on Weyburn Ave toward Gayley Ave'             , 'segment text okay'     );

#Create a Geo::Google::Path object from $loc1 to $loc2
#A path contains a series of Geo::Google::Segment objects with text labels representing
#turn-by-turn driving directions between two or more locations.
ok( ( $path ) = $geo->path( $loc1, $loc2 )         	     , "Instantiated a new Geo::Google::Path with no waypoints" );
isnt($path, undef                                            , "directions from gonda to stans and make a path object from the JSON response");
ok( @segments = $path->segments()                            , "Path contains segments" );
is( scalar( @segments ), 6                                   , "Correct number of segments on the path" );

#Test directions
#foreach my $s ( @segments ) {
#  warn "*".$s->id()."\n";
#  warn "\t".$s->text()."\n";
#  warn "\t".$s->distance()."\n";
#  warn "\t".$s->time()."\n";
#  warn "\t".$s->pointIndex()."\n";
#}

ok( $segment = $segments[1] );
is ( $segment->id(), 'panel_0_0'			    , 'segment id okay'       );
is ( $segment->pointIndex(), '0'                            , 'point index okay'       );
is ( $segment->distance(), '213 ft'                         , 'segment distance okay' );
is ( $segment->text(), 'Head west on Charles E Young Dr S toward Westwood Plaza'         , 'segment text okay'     );

ok( $segment = $segments[4] );
is ( $segment->id(), 'panel_0_9'			    , 'segment id okay'       );
is ( $segment->pointIndex(), '9'                            , 'segment id okay'       );
is ( $segment->distance(), '495 ft'                         , 'segment distance okay' );
is ( $segment->text(), 'Turn right at Weyburn Ave'          , 'segment text okay'     );


#Geo::Google::Segment objects contain a series of Geo::Google::Location objects --
#one for each time the segment deviates from a straight line to the end of the segment.
my @points = $segments[1]->points;

is( scalar( @points ), 2                                     , 'Correct number of points in segment' );
is( $points[1]->latitude(), '34.06694'                       , 'Point latitude okay' );  #polyline points are .00001 precision, no tolerances here
is( $points[1]->longitude(), '-118.44512'                    , 'Point longitude okay' ); #polyline points are .00001 precision, no tolerances here

#Find coffee near to Stan's Donuts
ok( my @near = $geo->near( $loc2, 'coffee' )                 , "Search for coffee near Stan's Donuts" );
is( ref( $near[0] ), 'Geo::Google::Location',                , "Search returns Geo::Google::Location objects" );
warn $geo->error() unless defined( $near[0] ); # Print out the exact reason it errored out and didn't return location objects

#Too many.  How about some Coffee Bean & Tea Leaf?
ok( (@near = grep { $_->title =~ /Coffee.*?Bean/i } @near)   , "Filter coffee shops to Coffee Bean" );

#Still too many!  Let's find the closest with a little trig and a Schwartzian transform
my ( $coffee ) = map { $_->[1] }
                 sort { $a->[0] <=> $b->[0] }
                  map { [ sqrt(
                    ($_->longitude - $loc2->longitude)**2
                      +
                    ($_->latitude - $loc2->latitude)**2
                  ), $_ ] } @near;

is( sprintf( TOLERANCE, $coffee->latitude()  ),   34.06196   , 'Coffee latitude okay');
is( sprintf( TOLERANCE, $coffee->longitude() ), -118.44795   , 'Coffee latitude okay');

# Exports
ok( my $loc2XML = $loc2->toXML()                             , "Stan's Donuts as Google Earth KML (XML) format" );
ok( my $loc3XML = $loc3->toJSON()                            , "Roscoe's as Google Maps JSON format" );

