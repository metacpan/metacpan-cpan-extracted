#!/usr/bin/env perl
use Modern::Perl;
use HackaMol;
use Math::Vector::Real;
use Time::HiRes qw(time);

my $t1 = time;
my $l = 1.42;

my $hack = HackaMol->new(name => "hackitup");

my $a1    = V(     0,  $l*sqrt(3),      0);
my $a2    = V($l*3/2,    -sqrt(3)*$l/2, 0); 

my @basis   = ( V(0,0,0), V($l,0,0) );
push @basis , ($basis[0]+$a2, $basis[1]+$a2);

$a2 *= 2;

my @atoms;
foreach my $j (0 .. 99){
  foreach my $i (0 .. 49){
    push @atoms, map {carbon($_+$j*$a1+$i*$a2,$i)} @basis;
  }
}

#grouped in strips along a2 vector

my @groups = $hack->group_by_atom_attr('resid',@atoms);
@groups = sort {$a->get_atoms(0)->resid <=> $b->get_atoms(0)->resid } @groups;

my $mol = HackaMol::Molecule->new(name=>"graphene", atoms=>[@atoms],
atomgroups=>[@groups]);

my @bonds ;
foreach my $group ($mol->all_groups){
  push @bonds, HackaMol::Bond->new(
                                   name=> "B", 
                                   atoms=>[$group->get_atoms(0),$group->get_atoms(4)],
                                  );
}

my $fh = $mol->print_xyz('nanotube.xyz');
for (my $i = 0; $i < $#groups; $i++){

  my @atoms;
  push @atoms, $groups[$_]->all_atoms foreach 0 .. $i;

  my $group = HackaMol::AtomGroup->new(atoms=>[@atoms]);
  $group->rotate( ($bonds[$i+1]->bond_vector)->versor,
                   360/scalar(@groups),
                   $bonds[$i+1]->get_atoms(0)->xyz,
  );
  $mol->print_xyz($fh);

}

my $t2 = time;

printf ("time: %10.4f\n", $t2-$t1);

#$mol->print_pdb;

sub carbon {
  my $mvr   = shift;
  my $resid = shift || 0;
  return ( HackaMol::Atom->new(name=>"C",Z=>6, coords =>[$mvr], resid => $resid)
);
}


