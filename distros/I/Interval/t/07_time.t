#!perl -w
# use times without date
########################
use strict;
no strict "vars";
use Interval;
use Date::Manip;
&Date_Init("DateFormat=non-US");
Date::Interval->setDisplayFormat( "%H:%M:%S"); # Discard the date

print "1..10\n";
$n = 1;

$int1 = new Date::Interval ("10:03:03", "11:30:30");		
$int2 = new Date::Interval ("12:03:03", "12:30:30");		
$int3 = new Date::Interval ("10:03:03", "11:30:30");		

if($int1->get eq '[10:03:03, 11:30:30)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if($int1->length eq '+0:0:0:0:1:27:27')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($int1<$int2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($int1>$int2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($int1==$int2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($int1!=$int2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($int1<$int3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($int1>$int3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($int1==$int3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($int1!=$int3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
