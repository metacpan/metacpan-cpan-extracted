#!/usr/bin/env perl
# Description
# grep out the backbone atoms and rotate the dihedrals to the angle read in
# adding the sidechains shouldn't be too difficult.  Just have to identify which
# atoms are moving
use Modern::Perl;
use HackaMol;
use HackaMol::Roles::SelectionRole;
use Moose::Util qw(ensure_all_roles);
use Time::HiRes qw(time);

my $t1    = time;
my $angle = 180 ;

my $pdbid = "2cba";

my $bldr = HackaMol -> new;
my $pdb_mol = $bldr->pdbid_mol("2cba");

ensure_all_roles($pdb_mol,'HackaMol::Roles::SelectionRole');

my $mol = HackaMol::Molecule->new( atoms => [$pdb_mol->select_group("protein")->all_atoms]);

ensure_all_roles($mol,'HackaMol::Roles::SelectionRole');

my $bb = $mol->select_group("backbone");

my @residues = sort {$a->get_atoms(0)->resid <=> $b->get_atoms(0)->resid  } $bldr->group_by_atom_attr("resid",$mol->all_atoms);

#reset iatom
#$atoms[$_]->iatom($_) foreach 0 .. $#atoms;

my @dihedrals = $bldr->build_dihedrals($bb->all_atoms);

$mol->push_dihedrals(@dihedrals);


foreach my $id ( 0 .. $#dihedrals) {

    my $dihe = $dihedrals[$id];
    my $name = $dihe->name;
    my $rang = -1 * ( $dihe->dihe_deg - $angle );

    my $group_rot;

    #say "$id let's go! ", $dihe->name, " ", $dihe->dihe_deg;    

    # there are three types of rotations
    if ($name =~ m/\w\d+\_N\d+\_CA\d+\_\w\d+/) {

      next unless $id > 0;
      my $n = $dihe->get_atoms(1);
      my $i;
      foreach my $ires (0 .. $#residues){
        if (grep { $n eq $_ } $residues[$ires]->all_atoms ) {
          $i = $ires;
        }
      }
     
      $group_rot = HackaMol::AtomGroup->new( atoms =>   
              [ map{$_->all_atoms} @residues[0 .. $i-1] ],
      );
      #$group_rot->print_pdb; exit;
      
    }
    elsif ($name =~ m/^N\d+\_CA\d+\_\w\d+/) {
    my $n = $dihe->get_atoms(0);
      my $i;
    foreach my $ires (0 .. $#residues){
        if (grep { $n eq $_ } $residues[$ires]->all_atoms ) {
          $i = $ires;
        }
      }

    $group_rot = HackaMol::AtomGroup->new( atoms =>   
              [ grep {! (     $_->resid == $n->resid 
                          and 
                        (    $_->name eq 'C'
                          or $_->name eq 'CA' 
                          or $_->name eq 'O')
                        )
                } map{$_->all_atoms} @residues[0 .. $i] ],
    );

    }


    #my $rotation_group = $bldr->group_rot($mol,$rot_bonds[$id]);

    #set angle to rotate
    #my $rang = -1 * ( $dihedrals[$id]->dihe_deg - $angle );

    #ready to rotate!
    $mol->dihedral_rotate_groups( $dihedrals[$id], $rang, $group_rot ) if ($group_rot);

    say "$id aight! ", $dihe->name, " ", $dihe->dihe_deg;    
}

$mol->print_pdb("$pdbid\_unfold.pdb"); 1;

my $t2 = time;

printf( "time: %10.6f\n", $t2 - $t1 );
