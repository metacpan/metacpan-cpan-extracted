#!perl -w

# Overloaded methods
####################
use strict;
no strict "vars";

use Interval;
use Date::Manip;
Date::Interval->setDisplayFormat("%Y-%m-%d"); # To make it more readable to my self
&Date_Init("DateFormat=non-US");
$, = ',';

print "1..24\n";
$n = 1;

$int601 = new Date::Interval ("10/10/97", "15/10/97"); 
$int602 = new Date::Interval ("12/10/97", "20/10/97");
$int605 = new Date::Interval ("18/10/97", "22/10/97");

### + ###
$int603 = $int601 + $int602;
if($int603->get eq '[1997-10-10, 1997-10-20)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int604 = $int601 - $int602;
if($int604->get eq '[1997-10-10, 1997-10-12)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int606 = $int601 + $int602 + $int605;
if($int606->get eq '[1997-10-10, 1997-10-22)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

### - ###
$int611 = new Date::Interval ("10/10/97", "15/10/97");
$int612 = new Date::Interval ("02/10/97", "12/10/97");
$int613 = $int611 - $int612;
if($int613->get eq '[1997-10-12, 1997-10-15)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int621 = new Date::Interval ("10/10/97", "15/10/97");
$int622 = new Date::Interval ("15/10/97", "20/10/97");
$int623 = $int621 - $int622;
if($int623->get eq '[1997-10-10, 1997-10-15)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int631 = new Date::Interval ("10/10/97", "15/10/97");
$int632 = new Date::Interval ("05/10/97", "10/10/97");
$int633 = $int631 - $int632;
if($int633->get eq '[1997-10-10, 1997-10-15)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int641 = new Date::Interval ("10/10/97", "15/10/97");
$int642 = new Date::Interval ("05/10/97", "20/10/97");
$int643 = $int641 - $int642;
if($int643->get eq '<empty>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int651 = new Date::Interval ("10/10/97", "15/10/97");
$int652 = new Date::Interval ("12/10/97", "14/10/97");
$int653 = $int651 - $int652;
if($int653->get eq '[1997-10-10, 1997-10-12)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# TODO Make to use overloaded operator
my ($int_1, $int_2) = $int651->_minus($int652);
if ($int_1->get eq '[1997-10-10, 1997-10-12)' &&
    $int_2->get eq '[1997-10-14, 1997-10-15)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# less than <, > ==, !=   
#######################
$int1 = new Date::Interval ("11/11/97", "22/11/97");
$int2 = new Date::Interval ("11/11/98", "22/11/98");
if($int1 < $int2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int1 > $int2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int1 == $int2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if($int1 != $int2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# greater than <, > ==, !=   
##########################
$int1 = new Date::Interval ("11/11/97", "22/11/97");
$int2 = new Date::Interval ("01/03/96", "05/07/96");
if(!($int1 < $int2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if($int1 > $int2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int1 == $int2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if($int1 != $int2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# equal <, > ==, !=   
##########################
$int1 = new Date::Interval ("01/03/96", "05/07/96");
$int2 = new Date::Interval ("01/03/96", "05/07/96");
if(!($int1 < $int2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int1 > $int2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if($int1 == $int2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(!($int1 != $int2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

#  <=>
####################
$int1 = new Date::Interval ("11/11/97", "22/11/97");
$int2 = new Date::Interval ("11/11/98", "22/11/98");
#$int3 = new Date::Interval ("11/11/99", "22/11/99");

# Do not try this at home using "private" methods
if(&Date::Interval::_spaceship ($int1, $int2) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(&Date::Interval::_spaceship ($int1, $int1) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if(&Date::Interval::_spaceship ($int2, $int1) ==1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;


#$test[0] = $int3;
#$test[1] = $int1;
#$test[2] = $int2;
#$test[3] = $int2;
#$test[4] = $int3;
#print "@test\n";
#@test = sort { $a <=> $b } @test;
#print "@test\n";


