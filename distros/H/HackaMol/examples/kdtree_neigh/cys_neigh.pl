#!/usr/bin/env perl
use Modern::Perl;
use Math::Trig;
use HackaMol;
use Math::Vector::Real::kdTree;
use Math::Vector::Real;
use Math::Vector::Real::Random;
use Scalar::Util qw(refaddr);
use Data::Dumper;

my $mol = HackaMol->new()->read_file_mol('/Users/dmr3/myPDB/cif/j3/3j3y.cif');
#my $mol = HackaMol->new()->read_file_mol('/Users/dmr3/myPDB/cif/j3/3j30.cif');
my @atoms = $mol->all_atoms;
my $tree = Math::Vector::Real::kdTree->new(map {$_->xyz } @atoms);

my $new_mol = HackaMol::Molecule->new();

my @exclude_seen;
foreach my $sg( $mol->select_group('name SG')->all_atoms ){
    
    my @ix = $tree->find_in_ball($sg->xyz, 4, @exclude_seen);
    push @exclude_seen, @ix;

    $new_mol->push_atoms($_) foreach  map {$atoms[$_]} @ix;
   
}

$new_mol->print_xyz;
