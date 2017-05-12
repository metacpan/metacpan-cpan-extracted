#!/usr/bin/perl

use GnaData::Load;
use Test;

BEGIN {plan test=>1;}

my (%hash);
$loader = GnaData::Load->new();
$loader->load("http://www.gnacademy.org/");
foreach ($loader->extract_hrefs()) { 
$hash{$_} = 1;	
}

ok($hash{"http://www.gnacademy.org/mason/catalog/browse.html"}, "1");
