#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Moose;
use Math::Vector::Real;
use Math::Vector::Real::Random;
use Math::Trig;
use HackaMol::AtomGroup;
use HackaMol::Atom;

my @attributes = qw(
name
);
my @methods = qw(
Rg
);
my @roles = qw(HackaMol::Roles::AtomGroupRole);

map has_attribute_ok( 'HackaMol::AtomGroup', $_ ), @attributes;
map can_ok (          'HackaMol::AtomGroup', $_ ), @methods;
map does_ok(          'HackaMol::AtomGroup', $_ ), @roles;

my $radius = 16;
my $natoms = int(0.0334*($radius**3)*4*pi/3);

my @atoms = map {HackaMol::Atom->new(Z => 8, charges=> [0], coords => [$_]) } 
            map {Math::Vector::Real->random_in_sphere(3,$radius)} 1 .. $natoms;

my $group = HackaMol::AtomGroup->new(name => 'biggroup', atoms=> [@atoms]);

is($group->count_atoms, $natoms, "atom count: $natoms");
is($group->count_unique_atoms, 1, 'unique atoms in sphere is 1');
is($group->bin_atoms_name, "O$natoms", "sphere atoms named O$natoms");
cmp_ok(2-abs($group->COM), '>',0, 'center of mass within 2 angstrom of 0,0,0');
cmp_ok(abs($group->COZ - $group->COM), '<',1E-6, 'COM ~ COZ');
cmp_ok($group->total_charge, '==', 0, 'total charges 0');
cmp_ok($group->dipole_moment, '==',0, 'dipole moment is zero, no charges');
my $exp_Rg = $radius*sqrt(3/5);
cmp_ok(abs($exp_Rg-$group->Rg), '<',0.75, 'numerical Rg within 0.75 Angs of theoretical');

$group->clear_atoms;
is($group->count_atoms, 0, "cleared atom count: 0");
cmp_ok(abs(0-$group->Rg), '<',1E-7, 'Rg return 0 with no atoms');

done_testing();



