use Modern::Perl;
use Math::Vector::Real;
use HackaMol;

#my $mol = HackaMol->new->pdbid_mol("2cba");

my $mol = HackaMol::Molecule->new(name=>'shit');#new->pdbid_mol("2cba");
$mol->push_atoms(HackaMol::Atom->new(Z=>1,coords=>[V(1,2,3)]));
print $mol->dump;
$mol->store('shit.json');

my $mol2 = HackaMol::Molecule->load('shit.json');

print $mol2->dump;

print abs($mol2->origin);

