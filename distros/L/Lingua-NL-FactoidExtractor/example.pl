#! /usr/bin/perl -w

use strict;
use lib "./lib";
use Lingua::NL::FactoidExtractor;

my $inputfile = "alpino.xml";
my $verbose = 1; #boolean
my $factoids = extract($inputfile,$verbose);
print "$factoids\n";
