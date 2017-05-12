#!perl -w

use Interval;

print "1..4\n";
$n=1;
$int1 = new Interval ("10/10/97", "20/10/97", $Interval::CLOSED_INT); 
if ($int1->get eq '[1997-10-10, 1997-10-20]') 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$lo_int = new Interval ("10/10/97", "20/10/97", $Interval::LEFT_OPEN_INT); 
if ($lo_int->get eq '(1997-10-10, 1997-10-20]') 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ro_int = new Interval ("10/10/97", "20/10/97", $Interval::RIGHT_OPEN_INT); 
if ($ro_int->get eq '[1997-10-10, 1997-10-20)') 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$open_int = new Interval ("10/10/97", "20/10/97", $Interval::OPEN_INT); 
if ($open_int->get eq '(1997-10-10, 1997-10-20)') 
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;




