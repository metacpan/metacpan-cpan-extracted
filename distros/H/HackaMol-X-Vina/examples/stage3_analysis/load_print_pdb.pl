# Demian Riccardi May 22, 2014
#
# This script prints dumps the results and pdb of receptor+ligand
# from the output generated from ligands_dock.pl.  
#
use Modern::Perl;
use HackaMol;
use YAML::XS qw(LoadFile Dump);
use Math::Vector::Real;

my $output = LoadFile(shift);

print Dump $output;

exit unless (exists($output->{Zxyz}));

my $rec = HackaMol -> new
                   -> read_file_mol ($output->{rpath});

my $lig = HackaMol -> new
                   -> read_file_mol ($output->{lpath});

set_Zxyz($lig,$output->{Zxyz});

my $bigmol = HackaMol::Molecule->new(
                                     atoms=>[$rec->all_atoms,$lig->all_atoms], 
                                     atomgroups=>[$rec,$lig]
                                    );

$_->segid("FGF") foreach $rec->all_atoms;
$_->segid("LIG") foreach $lig->all_atoms;

$bigmol->print_pdb;



sub set_Zxyz {
  my @atoms = shift->all_atoms;
  my $Zxyz  = shift;
  my @mvr   = map { V($_->[1],$_->[2],$_->[3]) } @$Zxyz;

  foreach my $i (0 .. $#mvr){
    $atoms[$i]->set_coords(0,$mvr[$i]);
  }
}

