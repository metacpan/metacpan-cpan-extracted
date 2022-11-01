# t/01_main.t - main testing file (for TCX.pm)
use strict;
use warnings;

use Test::More tests => 50;
use Geo::TCX;
use File::Temp qw/ tempfile tempdir /;

my $tmp_dir = tempdir( CLEANUP => 1 );

my $o  = Geo::TCX->new('t/2014-08-11-10-25-15.tcx');
my $oo = Geo::TCX->new('t/2022-08-21-00-34-06_rwg_course.tcx');
isa_ok ($o,  'Geo::TCX');
isa_ok ($oo, 'Geo::TCX');

my $for_delete = $o->clone;
my $for_keep   = $o->clone;

#
# Section A - Object Methods

#
# lap(), laps()

is($o->laps, 4,                     "    laps(): test number of laps returned");
my $l1 = $o->lap(1);
my $l2 = $o->lap(2);
my $l3 = $o->lap(3);
my $l4 = $o->lap(-1);
isa_ok($l1, 'Geo::TCX::Lap');
isa_ok($l2, 'Geo::TCX::Lap');
isa_ok($l3, 'Geo::TCX::Lap');
isa_ok($l4, 'Geo::TCX::Lap');
my @laps = $o->laps( -3, 4 );
is($laps[0]->StartTime, '2014-08-11T10:34:04Z',  "    lap(): test whether returned laps 2 and 4");
is($laps[1]->StartTime, '2014-08-11T10:54:47Z',  "    lap(): test whether returned laps 2 and 4");
@laps = $o->laps( 1, -2 );
is($laps[0]->StartTime, '2014-08-11T10:25:15Z',  "    lap(): test whether returned laps 1 and 3");
is($laps[1]->StartTime, '2014-08-11T10:42:33Z',  "    lap(): test whether returned laps 3 and 3");

#
# delete_lap(), keep_lap()

my (@d1, @d2, @d3, @d4, @k2, @k4);
@d2 = $for_delete->delete_lap(2);
is($d2[0]->StartTime, '2014-08-11T10:34:04Z',             "    delete_lap(): test that lap 2 was deleted");
@d4 = $for_delete->delete_lap(-1);
is($d4[0]->StartTime, '2014-08-11T10:54:47Z',             "    delete_lap(): test that lap 4 was deleted");

@d1 = $for_delete->delete_lap(1);
is($d1[0]->StartTime, '2014-08-11T10:25:15Z',             "    delete_lap(): test that lap 3 was deleted");
@d3 = $for_delete->delete_lap(-1);
is($d3[0]->StartTime, '2014-08-11T10:42:33Z',             "    delete_lap(): test that lap 1 was deleted");

@k2 = $for_keep->keep_lap(2);
is($for_keep->lap(1)->StartTime, '2014-08-11T10:34:04Z',  "    keep_lap(): test that lap 2 was kept");
@k4 = $for_keep   = $o->clone;
is($for_keep->lap(-1)->StartTime, '2014-08-11T10:54:47Z', "    keep_lap(): test that lap 4 was kept");

#
# save_laps()

$o->set_wd( $tmp_dir  );
$o->save_laps(force => 1 );
$o->save_laps(force => 1, indent => 1 );
$o->set_wd( '-' );
# design some test statements, for now, just testing that it doesn't carp or croak and visualing the saved files in vim, beta testing with pytrainer
# currently testing option 'course' in 03_courses.t but I should bring that test here, easier to compare both in the same test file

#
# is_activity(), is_course()

is($o->is_activity,   1,               "    is_activity(): true");
is($o->is_course,    '',               "    is_activity(): false");
is($oo->is_activity, '',               "    is_activity(): false");
is($oo->is_course,    1,               "    is_activity(): true");

#
# activity()

$o->activity('Running');
is($o->activity, 'Running',         "    activity(): test that activity set to 'Running'");
$o->activity('Biking');
is($o->activity, 'Biking',          "    activity(): test that activity set to 'Biking'");

#
# author()

my $href = $o->author;
is($href->{Name},   'EDGE705',         "    author(): name is EDGE 705");
$o->author( Name => 'geo-tcx' );
is($href->{Name},   'geo-tcx',         "    author(): name is yours truly");
$o->author( Name => 'EDGE705' );
is($href->{Name},   'EDGE705',         "    author(): we set it back to EDGE 705");

# I don't think I wan't to test cd(), prefer to beta test it instead

#
# test time_add()
#
$o->time_add( days => 1, hours => 2, seconds => 5 );
is($l1->StartTime, '2014-08-12T12:25:20Z',             "    time_add(): test whether StartTime is incremented propoerly");
is($l1->trackpoint(2)->Time,  '2014-08-12T12:25:28Z',  "    time_add(): test whether trackpoint 2 of lap 1 is incremented propoerly");
is($l2->trackpoint(-1)->Time, '2014-08-12T12:42:38Z',  "    time_add(): test whether last trackpoint 2 of lap 3 is incremented propoerly");

#
# test time_subtract()

$o->time_subtract( days => 3, hours => 9, seconds => 15 );
is($l1->StartTime, '2014-08-09T03:25:05Z',             "    time_subtract(): test whether StartTime is incremented propoerly");
is($l1->trackpoint(2)->Time,  '2014-08-09T03:25:13Z',  "    time_subtract(): test whether trackpoint 2 of lap 1 is incremented propoerly");
is($l2->trackpoint(-1)->Time, '2014-08-09T03:42:23Z',  "    time_subtract(): test whether last trackpoint 2 of lap 3 is incremented propoerly");

#
# test clone()

my $o2 = Geo::TCX->new ('t/2022-08-21-00-34-06.tcx');
my $c = $o2->clone();
isa_ok ($c, 'Geo::TCX');
# is_deeply ($c, $o2,                 "    clone(): compares if the deep strcutures are the same");
# is_deeply does not work because of operator overloading in Lap.pm.
# alternatively, we can visually inspect that there are no reused addresses (other than Begin/EndPosition if the clone is a course)

#
# test split_lap()

$o->split_lap(4, 10);
is($o->lap(4)->trackpoints, 10,             "   split_lap(): test that we get right number of trackpoints");
is($o->lap(5)->trackpoints,  7,             "   split_lap(): test that we get right number of trackpoints");
$o->split_lap(3, 45);
is($o->lap(3)->trackpoints, 45,             "   split_lap(): test that we get right number of trackpoints");
is($o->lap(4)->trackpoints, 70,             "   split_lap(): test that we get right number of trackpoints");
is($o->lap(5)->trackpoints, 10,             "   split_lap(): test that we get right number of trackpoints");
is($o->lap(6)->trackpoints,  7,             "   split_lap(): test that we get right number of trackpoints");

#
# test split_lap_at_point_closest_to()

my $coord_str = '45.29676 -72.65150';       # Rue Buck et C14 Divine
$o->split_lap_at_point_closest_to( 2, $coord_str );
is($o->lap(4)->trackpoints, 45,             "   split_lap(): test that we get right number of trackpoints");
is($o->lap(5)->trackpoints, 70,             "   split_lap(): test that we get right number of trackpoints");
is($o->lap(2)->trackpoints, 95,             "   split_lap(): test that we get right number of trackpoints");
is($o->lap(3)->trackpoints, 12,             "   split_lap(): test that we get right number of trackpoints");
# we should actually check something more precise, like the time of the 1st and last trackpoints of each

#
# test merge_laps()

my $a = $o->lap(5);
my $b = $o->lap(6);
$o->merge_laps(5, 6);
is($o->laps, 6,                             "   merge_laps(): test that we get right number of laps");
is($o->lap(5)->trackpoints, 80,             "   merge_laps(): test that we get right number of trackpoints");
is($o->lap(5)->DistanceMeters, 546.482,     "   merge_laps(): test lap aggregates");
is($o->lap(5)->TotalTimeSeconds, 417.34,    "   merge_laps(): test lap aggregates");

#
# activity_to_course()

my $course;
$course = $o->activity_to_course(lap => 2, filename => 'my-acadian-day-test.tcx', course_name => 'Bromont-Acadian', work_dir => '/tmp');
isa_ok($course, 'Geo::TCX');
is($course->lap(1)->is_course,   1,         "    is_course()");
$course->save_laps(force => 1);
# ... why did we do save laps above and not save()?  Maybe I hadn't coded save yet...

my $oo9 = Geo::TCX->new('t/2022-08-21-00-34-06.tcx');
my $course2;
$course2 = $oo9->activity_to_course(filename => 'Bate Island.tcx', course_name => 'Ile Bate', work_dir => $tmp_dir );
isa_ok($course2, 'Geo::TCX');
$course2->save(force => 1);


# some useful test constructs
# ok( defined $thisvar,			    "	test comment");
# is(2, 2, "    test comment");
# like($thatvar, qr/a regex/,	    "	test comment");

print "so debugger doesn't exit\n";

