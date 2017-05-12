#!/usr/bin/env perl

use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::Warn;
use Test::Fatal qw(lives_ok);
use HackaMol::Molecule;                # v0.001;#To test for version availability

my @attributes = qw(
basis
ecp
multiplicity
basis_geom
dummy
              Etot Eelec Enuc 
              qm_dipole_moment ionization_energy gradient_norm
              Hform 
              U H G S
              S_t
              S_r
              S_v
              Etot_mp2
              Etot_ccsdt
              Ecds
              qm_dipole frequencies eigvec alpha beta
);
my @methods = qw(
);

map has_attribute_ok( 'HackaMol::Molecule', $_ ), @attributes;
map can_ok( 'HackaMol::Molecule', $_ ), @methods;
my $obj;
lives_ok {
    $obj = HackaMol::Molecule->new();
}
'Test creation of an obj';

is($obj->basis, '6-31+G*', 'basis default');
is($obj->multiplicity        , 1     , 'multiplicity default');

done_testing();
