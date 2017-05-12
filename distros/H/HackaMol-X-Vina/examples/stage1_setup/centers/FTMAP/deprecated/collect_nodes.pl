use Modern::Perl;
use HackaMol;

my $root = shift or die "pass root of glob in FTMaps/";
my @pdbs = glob("FTMaps/$root*.pdb");
my $hack = HackaMol->new;
my $mol  = HackaMol::Molecule->new;

foreach my $k (0 .. $#pdbs){

  system("perl scripts/pull_bs_ftmap.pl $pdbs[$k] > $k.xyz");
  $mol->push_atoms($hack->read_file_atoms("$k.xyz"));
  unlink "$k.xyz";
}

$mol->print_xyz;

