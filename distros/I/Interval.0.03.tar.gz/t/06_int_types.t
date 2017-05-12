#!perl -w

use Interval;
use Date::Manip;
&Date_Init("DateFormat=non-US");
Date::Interval->setDisplayFormat("%Y-%m-%d");
$, = ',';

print "1..4\n";
$n=1;
$int1 = new Date::Interval ("10/10/97", "20/10/97", $Date::Interval::CLOSED_INT); 
if ($int1->get eq '[1997-10-10, 1997-10-20]') 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lo_int = new Date::Interval ("10/10/97", "20/10/97", $Date::Interval::LEFT_OPEN_INT); 
if ($lo_int->get eq '(1997-10-10, 1997-10-20]') 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ro_int = new Date::Interval ("10/10/97", "20/10/97", $Date::Interval::RIGHT_OPEN_INT); 
if ($ro_int->get eq '[1997-10-10, 1997-10-20)') 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$open_int = new Date::Interval ("10/10/97", "20/10/97", $Date::Interval::OPEN_INT); 
if ($open_int->get eq '(1997-10-10, 1997-10-20)') 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;




