use Modern::Perl;
use HackaMol;
use Data::Dumper;

my $bldr = HackaMol->new();
my $mol1 = $bldr->pdbid_mol("2K2X"); 
my $mol2 = $bldr->pdbid_mol("2K2X"); 

foreach my $t (2){#0 .. $mol2->tmax){
  $mol2->gt($t);
  my ($matrot,$trans,$rmsd) = HackaMol->new()->superpose_rt($mol1->select_group('backbone'),$mol2->select_group('backbone'));
  $mol2->rotate_translate($matrot,$trans);
  say "backbone  RMSD: ", $rmsd;
  say "All atoms RMSD: ", $bldr->rmsd($mol1,$mol2);
  
}
$mol1->print_pdb('ref.pdb');
$mol2->gt(2);
$mol2->print_pdb('aligned.pdb');



