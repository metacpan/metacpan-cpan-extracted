HackaMol-Roles-SelectionRole
===============
A role for simplifying selections in HackaMol  

VERSION 0.001
============= 
 

SYNOPSIS
============
````perl
    use Moose::Util qw( apply_all_roles );
    
    my $mol = HackaMol->new->pdbid_mol("2CHNs"); #returns HackaMol::Molecule

    apply_all_roles($mol, 'HackaMol::Roles::SelectionRole');

    my $group1 = $mol->select_group("chain A .or. chain B");
    my $group2 = $mol->select_group("chain A .and. resname TYR");
    my $group3 = $mol->select_group("water");
    my $group4 = $mol->select_group(".not. water");
    my $group5 = $mol->select_group("protein");
    my $group6 = $mol->select_group("sasa > 10");

    my $submol = HackaMol::Molecule->(groups => [$group2, $group3]);
    $submol->print_pdb("Tyrs_A_water.pdb");

````


DESCRIPTION
============
This role adds the select_group method to a class.  Applying this role to 
instances of the HackaMol::Molecule class (as above) would enable a molecule 
object to mint new AtomGroup objects based on selections.

