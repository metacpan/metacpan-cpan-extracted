#!/usr/bin/env perl
# Demian Riccardi  February 20, 2014
# 
# strips out TIP from pdb and renames HIS residues 
# pdb adjustments needed to submit pdb generated from charmm simulation 
# to COACH: http://zhanglab.ccmb.med.umich.edu/COACH/
#
use Modern::Perl;
use HackaMol;

my $hack = HackaMol->new(name=>"hackitup");
my @atoms = map  {
                  $_->resname('HIS') if $_->resname =~ /HSD|HSE|HSP/;
                  $_;
                 }
            grep {
                  $_->resname !~ /TIP|CLA/ 
                 } $hack->read_file_atoms(shift);

my $mol = HackaMol::Molecule->new(name=>"molecule", atoms=>[@atoms]);
$mol->print_pdb;



