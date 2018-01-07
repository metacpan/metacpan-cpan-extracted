#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Test::Warn;
use Test::Moose;
use HackaMol;

my @attributes = qw(
  selections_cr
  selection
);
my @methods = qw(
  select_group
);

my $mol = HackaMol->new->read_file_mol("t/lib/2sic.pdb");

map has_attribute_ok( $mol, $_ ), @attributes;
map can_ok( $mol, $_ ), @methods;

SELECTION:{
  $mol->set_selection('bb' => 'backbone');
  is ($mol->get_selection('bb'), 'backbone', 'selection attribute');
}

my $backbone = $mol->select_group('backbone');
ok(
    $backbone->isa('HackaMol::AtomGroup'),
    'select_group returns HackaMol::AtomGroup'
);
is( $backbone->natoms,                   152, 'select_group("backbone")' );
is( $mol->select_group('water')->natoms, 2,   'select_group("water")' );
is( $mol->select_group("sidechain")->natoms,
    141, 'select_group("sidechain")' );

is($mol->select_group("chain 1")->natoms,2, "integer chain no warnings");

foreach my $and (qw(and .and.)){
  is(
    $mol->select_group("resname TYR $and occ 1")->natoms,
    $mol->select_group('resname TYR')
        ->select_group('occ 1')->natoms,
    'tyr occ 1 natms == tyr chained to occ 1'
  );

  is(
    $mol->select_group("resname TYR $and resname CYS")->natoms,
    0,
    'none found: TYR and CYS'
  );
  is(
    $mol->select_group("resname TYR $and occ 0.25")->natoms,
    3,
    'tyr occ 0.25 natms == 3'
  );
  foreach my $not (qw(not .not.)){
    is( $mol->select_group("chain I $and $not water")->natoms,
      11, "select_group(\"chain I $and $not water\")" );
  }
}

is_deeply($mol->select_group("resname ARG+TYR"), 
          $mol->select_group("(resname ARG) .or. (resname TYR)"), "ARG+TYR ~~ (resname ARG) .or. (resname TYR)");

is_deeply($mol->select_group("resname ARG+TYR .and. (name CA .and. occ 1.0)"), 
          $mol->select_group("((resname ARG) .or. (resname TYR)) .and. (name CA .and. occ 1.0)"), "more parenthesis");


is ($mol->select_group('resname ARG+TYR')->natoms, '58', 'resname ARG+TYR');
is ($mol->select_group('resid 7+1-5+245-246+252')->natoms, '69', 'resid 7+1-5+245-246+252');
is ($mol->select_group('chain E-I and resid 7+1-5')->natoms, '45', 'chain E-I and resid 7+1-5');

is(
    $mol->select_group('(resname TYR .or. resname CYS) .and. occ 1')->natoms,
    $mol->select_group('resname TYR .or. resname CYS')->natoms - 7,
    'none found: (TYR or CYS) and occ 1'
);

is(
    $mol->select_group('metals')->natoms,
    $mol->select_group('ligands')->natoms,
    'select_group("metals") yields same as select_group("ligands") for 2sic'
);


# testcase from the docs for selections attr
$mol->set_selection_cr(
    "sidechain2" => sub {
        grep {
            $_->record_name eq 'ATOM'
              and not( $_->name eq 'N'
                or $_->name eq 'CA'
                or $_->name eq 'C' 
                or $_->name eq 'O' 
                or $_->name eq 'OXT' 
            )
        } @_;
    }
);

is(
    $mol->select_group('sidechain2')->natoms,
    $mol->select_group('sidechain')->natoms,
    "setting selection through selection attr",
);

is( $mol->select_group('resname CA1')->natoms, 2, 'resname with digits');
is( $mol->select_group('resname 1A2')->natoms, 2, 'resname with digits');

done_testing();
