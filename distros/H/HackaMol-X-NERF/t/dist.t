#!/usr/bin/env perl

use strict;
use warnings;
use Test::Moose;
use Test::More;
use HackaMol::X::NERF;

my @methods = qw(
  init extend_a extend_ab extend_abc
);

map can_ok( 'HackaMol::X::NERF', $_ ), @methods;

my $bld = HackaMol::X::NERF->new;

my @vecs = ();

push @vecs, $bld->init() ; # returns a Math::Vector::Real object
push @vecs, $bld->extend_a(  $vecs[0]  ,   1.47              );
push @vecs, $bld->extend_ab( @vecs[0,1],   1.47, 109.5       );
push @vecs, $bld->extend_abc(@vecs[0,1,2], 1.47, 109.5,  60 );
push @vecs, $bld->extend_abc(@vecs[1,2,3], 1.47, 109.5, -60 );
push @vecs, $bld->extend_abc(@vecs[2,3,4], 1.47, 109.5,  60 );

foreach my $i (0 .. 4){
  my $j = $i+1; 
  ok( abs($vecs[$i]->dist($vecs[$j])-1.47) < 1E-8, "distance $i $j"); 
} 

foreach my $i (0 .. 3){
  my $j = $i+1;
  my $k = $i+2;
  ok( abs($vecs[$i]->dist($vecs[$k])-2.40092617217534) < 1E-8, "distance $i $k");
}

foreach my $i (0 .. 2){
  my $j = $i+1;
  my $k = $i+2;
  my $l = $i+3;
  ok( abs($vecs[$i]->dist($vecs[$l])-2.81592629631964) < 1E-8, "distance $i $k");
}

done_testing();

