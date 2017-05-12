#!/usr/bin/perl

use strict;
use Rand::MersenneTwister;

my $i = 0;
my $totaltests = 10;
BEGIN { $| = 1 }
END {print "not ok 1\n" unless ($i > 0);}

print "1..$totaltests\n";
my($input) = "0123456701234567";
my @test;
my $r = Rand::MersenneTwister->new();
$r->seed(1000);
for($i=1 ; $i<$totaltests+1 ; $i++) {
  my $v = $r->rand(100);
  push @test, $v;
}
$r->seed(1000);
for($i=1 ; $i<$totaltests+1 ; $i++) {
  my $v = $r->rand(100);
  if($test[$i-1] == $v ) {
    print "ok $i\n";
  }
}
