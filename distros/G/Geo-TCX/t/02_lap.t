# t/02_lap.t - testing file for Lap.pm
use strict;
use warnings;

use Test::More tests => 60;
use Geo::TCX;

my $a1 = Geo::TCX->new('t/2022-08-21-00-34-06.tcx');
my $l  = $a1->lap(1);

isa_ok($l, 'Geo::TCX::Lap');

#
# Section A - Object Methods - with Activities

my $a2 = Geo::TCX->new('t/2014-08-11-10-25-15.tcx');
my $l1 = $a2->lap(1);
my $l2 = $a2->lap(2);
my $l3 = $a2->lap(3);
isa_ok($l2, 'Geo::TCX::Lap');
# If refer to a lap that doesn't exists, croaks with 'Lap 5 does not exist in the current file', I think that's what I want 
# e.g.  $a2->lap(5);

# actually a test of Trackpoint::distance_elapased, but need to test here
is  ($l1->trackpoint(1)->distance_elapsed, $l1->trackpoint(1)->DistanceMeters, "    distance_elapsed should be the same as DistanceMeters for the first point of the first lap");
isnt($l2->trackpoint(1)->distance_elapsed, $l2->trackpoint(1)->DistanceMeters, "    distance_elapsed should not be the same ... for the first point of laps other that the first lap");
isnt($l3->trackpoint(1)->distance_elapsed, $l3->trackpoint(1)->DistanceMeters, "    distance_elapsed should not be the same ... for the first point of laps other that the first lap");

#
# AUTOLOAD methods

is($l2->AverageHeartRateBpm, 159,                   "    AverageHeartRateBpm, AUTOLOAD method");
is($l2->Cadence,             undef,                 "    Cadence, AUTOLOAD method");
is($l2->Calories,            151,                   "    Calories, AUTOLOAD method");
is($l2->DistanceMeters,     '928.242920',           "    DistanceMeters, AUTOLOAD method");
is($l2->Intensity,          'Active',               "    Intensity, AUTOLOAD method");
is($l2->MaximumHeartRateBpm, 172,                   "    MaximumHeartRateBpm AUTOLOAD method");
is($l2->MaximumSpeed,       '3.355000',             "    MaximumSpeed AUTOLOAD method");
is($l2->StartTime,          '2014-08-11T10:34:04Z', "    StartTime AUTOLOAD method");
is($l2->TotalTimeSeconds,    459.82,                "    TotalTimeSeconds AUTOLOAD method");
is($l2->TriggerMethod,      'Manual',               "    TriggerMethod AUTOLOAD method");
is($l2->BeginPosition,      undef,                  "    BeginPosition AUTOLOAD method");
is($l2->EndPosition,        undef,                  "    EndPosition AUTOLOAD method");
# last 2 are only for courses

#
# is_activity()
is($l2->is_activity, 1,             "    is_activity()");
is($l2->is_course,   0,             "    is_course()");
 
#
# time_add(), time_subtract
my $c = $l->clone;
$c->time_add( DateTime::Duration->new( years => 2, months => 6, days => 2, minutes => 21, seconds => 15 ));
is($c->StartTime,            '2025-02-23T00:55:21Z',    "    time_add(): ensure StartTime is also adjusted");
is($c->trackpoint(1)->Time,  '2025-02-23T00:55:22Z',    "    time_add(): check time of first point");
is($c->trackpoint(-1)->Time, '2025-02-23T00:55:48Z',    "    time_add(): check time of last point");
$c->time_subtract( DateTime::Duration->new( years => 8, seconds => 75 ));
is($c->StartTime,            '2017-02-23T00:54:06Z',    "    time_add(): ensure StartTime is also adjusted");
is($c->trackpoint(1)->Time,  '2017-02-23T00:54:07Z',    "    time_add(): check time of first point");
is($c->trackpoint(-1)->Time, '2017-02-23T00:54:33Z',    "    time_add(): check time of last point");

#
# distance_add(), distance_subtract(), distance_net()

# these methods are from Track but best tests here with laps, plus we inherit so

my $clone1 = $l1->clone; 
my $clone2 = $l2->clone; 
my $clone3 = $l3->clone; 
$clone1->distance_add( 1000 );
$clone2->distance_subtract( 50 );
$clone3->distance_net;
is($clone1->trackpoint(1)->DistanceMeters, $l1->trackpoint(1)->DistanceMeters + 1000, 
                                "    distance_add(): compare with original lap's first trackpoint");
is($clone2->trackpoint(1)->DistanceMeters, $l2->trackpoint(1)->DistanceMeters - 50, 
                                "    distance_subtract(): compare with original lap's first trackpoint");
is($clone3->trackpoint(1)->DistanceMeters, '4.509', 
                                "    distance_net(): the first trackpoint Distance meters should be 0");

#
# split()

my ($la, $lb) = $l1->split(8);
is($la->trackpoints,   8,           "   split(): test that we get right number of trackpoints");
is($lb->trackpoints, 107,           "   split(): test that we get right number of trackpoints");
# we should actually check something more precise, like the time of the 1st and last trackpoints of each
is($l1->trackpoints, 115,                             "   split(): test that the lap used for the split is left intact");

#
# split_at_point_closest_to()  -- a Track.pm method but I also want to test it here

my $coord_str = '45.30181 -72.64558';   # M97 et rue de Nicolet
($la, $lb) = $l1->split_at_point_closest_to( $coord_str );
is($la->trackpoints, 64,             "   split(): test that we get right number of trackpoints");
is($lb->trackpoints, 51,             "   split(): test that we get right number of trackpoints");
# we should actually check something more precise, like the time of the 1st and last trackpoints of each

#
# merge()
my $m = $la->merge($lb);
is($m->trackpoints, 115,            "   merge(): test that we get right number of trackpoints");
# TODO: add more tests
is($la->trackpoints, 64,                             "   merge(): test that the laps used for the merge are left intact");
is($lb->trackpoints, 51,                             "   merge(): test that the laps used for the merge are left intact");

#
# Section B - Object Methods - with Courses

my $c1 = Geo::TCX->new('t/2022-08-21-00-34-06_rwg_course.tcx');
isa_ok ($c1, 'Geo::TCX');

$l = $c1->lap(1);
isa_ok ($l, 'Geo::TCX::Lap');

#
# AUTOLOAD methods

isa_ok( $l->BeginPosition, 'Geo::TCX::Trackpoint');
isa_ok( $l->EndPosition,   'Geo::TCX::Trackpoint');

# ones only for courses
 
is($l->BeginPosition->LatitudeDegrees,  '45.408728',    "    BeginPosition AUTOLOAD method");
is($l->BeginPosition->LongitudeDegrees, '-75.757339',   "    BeginPosition AUTOLOAD method");
is($l->EndPosition->LatitudeDegrees,    '45.409282',    "    EndPosition AUTOLOAD method");
is($l->EndPosition->LongitudeDegrees,   '-75.756993',   "    EndPosition AUTOLOAD method");

# common to both activities and courses (I think)
is($l->DistanceMeters,     '795.6',     "    DistanceMeters, AUTOLOAD method");
is($l->Intensity,          'Active',        "    Intensity, AUTOLOAD method");
is($l->TotalTimeSeconds,   '180',         "    TotalTimeSeconds AUTOLOAD method");

# ones only for activities (I think)
is($l->AverageHeartRateBpm, undef,          "    AverageHeartRateBpm, AUTOLOAD method");
is($l->Cadence,             undef,          "    Cadence, AUTOLOAD method");
is($l->Calories,            undef,          "    Calories, AUTOLOAD method");
is($l->MaximumHeartRateBpm, undef,          "    MaximumHeartRateBpm AUTOLOAD method");
is($l->MaximumSpeed,        undef,          "    MaximumSpeed AUTOLOAD method");
is($l->TriggerMethod,       undef,          "    TriggerMethod AUTOLOAD method");
is($l->StartTime,           undef,          "    StartTime AUTOLOAD method");


#
# is_course()
is($l->is_course,   1,              "    is_course()");
is($l->is_activity, 0,              "    is_activity()");

# TODO: test other lap fields
 
#
# reverse()
 
# croak if used on an activity lap;
# $a1->lap(1)->reverse();

$l = $c1->lap(1);
my $first_tp_orig = $l->trackpoint( 1);
my $last_tp_orig  = $l->trackpoint(-1);

my $dml =  $l->DistanceMeters;  
my $ttsl = $l->TotalTimeSeconds;

my $r = $l->reverse();
is($r->EndPosition->LatitudeDegrees,    $first_tp_orig->LatitudeDegrees,
                        "    reverse(): compare lattitude of EndPosition with first trackpoint of original lap");
is($r->BeginPosition->LatitudeDegrees,  $last_tp_orig->LatitudeDegrees,
                        "    reverse(): compare lattitude of BeginPosition with last trackpoint of original lap");
is($r->EndPosition->LongitudeDegrees,   $first_tp_orig->LongitudeDegrees,
                        "    reverse(): compare longitude of EndPosition with first trackpoint of original lap");
is($r->BeginPosition->LongitudeDegrees, $last_tp_orig->LongitudeDegrees,
                        "    reverse(): compare longitude of BeginPosition with last trackpoint of original lap");

my $dmr =  $r->DistanceMeters;  
my $ttsr = $r->TotalTimeSeconds;

# $r = $l->reverse( recalculate_distance => 1);      potential option not implemented yet

print "so debugger doesn't exit\n";
