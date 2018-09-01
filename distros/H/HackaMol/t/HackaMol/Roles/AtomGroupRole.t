#!/usr/bin/env perl

use warnings;
use strict;
use Test::More;
use Cwd;
use Test::Warn;
use Test::Output;
use Test::Fatal qw(lives_ok dies_ok);
use Test::Moose;
use Math::Vector::Real;
use HackaMol::Atom;
use HackaMol::AtomGroup;                # v0.001;#To test for version availability
use Scalar::Util qw(refaddr);
use Path::Tiny;

my @attributes = qw(
atoms 
is_constrained
qcat_print
);
my @methods = qw(
bin_atoms dipole COM COZ 
dipole_moment total_charge
count_unique_atoms  
bin_atoms_name all_atoms 
push_atoms get_atoms  
count_atoms clear_atoms
natoms 
select_atoms map_atoms
sort_atoms
insert_atoms
rotate translate print_xyz
fix_serial tmax what_time
);

map has_attribute_ok( 'HackaMol::AtomGroup', $_ ), @attributes;
map can_ok (          'HackaMol::AtomGroup', $_ ), @methods;

my $group;
lives_ok {
    $group = HackaMol::AtomGroup->new();
}
'Test creation of an group';

my $atom1 = HackaMol::Atom->new(
    name    => 'O',
    charges => [ -0.80, -0.82, -0.834 ],
    coords  => [ V(2.05274,        0.01959,       -0.07701) ],
    Z       => 8
);

my $atom2 = HackaMol::Atom->new(
    name    => 'H',
    charges => [0.4,0.41,0.417],
    coords  => [ V( 1.08388,        0.02164,       -0.12303 ) ],
    Z       => 1
);
my $atom3 = HackaMol::Atom->new(
    name    => 'H',
    charges => [0.4,0.41,0.417],
    coords  => [ V( 2.33092,        0.06098,       -1.00332 ) ],
    Z       => 1
);

$group->push_atoms($_) foreach ($atom1, $atom2, $atom3);

$group->do_forall('copy_ref_from_t1_through_t2','coords', 0, 2);

is($group->is_constrained, 0, 'is not constrained by default');
$group->is_constrained(1);
is($group->is_constrained, 1, 'is now constrained');
$group->is_constrained(0);
is($group->is_constrained, 0, 'is now not constrained');
is($group->count_atoms, 3, 'atom count');

foreach my $at ($group->all_atoms){
  cmp_ok(refaddr($at->get_coords(0)) , '==' , refaddr($at->get_coords($_)),
  "do_forall(copy_ref_from_t1_through_t2, coords, 0 , 2): $_") foreach 1 .. 2;
}

my @dipole_moments = qw(2.293 2.350 2.390);
$group->do_forall('t',0);
foreach my $at ($group->all_atoms){
  is($at->t, 0, "\$atom->t(0) for each atom: group->do_for_all");
}

$group->gt(1);
foreach my $at ($group->all_atoms){
  is($at->t, 1, "\$atom->t(1) for each atom: group->gt");
}

foreach my $t (0 .. 2){
  $group->gt($t);
  is($group->tmax, 2, 'group tmax remains max t with increment');
  cmp_ok(abs($group->dipole_moment-$dipole_moments[$t]), '<' , 0.001, "dipole moment at t=$t");
}

my $atom4 = HackaMol::Atom->new(
    name    => 'H',
    charges => [0.0],
    coords  => [ V( 0,0,0 ) ],
    Z       => 1
);

my $atom5 = HackaMol::Atom->new(
    name    => 'H',
    charges => [0.0],
    coords  => [ V( 1,0,0 ) ],
    Z       => 1
);

my $atom6 = HackaMol::Atom->new(
    name    => 'H',
    charges => [0.0],
    coords  => [ V( 2,0,0 ) ],
    Z       => 1
);

$group->push_atoms($atom4);
dies_ok{$group->tmax} "tmax differences within group";
$group->clear_atoms;
is($group->count_atoms, 0, 'atom clear atom count');
warning_is { $group->translate( V( 3,0,0 ) ) }
"no atoms to translate",
  "carp warning> translate no atoms. ";

$group->push_atoms($atom4);
is($group->count_atoms, 1, 'atom atom count 1');
$group->push_atoms($atom5);
is($group->count_atoms, 2, 'atom atom count 2');

is_deeply($group->COM, V (0.5,0,0), 'Center of mass');
is_deeply($group->COZ, V (0.5,0,0), 'Center of Z');

$group->push_atoms($atom6);

is($group->count_atoms, 3, 'atom atom count 3');
is_deeply($group->COM, V (1,0,0), 'Center of mass');
is_deeply($group->COZ, V (1,0,0), 'Center of Z');

$group->clear_atoms;
is_deeply($group->COM, V (0), 'Center of mass V (0) no atoms');
is_deeply($group->COZ, V (0), 'Center of Z V (0) no atoms');
is_deeply($group->dipole, V (0), 'Dipole V (0) no atoms');

my @atoms = map{HackaMol::Atom->new(Z=>1, coords=> [V($_, $_, $_)])} 1 .. 10;
$group->push_atoms(@atoms);
is_deeply($group->COM,     V(5.5,5.5,5.5), 
          'Center of mass 10 atoms [1,1,1]...[10,10,10]');
is_deeply($group->COZ,     V(5.5,5.5,5.5), 
          'Center of Z    10 atoms [1,1,1]...[10,10,10]');

warning_is { $group->dipole }
"build_dipole> mismatch number of coords and charges. all defined?",
  "carp warning> mismatch number of coords and charges. ";

$group->do_forall('set_charges', $group->get_atoms(0)->t, 0);

warning_is { $group->do_forall('set_charges') }
"doing nothing for all",
  "carp warning> doing nothing for all ";

is_deeply($group->dipole,     V(0,0,0), 
          'dipole (0,0,0) atoms [1,1,1]...[10,10,10]');
#cmp_ok(abs($group->Rg-4.97493), '<', 0.0001, "Rg for the ten atoms, double check" );
is($group->bin_atoms_name, "H10", "bin_atoms name is H10");

$group->delete_atoms(0) foreach 0 .. 4 ;

is_deeply($group->COM,     V(8,8,8), 
          'center of mass delete first 5 of 10 atoms [1,1,1]...[10,10,10]');
is($group->bin_atoms_name, "H5", "bin_atoms name is H5");

$group->clear_atoms;

$group->push_atoms($atom1);
$group->push_atoms($atom2);
$group->push_atoms($atom3);

is($group->count_unique_atoms, 2, 'unique atoms in water is 2');
is($group->bin_atoms_name, 'OH2', 'water named OH2');

$group->push_atoms($atom1);
is($group->count_unique_atoms, 2, 'push O1 again, unique atoms still 2');
is($group->bin_atoms_name, 'O2H2', 'now named O2H2');

cmp_ok (abs(-0.834-$group->total_charge), '<', 1E-7, 'total charge'  );
cmp_ok (abs(34.01468-$group->total_mass), '<', 1E-7, 'total mass'  );
cmp_ok ($group->total_Z, '==', 18, 'total Z'  );

#we have two copies of atom1 in the molecule
my $xyz = $atom1->xyz;
$group->translate(V(1,0,0));
is_deeply($atom1->xyz-$xyz, V(2,0,0), "two copies of an atom gets double the intended translations:beware ");

$group->delete_atoms(3); #delete the copy of atom 1 

my $COM = $group->COM;
$group->translate(V(1,0,0));
is_deeply($group->COM-$COM, V(1,0,0), "COM after translation ");
dies_ok{$group->translate} "translate dies with no args";
dies_ok{$group->rotate} "rotate dies with no args";
dies_ok{$group->rotate(V(1,0,0))} "rotate dies with 1 args";
dies_ok{$group->rotate(V(1,0,0), 30)} "rotate dies with 2 args";

$group->gt(0);
$COM = $group->COM;
my $xyz1 = 
'3

  O   2.052740   0.019590  -0.077010
  H   1.083880   0.021640  -0.123030
  H   2.330920   0.060980  -1.003320
';

my $pdb =
'MODEL        1
HETATM    1  O   UNK     1       2.053   0.020  -0.077  1.00 20.00           O
HETATM    1  H   UNK     1       1.084   0.022  -0.123  1.00 20.00           H
HETATM    1  H   UNK     1       2.331   0.061  -1.003  1.00 20.00           H
ENDMDL
';

my $pdb2 =
'HETATM    1  O   UNK     1       2.053   0.020  -0.077  1.00 20.00           O
HETATM    1  H   UNK     1       1.084   0.022  -0.123  1.00 20.00           H
HETATM    1  H   UNK     1       2.331   0.061  -1.003  1.00 20.00           H
';

# previously ALA as default, but no longer
#HETATM    0  O   ALA     0       2.053   0.020  -0.077  1.00 20.00           O
#HETATM    0  H   ALA     0       1.084   0.022  -0.123  1.00 20.00           H
#HETATM    0  H   ALA     0       2.331   0.061  -1.003  1.00 20.00           H

#print_pdb tests
stdout_is(sub{$group->print_pdb},$pdb,"print_pdb no arg");
$group->qcat_print(1);
stdout_is(sub{$group->print_pdb},$pdb2,"print_pdb with qcat_print no arg");
$group->qcat_print(0);

#print_xyz tests
stdout_is(sub{$group->print_xyz},$xyz1,"print_xyz no arg");
my $dir = getcwd;
my $tfl = $dir."/t/lib/tmp.xyz"; 
unlink($tfl);
is(-e $tfl, undef, 'no xyz_file');
my $fh  = $group->print_xyz($tfl);
is(-e $tfl, 1, 'xyz_file written');
$group->print_xyz($fh);
$fh->close;
my $tmp = path($tfl)->slurp;
is($tmp,$xyz1.$xyz1,"printed twice");

warning_is { $group->print_xyz($tfl) }
"overwrite $tfl",
  "carp warning> overwrite xyz ";

my $xyz2 = 
'3

  O   2.052740   0.024451  -0.185812
  H   1.083880   0.022401  -0.139792
  H   2.330920  -0.016939   0.740498
';

dies_ok{$group->print_xyz($group)} "die of print to strange reference";

$group->rotate(V(1,0,0), 180, $COM,1);
$group->gt(1);

#some rotation tests
cmp_ok(abs($group->COM-$COM), '<', 1E-7, "COM after rotation ");
stdout_is(sub{$group->print_xyz},$xyz2,"print_xyz after rotation 180");
$group->rotate(V(1,0,0), 180, $COM);
stdout_is(sub{$group->print_xyz},$xyz1,"print_xyz after rotation 180 again");

{ 
#test fix_serial
  $group->fix_serial(10);
  my @exp = (10,11,12);
  my @obs = map {$_->serial} $group->all_atoms;
  is_deeply(\@exp, \@obs, "fix_serial, start from 10");
  $group->fix_serial(); # default
  @exp = (1,2,3);
  @obs = map {$_->serial} $group->all_atoms;
  is_deeply(\@exp, \@obs, "fix_serial, default start from 1");
  @exp = (0,1,2);
  $group->fix_serial(0);
  @obs = map {$_->serial} $group->all_atoms;
  is_deeply(\@exp, \@obs, "fix_serial, start from 0");
  $_->serial(0) foreach $group->all_atoms; # return to default 
}
# testing the print_xyz_ts
{
  my $xyz = 
'3

  O   1.000000   0.000000   0.000000
  H   1.000000   0.000000   0.000000
  H   1.000000   0.000000   0.000000
3

  O   2.052740   0.019590  -0.077010
  H   1.083880   0.021640  -0.123030
  H   2.330920   0.060980  -1.003320
';
  $_->push_coords(V(0,0,0),V(1,0,0),V(2,0,0)) foreach $group->all_atoms;
  dies_ok{$group->print_xyz_ts()} "dies_ok print_xyz_ts, without \@ts";
  dies_ok{$group->print_xyz_ts([])} "dies_ok print_xyz_ts, with empty \@ts";
  dies_ok{$group->print_xyz_ts( [ 0 .. 9 ])} "print_xyz_ts, some \@ts in array greater than tmax";
  dies_ok{$group->print_pdb_ts( [ 0 .. 9 ])} "print_pdb_ts, some \@ts in array greater than tmax";
  stdout_is(sub{$group->print_xyz_ts( [ 4,0 ]) },$xyz, "print_xyz_ts slice reverse");
  my $pdb =
'MODEL        1
HETATM    0  O   UNK     1       2.053   0.020  -0.077  1.00 20.00           O
HETATM    0  H   UNK     1       1.084   0.022  -0.123  1.00 20.00           H
HETATM    0  H   UNK     1       2.331   0.061  -1.003  1.00 20.00           H
ENDMDL
MODEL        2
HETATM    0  O   UNK     1       2.053   0.020  -0.077  1.00 20.00           O
HETATM    0  H   UNK     1       1.084   0.022  -0.123  1.00 20.00           H
HETATM    0  H   UNK     1       2.331   0.061  -1.003  1.00 20.00           H
ENDMDL
MODEL        3
HETATM    0  O   UNK     1       5.053   0.020  -0.077  1.00 20.00           O
HETATM    0  H   UNK     1       3.084   0.022  -0.123  1.00 20.00           H
HETATM    0  H   UNK     1       4.331   0.061  -1.003  1.00 20.00           H
ENDMDL
MODEL        4
HETATM    0  O   UNK     1       0.000   0.000   0.000  1.00 20.00           O
HETATM    0  H   UNK     1       0.000   0.000   0.000  1.00 20.00           H
HETATM    0  H   UNK     1       0.000   0.000   0.000  1.00 20.00           H
ENDMDL
';

  stdout_is(sub{$group->print_pdb_ts( [ 0 .. 3 ])},$pdb,"print_pdb_ts series"); 
}

$group->clear_atoms;

is($group->tmax,0, 'group with no atoms returns 0 tmax ');

cmp_ok (abs(0-$group->total_charge), '<', 1E-7, 'cleared total charge'  );
cmp_ok (abs(0-$group->total_mass), '<', 1E-7, 'cleared total mass'  );
cmp_ok ($group->total_Z, '==', 0, 'cleared total Z'  );
my ($bin_hr,$z_hr) = $group->bin_atoms;

is_deeply($bin_hr,{}, "empty bin_hr");

unlink($tfl);

#test what_time method
{
  $group->push_atoms($atom1, $atom2, $atom3);
  $atom1->push_coords(V(0, 1, 2),V(3,4,5));
  $atom1->t(2);
  warning_is { $group->what_time } 
    "what_time> t differences within group!!", 
    "carp warning> if atoms are different ts";

}


done_testing();
