#!perl -w
# Test of class methods
##############################
use Interval;

print "1..6\n";
$n = 1;

if (Interval->getDefaultIntervalType eq $Interval::RIGHT_OPEN_INT)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$i1 = new Interval ("10/10/97", "20/10/97"); 
if ($i1->get eq '[1997-10-10, 1997-10-20)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Interval->setDefaultIntervalType ($Interval::OPEN_INT); 
$i2 = new Interval ("10/10/97", "20/10/97"); 
if ($i2->get eq '(1997-10-10, 1997-10-20)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Interval->setDefaultIntervalType ($Interval::LEFT_OPEN_INT); 
$i3 = new Interval ("10/10/97", "20/10/97"); 
if ($i3->get eq '(1997-10-10, 1997-10-20]')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Interval->setDefaultIntervalType ($Interval::CLOSED_INT); 
$i4 = new Interval ("10/10/97", "20/10/97"); 
if ($i4->get eq '[1997-10-10, 1997-10-20]')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

Interval->setDisplayFormat ("%Y-%m-%d %H:%M:%S");
$i5 = new Interval ("10/10/97", "20/10/97"); 
if ($i5->get eq '[1997-10-10 00:00:00, 1997-10-20 00:00:00]')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;




