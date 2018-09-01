use HackaMol;
use Modern::Perl;

my $bld = HackaMol->new;
my $mol = $bld->read_file_mol( shift );
$mol->print_xyz;
