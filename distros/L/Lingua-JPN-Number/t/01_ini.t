#!/usr/bin/env perl

# t/01_ini.t; just to load Lingua::JPN::Number by using it

$|++; 
print "1..1
";
my($test) = 1;

# 1 load
use Lingua::JPN::Number;
my($loaded) = 1;
$loaded ? print "ok $test
" : print "not ok $test
";
$test++;

# end of t/01_ini.t

