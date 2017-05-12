#!/usr/local/bin/perl

use diagnostics;
use strict;
use warnings;
use Digest::Haval256;

my $string1 = "This is a string.";
my $string2 = "This is another string.";
my $string3 = "This is a string.This is another string.";

my $haval = new Digest::Haval256;
print "hash size=", $haval->hashsize, "\n";
print "number of rounds=", $haval->rounds, "\n\n";

$haval->add($string1);
my $digest = $haval->hexdigest();
print "1. Hash string1 only\n";
print "$digest\n\n";

$haval->reset();
$haval->add($string1, $string2);
my $digest2 = $haval->hexdigest();
print "2. Hash string1 and then hash string2\n";
print "$digest2\n\n";

$haval->reset();
$haval->add($string3);
print "3. Hash the two concatenated strings\n";
my $digest3 = $haval->hexdigest();
print "$digest3\n\n";

$haval->reset();
$haval->add($string1);
$haval->add($string2);
print "4. Hash the two concatenated strings\n";
my $digest4 = $haval->hexdigest();
print "$digest4\n";

