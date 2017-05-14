#!perl -w
# date formats
#######################################
use strict;
no strict "vars";
use Date::Interval;
use Date::Manip;
&Date_Init("DateFormat=non-US");

print "1..3\n";
$n = 1;

my ($date1) = &UnixDate ("1998-01-10 23:00:10", "%Y-%m-%d %H:%M:%S");
my ($date2) = 'NOBIND NOW';
my ($int1)  = new Date::Interval ($date1, $date2);
if ($int1->get eq '[10/01/1998, NOBIND NOW)') 
{print "ok $n\n";} else {print "not ok $n\n";} $n++;

Date::Interval->setDisplayFormat("%Y-%m-%d %H:%M:%S");
my ($int2) = new Date::Interval ("1998-01-10 23:00:10", 'NOBIND NOW');
if ($int2->get eq '[1998-01-10 23:00:10, NOBIND NOW)') 
{print "ok $n\n";} else {print "not ok $n\n";} $n++;

my ($a) = 1998;
my ($b) = 01;
my ($c) = 12;
my ($d) = 14;

$date1 = &UnixDate ("$a-$b-$c $d:$d:$d", "%Y-%m-%d %H:%M:%S");
$date2 = 'NOBIND NOW';
my ($int3)  = new Date::Interval ($date1, $date2);
if ($int3->get eq '[1998-01-12 14:14:14, NOBIND NOW)')
{print "ok $n\n";} else {print "not ok $n\n";} $n++;

