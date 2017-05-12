use Modern::Perl;
use HackaMol;
#print the TRP sidechain via search

my $mol = HackaMol->new->pdbid_mol('2cba');

my $bond = HackaMol::Bond->new(atoms => [
                                  $mol->get_atoms(985),
                                  $mol->get_atoms(988),
                               ]
);

my $group = HackaMol->new->group_rot($mol,$bond);

$group->print_xyz;


