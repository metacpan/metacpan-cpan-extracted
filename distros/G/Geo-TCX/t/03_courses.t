# t/03_BRTcourse.t - main testing file (until I can rename it to something more specific)
use strict;
use warnings;

use Test::More tests => 2;
use Geo::TCX;
use File::Temp qw/ tempfile tempdir /;

my $temp_dir = tempdir( CLEANUP => 1 );

my $c = Geo::TCX->new('t/2022-08-21-00-34-06_rwg_course.tcx');
isa_ok ($c, 'Geo::TCX');
is($c->laps, 1,             "    laps(): exactly 1 lap");
# ... no need to test multi-lap courses, recently realised that multilap courses do not make sense eventhough I support saving them (yah, contradiction - comment this in Notes)

# history files that is the source of the course above
my $h = Geo::TCX->new('t/2022-08-21-00-34-06_rwg_course.tcx');

my $l = $h->lap(1);
$l->xml_string( course => 1 );

$h->set_wd( $temp_dir );
$h->save_laps( course => 1 , force => 1, indent => 1);
$h->set_wd( '-' );

#
# Section B - Methods and fields not appropriate for Courses

# THINK about: what is the behaviour I want for these? return undef? warn? croak?

# TODO: activity() - Test for courses, it should croak I think if it tries to set, undef if it accesses?  not sure yet.

#   my $ret = $l->StartTime
# we will get undef if we try to get the StartTime field, is this ok?  Should be fix that?  Think about it


print "so debugger doesn't exit";

