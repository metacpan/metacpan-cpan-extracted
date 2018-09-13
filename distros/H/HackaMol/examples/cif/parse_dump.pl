use Modern::Perl;
use HackaMol;
use Time::HiRes qw(time);
use Data::Dumper;

my $file = shift;

open my $fh, "<", $file or die 'cant open file';

my $bldr = HackaMol->new();
my $t1 = time;
my $info = $bldr->read_cif_info($fh);
my ($atoms) = $bldr->read_cif_atoms($fh);
$info = $bldr->read_cif_info($fh,$info);
my $t2 = time;

say scalar(@$atoms);
printf ("parse time: %10.6f\n", $t2 - $t1);
HackaMol::Molecule->new(
  atoms => [grep {$_->symbol eq 'Zn'} @$atoms],
)->print_pdb;

print Dumper $info;

my ($info, $mols) = $bldr->read_file_cif_parts($file);

print Dumper $info;

