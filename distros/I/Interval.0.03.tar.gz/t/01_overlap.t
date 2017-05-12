#!perl -w

use strict;
no strict "vars";

use Interval;
use Date::Manip;
Date::Interval->setDisplayFormat("%Y-%m-%d"); # To make it more readable to my self
&Date_Init("DateFormat=non-US");
$, = ',';

print "1..17\n";
$n = 1;

# Overlaps
####################
$int1 = new Date::Interval ("today", "tomorrow");		
$int2 = new Date::Interval ("yesterday", "tomorrow");
if ($int1->overlaps($int2)) 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# Right Overlap
####################
$int301 = new Date::Interval ("10/10/97", "20/10/97"); 
$int302 = new Date::Interval ("2/10/97", "15/10/97");
if (!$int301->leftOverlaps ($int302))     
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($int301->rightOverlaps ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$int301->during ($int302)) 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$int301->totallyOverlaps ($int302))   
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# left Overlap
# ####################
$int301 = new Date::Interval ("01/10/97", "12/10/97");
$int302 = new Date::Interval ("10/10/97", "15/10/97");
if ($int301->leftOverlaps ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$int301->rightOverlaps ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$int301->during ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$int301->totallyOverlaps ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# Inclusion Overlap
####################
$int301 = new Date::Interval ("10/10/97", "12/10/97");
$int302 = new Date::Interval ("5/10/97", "15/10/97");
if (!$int301->leftOverlaps ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$int301->rightOverlaps ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($int301->during ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$int301->totallyOverlaps ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# Total Overlap
####################
$int301 = new Date::Interval ("10/10/97", "20/10/97");
$int302 = new Date::Interval ("15/10/97", "17/10/97");
if (!$int301->leftOverlaps ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$int301->rightOverlaps ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$int301->during ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($int301->totallyOverlaps ($int302))
{print "ok $n\n";} else {print "not ok $n\n";}
