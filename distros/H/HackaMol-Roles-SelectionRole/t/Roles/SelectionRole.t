#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Test::Warn;
use Test::Moose;
use HackaMol;
use Moose::Util qw( ensure_all_roles );

my @attributes = qw(
  selections_cr
);
my @methods = qw(
  select_group
);

my $mol = HackaMol->new->read_file_mol("t/lib/2sic.pdb");
ensure_all_roles( $mol, 'HackaMol::Roles::SelectionRole' );

map has_attribute_ok( $mol, $_ ), @attributes;
map can_ok( $mol, $_ ), @methods;

my $backbone = $mol->select_group('backbone');
ok(
    $backbone->isa('HackaMol::AtomGroup'),
    'select_group returns HackaMol::AtomGroup'
);
is( $backbone->natoms,                   1146, 'select_group("backbone")' );
is( $mol->select_group('water')->natoms, 258,  'select_group("water")' );
is( $mol->select_group("sidechains")->natoms,
    1556, 'select_group("sidechains")' );
is(
    $mol->select_group('resname TYR .and. occ 1')->natoms,
    $mol->select_group('resname TYR')->natoms,
'select_group("resname TYR .and. occ 1") returns same as select_group("resname TYR") because all TYR have 1.0 occ'
);    #  .and. resname TYR');
is(
    $mol->select_group('metals')->natoms,
    $mol->select_group('ligands')->natoms,
    'select_group("metals") yields same as select_group("ligands") for 2sic'
);

is( $mol->select_group('chain I .and. .not. water')->natoms, 764,  'select_group("chain I .and. .not. water")' );

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

done_testing();
