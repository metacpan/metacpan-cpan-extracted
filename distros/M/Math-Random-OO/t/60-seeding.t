#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Math::Random::OO  

use Test::More 'no_plan';

my @classes = qw(Uniform UniformInt Normal); 
my @seeds = qw/ 0 1 2 3 /;

for my $c (@classes) {
  $c = "Math::Random::OO::$c";
  require_ok( $c );
  my $rng = $c->new();
  my @rands;
  for my $s ( @seeds ) {
    $rng->seed($s);
    push @rands, [ $s, [map { $rng->next } 1 .. 5] ];
  }
  while ( my $first = shift @rands ) {
    for my $r ( @rands ) {
      ok( ! eq_array( $first->[1], $r->[1] ), "$c\: contents differ ($first->[0] vs $r->[0])" );
    }
  }
}
