# t/time.t

use DateTime;
use DateTime::Format::ISO8601;
use Geo::Gpx;
use Geo::Gpx::Point;
use Test::More tests => 18;

my ($dt_t, $dt_u);
$dt_t = DateTime->new(
               year       => 2022,
               month      => 10,
               day        => 25,
               hour       => 9,
               minute     => 45,
               second     => 0,
               time_zone  => 'America/Toronto',
           );

$dt_u = DateTime->new(
               year       => 2022,
               month      => 10,
               day        => 25,
               hour       => 9,
               minute     => 45,
               second     => 0,
               time_zone  => 'UTC',
           );

#
# Show that epoch time is "unique" and always reflects UTC time

my $epoch_diff_t_vs_u = ($dt_t->epoch - $dt_u->epoch) / 3600;
is($epoch_diff_t_vs_u, 4, "    time(): same hour and minute b/w EST (in DST) and UTC should be 4 hours appart, epoch wise");
is($dt_t->stringify, '2022-10-25T09:45:00',      "    stringify(): produce time as a string in local timezone (unless time_zone specified in DT object)");
is($dt_u->stringify, '2022-10-25T09:45:00',      "    stringify(): produce time as a string in local timezone (unless time_zone specified in DT object)");

my ($dt_min4, $dt_min4_z);
$dt_min4 =   DateTime::Format::ISO8601->parse_datetime('2022-10-25T09:45:00-04:00');
$dt_min4_z = DateTime::Format::ISO8601->parse_datetime('2022-10-25T13:45:00Z');
my $epoch_diff_min4_vs_z = ($dt_min4->epoch - $dt_min4_z->epoch) / 3600;
is($epoch_diff_min4_vs_z, 0, "    time(): should produce same value for epoch in Gpx and Gpx::Point constructors");
is($dt_min4->stringify,   '2022-10-25T09:45:00', "    stringify(): produce time as a string in local timezone");
is($dt_min4_z->stringify, '2022-10-25T13:45:00', "    stringify(): produce time as a string in local timezone (Z as same effect it seems as specifying time_zone => 'UTC'");

#
# Test that Geo::Gpx->new() and Geo::Gpx::Point-new() parse date strings the same way

# First, NB that within <time>...</time> tags in the xml, the date is *always* a string, never epoch i.e.
# my $xml_fail = '<?xml version="1.0" encoding="utf-8"?><gpx version="1.0"><wpt lat="54.786989" lon="-2.344214"><time>1666705500</time></wpt></gpx>';
# my $gpx_fail = Geo::Gpx->new( xml => $xml_fail );
# would return Invalid date format: 1666705500 (as expected)
# ... but Point's new() constructor is more flexibile, also accepts an epoch (see below)

my $xml = do { local $/; <DATA> };
my $gpx = Geo::Gpx->new( xml => $xml );

# creating these same 4 points individually with Point->new(), should yield the same results
my $pt1 = Geo::Gpx::Point->new( lat => '54.786989', lon => '-2.344214', time  => '2022-10-25T09:45-04:00' );
my $pt2 = Geo::Gpx::Point->new( lat => '54.786989', lon => '-2.344214', time  => '2022-10-25T13:45' );
my $pt3 = Geo::Gpx::Point->new( lat => '54.786989', lon => '-2.344214', time  => '2022-10-25T13:45Z' );
my $pt4 = Geo::Gpx::Point->new( lat => '54.786989', lon => '-2.344214', time  => 1666705500 );

# NB: can specify time as epoch in ::Point constructor but epoch cannot appear in xml mark-up

is($gpx->waypoints(1)->time, $pt1->time,   "    time(): should produce same value for epoch in Gpx and Gpx::Point constructors");
is($gpx->waypoints(2)->time, $pt2->time,   "    time(): should produce same value for epoch in Gpx and Gpx::Point constructors");
is($gpx->waypoints(3)->time, $pt3->time,   "    time(): should produce same value for epoch in Gpx and Gpx::Point constructors");
is($gpx->waypoints(4)->time, $pt4->time,   "    time(): should produce same value for epoch in Gpx and Gpx::Point constructors");


# stringification of the points is done in perspective of the local time (**unless** time_zone is specified in DT object). The
# DateTime manpage states the from_epoch() method creates a DT object **with** a time_zone, which is  time_zone => 'UTC' as the default,
# so the stringification of the DT object returned by Point->time_datetime() will represent UTC time and not local time (for the same epoch).
# If a a differe time_zone is specified upon construction, the string will represent the time of that time_zone

my $str1 = $pt1->time_datetime->stringify;
my $str2 = $pt2->time_datetime->stringify;
my $str3 = $pt3->time_datetime->stringify;
my $str4 = $pt4->time_datetime->stringify;

is($str1, '2022-10-25T13:45:00',       "    stringify(): produce time as a string in local timezone (unless time_zone specified in DT object)");
is($str2, '2022-10-25T13:45:00',       "    stringify(): produce time as a string in local timezone (unless time_zone specified in DT object)");
is($str3, '2022-10-25T13:45:00',       "    stringify(): produce time as a string in local timezone (unless time_zone specified in DT object)");
is($str4, '2022-10-25T13:45:00',       "    stringify(): produce time as a string in local timezone (unless time_zone specified in DT object)");

my $str5 = $pt1->time_datetime( time_zone => 'America/Toronto' )->stringify;
my $str6 = $pt2->time_datetime( time_zone => 'America/Toronto' )->stringify;
my $str7 = $pt3->time_datetime( time_zone => 'America/Toronto' )->stringify;
my $str8 = $pt4->time_datetime( time_zone => 'America/Toronto' )->stringify;

is($str5, '2022-10-25T09:45:00',       "    stringify(): produce time as a string in local timezone (unless time_zone specified in DT object)");
is($str6, '2022-10-25T09:45:00',       "    stringify(): produce time as a string in local timezone (unless time_zone specified in DT object)");
is($str7, '2022-10-25T09:45:00',       "    stringify(): produce time as a string in local timezone (unless time_zone specified in DT object)");
is($str8, '2022-10-25T09:45:00',       "    stringify(): produce time as a string in local timezone (unless time_zone specified in DT object)");


# Add a lot of check, questions, etc.
#
# TODO: then document that Gpx has _parse_time becaseu need to parse time for other things than points, tracks, routes, etc.

print "so debug doesn't exit\n";

__DATA__
<?xml version="1.0" encoding="utf-8"?>
<gpx version="1.0">
  <name>Test</name>
  <wpt lat="54.786989" lon="-2.344214">
    <time>2022-10-25T09:45-04:00</time>
  </wpt>
  <wpt lat="54.786989" lon="-2.344214">
    <time>2022-10-25T13:45</time>
  </wpt>
  <wpt lat="54.786989" lon="-2.344214">
    <time>2022-10-25T13:45Z</time>
  </wpt>
  <wpt lat="54.786989" lon="-2.344214">
    <time>2022-10-25T13:45Z</time>
  </wpt>
</gpx>

