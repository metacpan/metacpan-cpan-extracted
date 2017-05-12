#!perl -w

use strict;
no strict "vars";

use Interval;
use Date::Manip;

print "1..17\n";
$n = 1;

# Overlaps
####################
$int1 = new Interval ("today", "tomorrow");		
$int2 = new Interval ("yesterday", "tomorrow");
if ($int1->overlaps($int2)) 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# Right Overlap
####################
$int301 = new Interval ("10/10/97", "20/10/97"); 
$int302 = new Interval ("2/10/97", "15/10/97");
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
$int301 = new Interval ("01/10/97", "12/10/97");
$int302 = new Interval ("10/10/97", "15/10/97");
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
$int301 = new Interval ("10/10/97", "12/10/97");
$int302 = new Interval ("5/10/97", "15/10/97");
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
$int301 = new Interval ("10/10/97", "20/10/97");
$int302 = new Interval ("15/10/97", "17/10/97");
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
