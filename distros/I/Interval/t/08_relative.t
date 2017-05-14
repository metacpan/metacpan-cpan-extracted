#!perl -w
# Relative intervals
########################
use strict;
no strict "vars";
use Interval;
use Date::Manip;
&Date_Init("DateFormat=non-US");
Date::Interval->setDisplayFormat("%Y-%m-%d");

print "1..23\n";
$n = 1;

$int1 = new Date::Interval ('1997-10-30', 'NOBIND NOW');
if($int1->get eq '[1997-10-30, NOBIND NOW)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int2 = new Date::Interval("2097-10-30", 'NOBIND NOW');
if($int2->get eq '[2097-10-30, NOBIND NOW)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int3 = new Date::Interval('NOBIND NOW', 'NOBIND NOW');
if($int3->get eq '[NOBIND NOW, NOBIND NOW)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int4 = new Date::Interval('NOBIND NOW', 'NOBIND 0:0:11:0:0:0');
if($int4->get eq '[NOBIND NOW, 0:0:11:0:0:0)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int5 = new Date::Interval('NOBIND NOW', 'NOBIND 2 business days');
if($int5->get eq '[NOBIND NOW, 2 business days)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int6 = new Date::Interval('NOBIND 4 days', 'NOBIND 6 days');
if($int6->get eq '[4 days, 6 days)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int7 = new Date::Interval('NOBIND 0:1:0:0:0:0:0', 'NOBIND 1:0:0:11:0:0:0');
if($int7->get eq '[0:1:0:0:0:0:0, 1:0:0:11:0:0:0)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int8 = new Date::Interval('NOBIND 0:1:0:0:0:0:0', 'NOBIND 0:2:0:11:0:0:0');
$int9 = new Date::Interval('NOBIND 0:3:0:0:0:0:0', 'NOBIND 1:0:11:0:0:0:0');
if($int8 < $int9)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int8 > $int9))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int8 == $int9))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if($int8 != $int9)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int10 = new Date::Interval('NOBIND 14 days', 'NOBIND 16 days');
$int11 = new Date::Interval('NOBIND 7 days', 'NOBIND 9 days');
if(!($int10 < $int11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if($int10 > $int11)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int10 == $int11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if($int10 != $int11)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int12 = new Date::Interval('30-10-1996', '01-11-1996');
$int13 = new Date::Interval('NOBIND 7 days', 'NOBIND 9 days');
if($int12 < $int13)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int12 > $int13))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int12 == $int13))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if($int12 != $int13)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int14 = new Date::Interval ('NOBIND 7 days', 'NOBIND 9 days');
$int15 = new Date::Interval ('30-10-1996', '01-11-1996');

if(!($int14 < $int15))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if($int14 > $int15)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int14 == $int15))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if($int14 != $int15)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

