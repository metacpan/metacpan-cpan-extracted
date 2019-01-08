#!/usr/bin/env perl
use Modern::Perl;
use Math::Trig;
use HackaMol;
use Math::Vector::Real::kdTree;
use Math::Vector::Real;
use Math::Vector::Real::Random;
use Data::Dumper;

my @v = map Math::Vector::Real->random_in_box(3,24), 1..100000;
my $tree = Math::Vector::Real::kdTree->new(@v);

foreach my $diag (6, 12, 18){
    my @ix = $tree->find_in_ball(V($diag,$diag,$diag), 5);
   
    HackaMol::Molecule->new(atoms => [ map { 
                HackaMol::Atom->new(
                    Z => 80,
                    coords => [$v[$_]]
                )
                }@ix ])->print_xyz("sphere_$diag.xyz");
}

