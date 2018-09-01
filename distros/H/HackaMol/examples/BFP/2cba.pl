use Modern::Perl;
use HackaMol;

my $mol_2cba = HackaMol->new()->pdbid_mol('2cba');
my $CA_group = $mol_2cba->select_group('name CA');
$CA_group->calc_bfps;

foreach my $at ($CA_group->all_atoms){
    printf("%4i %5.2f %5.2f\n", $at->resid, $at->bfact, $at->bfp );
}


