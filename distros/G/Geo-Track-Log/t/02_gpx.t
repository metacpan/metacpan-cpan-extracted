# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;

# of if you know how many tests there will be...
# use Test::More tests => 1;
# use Geo::Track::Log;
 BEGIN { use_ok('Geo::Track::Log') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $trk = new Geo::Track::Log;
$trk->loadTrackFromGPX("eg/test.gpx");
my ($pt) = $trk->whereWasI('2004-08-26 15:09:25');
is( $pt->{lat}, 60.171068, "first lat" );
is( $pt->{long}, 24.943213, "first long" );

($pt) = $trk->whereWasI('2004-08-26 15:09:26');
is( $pt->{lat}, 60.171071, "interpolated lat" );
is( $pt->{long}, 24.943213, "interpolated long" );

__END__
<?xml version="1.0"?>
<gpx
 version="1.0"
creator="GPSBabel - http://gpsbabel.sourceforge.net"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns="http://www.topografix.com/GPX/1/0"
xsi:schemaLocation="http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd">
<trk>
<trkseg>
<trkpt lat="60.171068" lon="24.943213">
<ele>-8.995239</ele>
<time>2004-08-26T15:09:25Z</time>
</trkpt>
<trkpt lat="60.171111" lon="24.943213">
<ele>-8.995239</ele>
<time>2004-08-26T15:09:42Z</time>
</trkpt>
</trkseg>
</trk>
</gpx>
