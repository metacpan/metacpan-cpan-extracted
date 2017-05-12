#!perl -w

# Overloaded methods
####################
use strict;
no strict "vars";

use Interval;
print "1..8\n";
$n = 1;

$int601 = new Interval ("10/10/97", "15/10/97"); 
$int602 = new Interval ("12/10/97", "20/10/97");
$int605 = new Interval ("18/10/97", "22/10/97");

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
$int611 = new Interval ("10/10/97","15/10/97");
$int612 = new Interval ("02/10/97", "12/10/97");
$int613 = $int611 - $int612;
if($int613->get eq '[1997-10-12, 1997-10-15)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int621 = new Interval ("10/10/97", "15/10/97");
$int622 = new Interval ("15/10/97", "20/10/97");
$int623 = $int621 - $int622;
if($int623->get eq '[1997-10-10, 1997-10-15)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int631 = new Interval ("10/10/97", "15/10/97");
$int632 = new Interval ("05/10/97", "10/10/97");
$int633 = $int631 - $int632;
if($int633->get eq '[1997-10-10, 1997-10-15)')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int641 = new Interval ("10/10/97", "15/10/97");
$int642 = new Interval ("05/10/97", "20/10/97");
$int643 = $int641 - $int642;
if($int643->get eq '<empty>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$int651 = new Interval ("10/10/97", "15/10/97");
$int652 = new Interval ("12/10/97", "14/10/97");
$int653 = $int651 - $int652;
if($int653->get eq '<empty>')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;



