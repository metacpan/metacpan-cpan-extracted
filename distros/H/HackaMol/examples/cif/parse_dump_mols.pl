use Modern::Perl;
use HackaMol;
use Time::HiRes qw(time);
use Data::Dumper;

my $file = shift;

open my $fh, "<", $file or die 'cant open file';

my $bldr = HackaMol->new();
my $t1 = time;
my ($info, $mols) = $bldr->read_file_cif_parts($file);
my $t2 = time;

print Dumper $info;
say scalar(@$mols);
printf ("parse time: %10.6f\n", $t2 - $t1);

open my $fh2, ">", 'stuff.xyz';

foreach my $mol (@$mols){
    $mol->print_xyz($fh2);
}

exit;
