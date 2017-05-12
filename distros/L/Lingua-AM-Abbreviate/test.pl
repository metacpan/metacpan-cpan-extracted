#!/usr/bin/perl

use Lingua::AM::Abbreviate;

$weyzero     =  "ወ/ሮ";
$doctor      =  "ዶ/ር";
$weldemaryam =  "ወ/ማርያም";

print $weyzero, " => ", Expand ( $weyzero ), "\n";
print $doctor, " => ", Expand ( $doctor ), "\n";

print $weldemaryam, " => ", $w_maryam = Expand ( $weldemaryam ), "\n";
print $w_maryam, " => ", Contract ( $w_maryam ), "\n";
