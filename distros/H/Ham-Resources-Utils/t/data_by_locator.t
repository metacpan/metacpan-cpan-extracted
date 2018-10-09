#!perl -T

use strict;
use warnings;
use Test::More tests=>24;

my $m = Ham::Resources::Utils->new();
BEGIN { use_ok('Ham::Resources::Utils') };

# Check DATA_BY_LOCATOR() function
my $locator_dep = "JN11cj";
my $locator_arr = "IE38SC";
my $date = "28-6-2012";


ok( defined $m			, 'new() creation');

my %data = $m->data_by_locator($date, $locator_dep, $locator_arr);

ok( $data{"compass"} eq "S"		, 'compass conversion');
ok( int($data{"course_dec"}) == 190	, 'course decimal calculation');
ok( int($data{"course_sexag"}) == 190	, 'course sexagesimal calculation');
ok( $data{"date"} eq "28-6-2012"	, 'date of sun calculation');
ok( $data{"distance_km"} =~ /9375/	, 'distance between points in km');
ok( $data{"distance_mi"} =~ /5825/	, 'distance between point in miles');
ok( $data{"lat_1"} eq "41N23"		, 'latitude point A');
ok( $data{"lat_1_dec"} =~ /41.383/	, 'latitude A in decimal');
ok( $data{"lat_2"} eq " 41S53"		, 'latitude point B');
ok( $data{"lat_2_dec"} =~ /-41.883/		, 'latitude B in decimal');
ok( uc($data{"locator_1"}) eq "JN11CJ42"	, 'locator A');
ok( uc($data{"locator_2"}) eq "IE38SC68"	, 'locator B');
ok( $data{"long_1"} eq "2E12"		, 'longitude point A');
ok( $data{"long_1_dec"} =~ /2.2/	, 'longitude A in decimal');
ok( $data{"long_2"} eq " 12W27"		, 'longitude point B');
ok( $data{"long_2_dec"} =~ /-12.45/	, 'longitude B in decimal');

ok( $data{"midday_arrive"} eq "12h 53m"	, 'midday at point B');
ok( $data{"midday_departure"} eq "11h 54m" , 'midday at point A');
ok( $data{"sunrise_arrive"} eq "8h 18m"	, 'sunrise at point B');
ok( $data{"sunrise_departure"} eq "4h 20m" , 'sunrise at point A');
ok( $data{"sunset_arrive"} eq  "17h 28m"   , 'sunset at point B');
ok( $data{"sunset_departure"} eq "19h 28m" , 'sunset at point A');

done_testing();
