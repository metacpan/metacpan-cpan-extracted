#!perl  -T

BEGIN {
 require './t/test.pl';
}
use Test::More;
BEGIN {
 my $j;
 if (!eval { require JSON } || !eval {$j = new JSON}) {
  plan (skip_all => "JSON not available");
 }
 elsif ($j->backend eq 'JSON::PP' && $JSON::PP'VERSION < '2.27104') {
  # Vesion 2.27104 removed the string equivalence test against the return
  # value of TO_JSON.
  plan (skip_all =>
       "JSON::PP < 2.27104 (you have $JSON::PP'VERSION) is too buggy");
 }
}

use strict; use warnings; no warnings 'utf8';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
plan tests => $tests;

use JE;

my $je = new JE;
my $j  = new JSON ->convert_blessed;

#--------------------------------------------------------------------#
use tests 1;

like $j->encode($je->eval(
       '[{a:"b",c:"d"},1,2,3,true,false,null,undefined,"3"]'
     )),
     qr/^\s*\[\s*
         {\s*
           (?:"a"\s*:\s*"b"\s*,\s*"c"\s*:\s*"d"
             |"c"\s*:\s*"d"\s*,\s*"a"\s*:\s*"b")
         \s*}
         \s*,\s*
         1
         \s*,\s*
         2
         \s*,\s*
         3
         \s*,\s*
         true
         \s*,\s*
         false
         \s*,\s*
         null
         \s*,\s*
         null
         \s*,\s*
         "3"
        ]\s*$/x;

