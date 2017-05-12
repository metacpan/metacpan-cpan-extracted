# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan); 
use FileHandle;
use strict;
use warnings;

# of if you know how many tests there will be...
# use Test::More tests => 1;
# use Geo::Track::Log;
 BEGIN { use_ok('Geo::Track::Log') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is (1,1, 'okay');

my $st;
my $trk = new Geo::Track::Log;

$st = qq(38? 18' 11.5" -123?  3' 27.8" 0.0 WGS84   ADV2 "CRTD 14:37 15-OCT-00");

my $pt = $trk->fixGarnixWayLine($st);
is($pt->{name}, "ADV2", "fixGarnixWayLine Check name");

$st = qq(33� 47' 14.77" -117� 51' 12.67" 55.0 WGS84 "FELIX CAFE" "CRTD Comment" [knife N];);

$pt = $trk->fixGarnixWayLine($st);
is($pt->{name}, "FELIX CAFE", "fixGarnixWayLine Check name with space");



exit;
# ok is okay, but doesn't return the actual and expected values...
is(sprintf("%.4f",  $pt->{lat}),   44.0592, "fixGarnixWayLine Check latitude");
is(sprintf("%.4f",  $pt->{lat}),   44.0592, "fixGarnixWayLine Check latitude");

is(sprintf("%.4f", $pt->{long}), -123.0834, "fixGarnixWayLine Check longitude");
isnt(sprintf("%.4f", $pt->{long}), -124.0834, "fixGarnixWayLine ");
is($pt->{date}, "2004-07-12", "fixGarnixWayLine Check date");
is($pt->{date}, "2004-07-12", "fixGarnixWayLine Check date");

ok(1,'Tests done');
