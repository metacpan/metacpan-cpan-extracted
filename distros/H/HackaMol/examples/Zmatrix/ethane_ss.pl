use Modern::Perl;
use HackaMol;

my $bldr = HackaMol->new();
open( my $fh, ">", "diethane_disulfide.xyz" );

foreach my $chi2 ( 0, 45, 90, 135, 180, 235, 270, 315 ) {
    foreach my $chi2p ( 0, 45, 90, 135, 180, 235, 270, 315 ) {
        foreach my $chi3 ( 0, 45, 90, 135, 180 ) {
            my $string = "
C
S 1 1.80
S 2 2.05 1 114
C 3 1.80 2 114 1 $chi3
C 1 1.50 2 115 3 $chi2
C 4 1.50 3 115 2 $chi2p
H 1 1.00 2 109 5  120 
H 1 1.00 2 109 5 -120 
H 4 1.00 3 109 6  120 
H 4 1.00 3 109 6 -120 
H 5 1.00 1 109 2  120 
H 5 1.00 1 109 2 -120 
H 5 1.00 1 109 2    0 
H 6 1.00 4 109 3  120 
H 6 1.00 4 109 3 -120 
H 6 1.00 4 109 3    0 
";

            my $mol = $bldr->read_string_mol( $string, 'zmat' );
            my $ca1 = $mol->get_atoms(4);
            my $ca2 = $mol->get_atoms(5);
            $mol->print_xyz($fh) if $ca1->distance($ca2) > 3.5; # cutoff from pdbs
        }
    }
}

