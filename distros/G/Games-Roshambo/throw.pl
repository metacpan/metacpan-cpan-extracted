#!/usr/bin/perl

use lib './lib';
use Games::Roshambo;

##### Embrace the insanity, try 101 here.

my $numthrows = 3;

my $rps = Games::Roshambo->new(numthrows=>$numthrows);

my $one;
my $two;

foreach $a (1 .. $numthrows) {
 foreach $b (1 .. $numthrows) {
    if ($a == $b) { next; }

    print $rps->num_to_name($a) . " vs. " . $rps->num_to_name($b) . ": "; 

    $result =$rps->judge($a,$b);

    if ($result == 1) { print $rps->num_to_name($a) . " " . $rps->getaction($a, $b) . " " .  $rps->num_to_name($b) . "\n"; }
    if ($result == 2) { print $rps->num_to_name($b) . " " . $rps->getaction($b, $a) . " " .  $rps->num_to_name($a) . "\n"; }

   
 }
 print "--------------------------------------\n";
}

