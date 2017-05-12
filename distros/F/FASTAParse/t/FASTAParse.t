# Todd Wylie [Wed Apr 12 15:10:27 CDT 2006]

use strict;
use warnings;
use IO::File;
use Test::More tests => 19;

# SOURCE THE MODULE
use_ok('FASTAParse');

# LOAD TEST DATA
my $NR_fh  = new IO::File 't/nr.fa'    or die "could not open nr.fa file";
my $nr;
while( <$NR_fh> ) {
    $nr .= $_;
}
close( $NR_fh );

# BUILD A FASTA OBJECT FROM NR
ok( my $fasta = FASTAParse->new(), "NR FASTA object" ) or exit;
ok( $fasta->load_FASTA( fasta => $nr ), "loading NR" ) or exit;

# TEST PULLING OUT VALUES FROM THE FASTA OBJECT
ok( my $sequence = $fasta->sequence(), "access NR sequence" ) or exit;
ok( $sequence eq "RNVGELIQNQVRTGLARMERVVRERMTTQDVEAITPQTLINIRPVVASIKEFFGTSQLSQFMDQTNPLSGLTHKRRLNALGPGGLSRERAGFEVRDVHPSH", "validate NR sequence" ) or exit;
ok( my $id = $fasta->id(), "access NR id" ) or exit;
ok( $id eq "gi|78925963|gb|ABB51603.1|", "validate NR id" ) or exit;
ok( my @descriptors =  @{$fasta->descriptors()}, "access NR descriptors" ) or exit;
my @known_descriptors = ( 'RNA polymerase subunit B [Streptomyces violaceusniger]', 'gi|78925959|gb|ABB51601.1| RNA polymerase subunit B [Streptomyces sp. NRRL B-24364]', 'gi|78925957|gb|ABB51600.1| RNA polymerase subunit B [Streptomyces sp. NRRL B-24363]', 'gi|78925953|gb|ABB51598.1| RNA polymerase subunit B [Streptomyces sp. NRRL B-24361]', 'gi|78925951|gb|ABB51597.1| RNA polymerase subunit B [Streptomyces sporoclivatus]', 'gi|78925949|gb|ABB51596.1| RNA polymerase subunit B [Streptomyces malaysiensis]', 'gi|78925947|gb|ABB51595.1| RNA polymerase subunit B [Streptomyces rhizosphaericus]', 'gi|78925945|gb|ABB51594.1| RNA polymerase subunit B [Streptomyces yogyakartensis]', 'gi|78925943|gb|ABB51593.1| RNA polymerase subunit B [Streptomyces indonesiensis]', 'gi|78925941|gb|ABB51592.1| RNA polymerase subunit B [Streptomyces cangkringensis]', 'gi|78925939|gb|ABB51591.1| RNA polymerase subunit B [Streptomyces asiaticus]', 'gi|78925937|gb|ABB51590.1| RNA polymerase subunit B [Streptomyces yatensis]', 'gi|78925935|gb|ABB51589.1| RNA polymerase subunit B [Streptomyces melanosporofaciens]', 'gi|78925931|gb|ABB51587.1| RNA polymerase subunit B [Streptomyces hygroscopicus subsp. hygroscopicus]', 'gi|78925925|gb|ABB51584.1| RNA polymerase subunit B [Streptomyces violaceusniger]', 'gi|78925923|gb|ABB51583.1| RNA polymerase subunit B [Streptomyces violaceusniger]', 'gi|78925919|gb|ABB51581.1| RNA polymerase subunit B [Streptomyces hygroscopicus subsp. geldanus]', 'gi|78925917|gb|ABB51580.1| RNA polymerase subunit B [Streptomyces sparsogenes]', 'gi|78925913|gb|ABB51578.1| RNA polymerase subunit B [Streptomyces hygroscopicus subsp. hygroscopicus]' );
ok( my @comments = @{$fasta->comments()}, "access NR comments" ) or exit;
my @known_comments = ('from GenBank nr');
ok( eq_array( \@comments, \@known_comments ), "validate NR comments" ) or exit;
ok( eq_array( \@descriptors, \@known_descriptors), "validate NR descriptors" ) or exit;

# FASTA DUMP
ok( my $dumped = $fasta->dump_FASTA(), "access NR FASTA dump" ) or exit;
ok( $fasta->print(), "print FASTA test" ) or exit;

# MANUALLY LOAD A FASTA FILE
my $new_fasta = FASTAParse->new();
ok( $new_fasta->format_FASTA(
                             sequence    => $sequence,
                             id          => $id,
                             cols        => '80',
                             comments    => ['fake FASTA for test purposes'],
                             descriptors => ['TESTED FASTA'],
                             ), "creation of FASTA" );
# VALUE CHECKS
$id          = $new_fasta->id();
$sequence    = $new_fasta->sequence();
@comments    = @{$new_fasta->comments()};
@descriptors = @{$new_fasta->descriptors()};
ok( $id eq "gi|78925963|gb|ABB51603.1|", "manual id check" ) or exit;
ok( $sequence eq "RNVGELIQNQVRTGLARMERVVRERMTTQDVEAITPQTLINIRPVVASIKEFFGTSQLSQFMDQTNPLSGLTHKRRLNALGPGGLSRERAGFEVRDVHPSH", "manual sequence check" ) or exit;
@known_comments    = ('fake FASTA for test purposes');
@known_descriptors = ('TESTED FASTA');
ok( eq_array(\@comments, \@known_comments), "manual comments validation" ) or exit; 
ok( eq_array(\@descriptors, \@known_descriptors), "manual descriptors validation" ) or exit; 

# SAVE CHECK
ok( $new_fasta->save_FASTA( save => '/tmp/revised.fa' ), "save to file of entry" ) or exit;

__END__
