#!perl -w

# Version and constructors
##########################
use strict;
no strict "vars";

use Interval;
use Date::Manip;

print "1..3\n";
$n = 1;
if ($Interval::VERSION eq "0.01")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$d1 = &ParseDate ("10/10/97");
$d2 = &ParseDate ("15/10/97");
$int1 = new Interval ($d1, $d2);
if ($int1->get eq '[1997-10-10, 1997-10-15)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int2 = new Interval ("10/10/97", "15/10/97");
if ($int2->get eq '[1997-10-10, 1997-10-15)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
