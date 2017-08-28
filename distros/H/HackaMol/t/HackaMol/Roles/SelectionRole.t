#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Test::Warn;
use Test::Moose;
use HackaMol;

my @attributes = qw(
  selections_cr
);
my @methods = qw(
  select_group
);

my $mol = HackaMol->new->read_file_mol("t/lib/2sic.pdb");

map has_attribute_ok( $mol, $_ ), @attributes;
map can_ok( $mol, $_ ), @methods;

my $backbone = $mol->select_group('backbone');
ok(
    $backbone->isa('HackaMol::AtomGroup'),
    'select_group returns HackaMol::AtomGroup'
);
is( $backbone->natoms,                   114, 'select_group("backbone")' );
is( $mol->select_group('water')->natoms, 2,   'select_group("water")' );
is( $mol->select_group("sidechains")->natoms,
    180, 'select_group("sidechains")' );
is(
    $mol->select_group('resname TYR .and. occ 1')->natoms,
    $mol->select_group('resname TYR')->natoms - 7,
    'tyr occ 1 natms == tyr - 7'
);

is(
    $mol->select_group('resname TYR .and. resname CYS')->natoms,
    0,
    'none found: TYR and CYS'
);

is(
    $mol->select_group('(resname TYR .or. resname CYS) .and. occ 1')->natoms,
    $mol->select_group('resname TYR .or. resname CYS')->natoms - 7,
    'none found: (TYR or CYS) and occ 1'
);


is(
    $mol->select_group('resname TYR .and. occ 0.25')->natoms,
    3,
    'tyr occ 0.25 natms == 3'
);
is(
    $mol->select_group('metals')->natoms,
    $mol->select_group('ligands')->natoms,
    'select_group("metals") yields same as select_group("ligands") for 2sic'
);

is( $mol->select_group('chain I .and. .not. water')->natoms,
    11, 'select_group("chain I .and. .not. water")' );

# testcase from the docs for selections attr
$mol->set_selection_cr(
    "sidechains2" => sub {
        grep {
            $_->record_name eq 'ATOM'
              and not( $_->name eq 'N'
                or $_->name eq 'CA'
                or $_->name eq 'C' )
        } @_;
    }
);

is(
    $mol->select_group('sidechains2')->natoms,
    $mol->select_group('sidechains')->natoms,
    "setting selection through selection attr",
);

is( $mol->select_group('resname CA1')->natoms, 2, 'resname with digits');
is( $mol->select_group('resname 1A2')->natoms, 2, 'resname with digits');

done_testing();
