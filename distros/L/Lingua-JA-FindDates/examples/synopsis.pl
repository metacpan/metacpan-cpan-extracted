#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Lingua::JA::FindDates 'subsjdate';

binmode STDOUT, ":utf8";

# Given a string, find and substitute all the Japanese dates in it.

my $dates = '昭和４１年三月１６日';
print subsjdate ($dates), "\n";
$dates = 'blah blah blah 三月１６日';
print subsjdate ($dates), "\n";
