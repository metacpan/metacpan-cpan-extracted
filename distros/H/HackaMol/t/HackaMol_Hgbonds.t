#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Fatal qw(dies_ok);
use Test::Warn;
use HackaMol;

my $hack = HackaMol->new( name => "hackitup" );

my @atoms = $hack->read_file_atoms("t/lib/Hg.2-18w.xyz");
my $mol   = HackaMol::Molecule->new( name => 'HgW_18', atoms => [@atoms] );

my @hgs   = grep{$_->Z == 80} $mol->all_atoms;
is (@hgs, 1, "one Hg found");
my $hg    = shift @hgs; # I know there is only one

my @bonds = $hack->find_bonds_brute(
                                    bond_atoms => [$hg], 
                                    candidates => [$mol->all_atoms],
                                   );

is ($hg->bond_count, 0, "molecule has not told atoms how many bonds they have");
$mol->push_bonds(@bonds);
is ($hg->bond_count, 6, "molecule has told atoms how many bonds they have");

my @b_oxys = map{ grep {$_->Z == 8} $_->all_atoms  } @bonds; 

foreach my $at (@b_oxys) {
  is($at->bond_count,1, "molecule has told water oxygen about 1 bond");
}

$mol->clear_bonds;

is ($hg->bond_count, 0, "molecule has taken away bond from Hg");

foreach my $at (@b_oxys) {
  is($at->bond_count,0, "molecule has taken away bond from water oxygen");
}

@bonds = $hack->find_bonds_brute(
                                    bond_atoms => [$hg],
                                    candidates => [$mol->all_atoms],
                                    fudge      => -0.01, 
                                   );

#you find no bonds with negative fudge  
is(@bonds, 0, "you find no bonds too much negative fudge");

@bonds = $hack->find_bonds_brute(
                                    bond_atoms => [$hg],
                                    candidates => [$mol->all_atoms],
                                    fudge      => 0.40,
                                   );

is(@bonds, 0, "you may find no bonds without enough fudge");

@bonds = $hack->find_bonds_brute(
                                    bond_atoms => [$hg],
                                    candidates => [$mol->all_atoms],
                                    fudge      => 0.45,
                                   );

is(@bonds, 6, "default fudge suggested by open babel, 0.45, gives the coordination");


my @oxy_bonds = $hack->find_bonds_brute(
                                    bond_atoms => [@b_oxys],
                                    candidates => [grep {$_->Z != 80} $mol->all_atoms],
                                    fudge      => 0.45,
                                   );
@bonds = (@bonds, @oxy_bonds);

is(@bonds, 18, "including oxy in the bond_search");

$mol->push_bonds(@bonds);

is ($hg->bond_count, 6, "molecule has told hg how many bonds they have");

foreach my $at (@b_oxys) {
  is($at->bond_count,3, "molecule has told water oxygen about 1 bond");
}



done_testing();

