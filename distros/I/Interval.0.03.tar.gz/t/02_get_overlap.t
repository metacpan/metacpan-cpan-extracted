#!perl -w
# Get overlap and getStart and getStop
use strict;
no strict "vars";
use Interval;
use Date::Manip;
Date::Interval->setDisplayFormat("%Y-%m-%d"); # To make it more readable to my self
&Date_Init("DateFormat=non-US");
$, = ',';
print "1..6\n";
$n = 1;

my $int201 = new Date::Interval ("10/10/97", "20/10/97"); 
my $int204 = new Date::Interval ("02/10/97", "30/10/97");
my $int205 = new Date::Interval ("02/10/97", "15/10/97");
my $int206 = new Date::Interval ("10/10/97", "15/10/97");
my $int207 = new Date::Interval ("15/10/97", "30/10/97");
my $int208 = new Date::Interval ("12/10/97", "14/10/97");

my $int209 = new Date::Interval ("1/10/97", "1/10/97");
my $int210 = new Date::Interval ("20/10/97", "20/10/97");
my $int211 = new Date::Interval ("14/10/97", "14/10/97");

$rt = $int201->getOverlap ($int204);
if ($rt->get eq '[1997-10-10, 1997-10-20)') {print "ok $n\n";} else {print "not ok $n\n";} $n++;

$rt = $int201->getOverlap ($int205);
if ($rt->get eq '[1997-10-10, 1997-10-15)') {print "ok $n\n";} else {print "not ok $n\n";} $n++;

$rt = $int201->getOverlap ($int206);
if ($rt->get eq '[1997-10-10, 1997-10-15)') {print "ok $n\n";} else {print "not ok $n\n";} $n++;

$rt = $int201->getOverlap ($int207);
if ($rt->get eq '[1997-10-15, 1997-10-20)') {print "ok $n\n";} else {print "not ok $n\n";} $n++;

$rt = $int201->getOverlap ($int208);
if ($rt->get eq '[1997-10-12, 1997-10-14)') {print "ok $n\n";} else {print "not ok $n\n";} $n++;

$rt = $int201->getOverlap ($int211);
if ($rt->get eq '[1997-10-14, 1997-10-14)') {print "ok $n\n";} else {print "not ok $n\n";} $n++;
