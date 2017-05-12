# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use Data::Dumper;

my $result;
my $cDNA;
my $genomic;

BEGIN { plan(tests => 36) };
use GH::Sim4 qw/ sim4 /;
print "# check that the library loads correctly.\n";
ok(1); # If we made it this far, we're ok.


#########################
#
# first pass test, just see if it works
#

print "#################\n# Basic functionality test.\n#\n";

$cDNA = slurp("t/cDNA-1.fasta");
$genomic = slurp("t/genomic-1.fasta");

undef $result;
$result = sim4($genomic, $cDNA, {"R" => 0});

print "# check if sim4 returned a defined value.\n";
ok(defined($result));

print "# check that it returned the number of exons we expect.\n";
ok(scalar @{$result->{exons}}, 7);

print "# check that the alignment is on the forward strand.\n";
ok($result->{match_orientation}, 'forward');

#
# and w/ the alignment text...
#

undef $result;
$result = sim4($genomic, $cDNA, {"R" => 0, "A" => 1});

print "# make sure that there's something in the alignment_string hash bucket.\n";
ok(defined($result->{alignment_string}));

$a = << 'EOA';

      0     .    :    .    :    .    :    .    :    .    :
     51 ATGGTGGGTGTGTCGCCGAAGATCGCTCCGTCGATGTTGTCATCGGACTT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
      1 ATGGTGGGTGTGTCGCCGAAGATCGCTCCGTCGATGTTGTCATCGGACTT

     50     .    :    .    :    .    :    .    :    .    :
    101 TGCAAATCTTGCCGCGGAGGCTAAGCGGATGATCGATTTGGGCGCCAATT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
     51 TGCAAATCTTGCCGCGGAGGCTAAGCGGATGATCGATTTGGGCGCCAATT

    100     .    :    .    :    .    :    .    :    .    :
    151 GGCTTCACATGGACATTATGGTA...TCGGGCAGGCATTTTGTTTCTAAC
        ||||||||||||||||||||>>>...>>>| | |||||||||||||||||
    101 GGCTTCACATGGACATTATG         GACGGGCATTTTGTTTCTAAC

    150     .    :    .    :    .    :    .    :    .    :
    583 CTAACGATTGGTGCTCCTGTCATCGAGAGTTTGAGGAAGCACACAAAGTA
        |||||||||||||||||||||||||||||||||||||||||||||||>>>
    142 CTAACGATTGGTGCTCCTGTCATCGAGAGTTTGAGGAAGCACACAAA   

    200     .    :    .    :    .    :    .    :    .    :
    633 ...CAGTGCATATCTTGATTGCCACTTAATGGTGACGAACCCCATGGATT
        ...>>>||||||||||||||||||||||||||||||||||||||||||||
    189       TGCATATCTTGATTGCCACTTAATGGTGACGAACCCCATGGATT

    250     .    :    .    :    .    :    .    :    .    :
    771 ATGTGGATCAGATGGCTAAAGCTGGGGCGTCTGGTTTCACATTCCACGTT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
    233 ATGTGGATCAGATGGCTAAAGCTGGGGCGTCTGGTTTCACATTCCACGTT

    300     .    :    .    :    .    :    .    :    .    :
    821 GAGGTGGCCCAAGGTA...CAGAGAATTGGCAAGAACTTGTGAAGAAGAT
        |||||||||||||>>>...>>>||||||||||||||||||||||||||||
    283 GAGGTGGCCCAAG         AGAATTGGCAAGAACTTGTGAAGAAGAT

    350     .    :    .    :    .    :    .    :    .    :
    952 TAAGGCTGCTGGGATGAGGCCAGGTGTGGCTCTAAAGCCTGGAACACCTG
        ||||||||||||||||||||||||||||||||||||||||||||||||||
    324 TAAGGCTGCTGGGATGAGGCCAGGTGTGGCTCTAAAGCCTGGAACACCTG

    400     .    :    .    :    .    :    .    :    .    :
   1002 TTGAACAAGTCTATCCTCTGGTA...CAGGTCGAAGGTACAAATCCGGTC
        ||||||||||||||||||||>>>...>>>|||||||||||||||||||||
    374 TTGAACAAGTCTATCCTCTG         GTCGAAGGTACAAATCCGGTC

    450     .    :    .    :    .    :    .    :    .    :
   1118 GAAATGGTTCTTGTGATGACTGTGGAGCCTGGATTTGGAGGCCAGAAGTT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
    415 GAAATGGTTCTTGTGATGACTGTGGAGCCTGGATTTGGAGGCCAGAAGTT

    500     .    :    .    :    .    :    .    :    .    :
   1168 CATGCCCAGCATGATGGACAAGGTT...TAGGTCAGGGCATTGAGGAACA
        ||||||||||||||||||||||>>>...>>>|||||||||||||||||||
    465 CATGCCCAGCATGATGGACAAG         GTCAGGGCATTGAGGAACA

    550     .    :    .    :    .    :    .    :    .    :
   1294 AGTACCCAACACTTGATATTGAGGTA...CAGGTGGACGGCGGCTTAGGC
        |||||||||||||||||||||||>>>...>>>||||||||||||||||||
    506 AGTACCCAACACTTGATATTGAG         GTGGACGGCGGCTTAGGC

    600     .    :    .    :    .    :    .    :    .    :
   1409 CCTTCCACAATCGATGCAGCAGCTGCAGCTGGAGCCAACTGTATCGTCGC
        ||||||||||||||||||||||||||||||||||||||||||||||||||
    547 CCTTCCACAATCGATGCAGCAGCTGCAGCTGGAGCCAACTGTATCGTCGC

    650     .    :    .    :    .    :    .    :    .    :
   1459 AGGAAGTTCAGTGTTTGGAGCTCCGAAGCCTGGGGACGTCATATCCCTTT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
    597 AGGAAGTTCAGTGTTTGGAGCTCCGAAGCCTGGGGACGTCATATCCCTTT

    700     .    :    .    :    .    :    .
   1509 TGCGGGCTAGTGTTGAGAAAGCACAACCCTCCACTTAA
        ||||||||||||||||||||||||||||||||||||||
    647 TGCGGGCTAGTGTTGAGAAAGCACAACCCTCCACTTAA
EOA

print "# check that the alignment looks right.\n";
ok($result->{alignment_string} eq $a);

print "# check that it returned the correct number of exon alignments.\n";
ok(scalar(@{$result->{exon_alignment_strings}}) == 7);

$a = << 'EOA';
ATGGTGGGTGTGTCGCCGAAGATCGCTCCGTCGATGTTGTCATCGGACTTTGCAAATCTTGCCGCGGAGGCTAAGCGGATGATCGATTTGGGCGCCAATTGGCTTCACATGGACATTATG
||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
ATGGTGGGTGTGTCGCCGAAGATCGCTCCGTCGATGTTGTCATCGGACTTTGCAAATCTTGCCGCGGAGGCTAAGCGGATGATCGATTTGGGCGCCAATTGGCTTCACATGGACATTATG
EOA

print "# and check that the first one looks right.\n";
ok($result->{exon_alignment_strings}->[0] eq $a);

#########################
#
# second pass test, see if reverse complementing works.
#

$cDNA = slurp("t/cDNA-1-rev.fasta");

undef $result;
$result = sim4($genomic, $cDNA, {"R" => 1});

print "#################\n# Reverse complement test (try both orientations).\n#\n";

print "# check if sim4 returned a defined value.\n";
ok(defined($result));

print "# check that it returned the number of exons we expect.\n";
ok(scalar @{$result->{exons}}, 7);

print "# check that the alignment is on the reverse strand.\n";
ok($result->{match_orientation}, 'reverse');	

#
# and w/ an alignment string.
#
undef $result;
$result = sim4($genomic, $cDNA, {"R" => 1, "A" => 1});

print "# and check that alignments for reversed strings work....\n";	
print "# first make sure that there's something in the alignment_string hash bucket.\n";
ok(defined($result->{alignment_string}));

$a = << 'EOA';

      0     .    :    .    :    .    :    .    :    .    :
     51 ATGGTGGGTGTGTCGCCGAAGATCGCTCCGTCGATGTTGTCATCGGACTT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
      1 ATGGTGGGTGTGTCGCCGAAGATCGCTCCGTCGATGTTGTCATCGGACTT

     50     .    :    .    :    .    :    .    :    .    :
    101 TGCAAATCTTGCCGCGGAGGCTAAGCGGATGATCGATTTGGGCGCCAATT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
     51 TGCAAATCTTGCCGCGGAGGCTAAGCGGATGATCGATTTGGGCGCCAATT

    100     .    :    .    :    .    :    .    :    .    :
    151 GGCTTCACATGGACATTATGGTA...TCGGGCAGGCATTTTGTTTCTAAC
        ||||||||||||||||||||>>>...>>>| | |||||||||||||||||
    101 GGCTTCACATGGACATTATG         GACGGGCATTTTGTTTCTAAC

    150     .    :    .    :    .    :    .    :    .    :
    583 CTAACGATTGGTGCTCCTGTCATCGAGAGTTTGAGGAAGCACACAAAGTA
        |||||||||||||||||||||||||||||||||||||||||||||||>>>
    142 CTAACGATTGGTGCTCCTGTCATCGAGAGTTTGAGGAAGCACACAAA   

    200     .    :    .    :    .    :    .    :    .    :
    633 ...CAGTGCATATCTTGATTGCCACTTAATGGTGACGAACCCCATGGATT
        ...>>>||||||||||||||||||||||||||||||||||||||||||||
    189       TGCATATCTTGATTGCCACTTAATGGTGACGAACCCCATGGATT

    250     .    :    .    :    .    :    .    :    .    :
    771 ATGTGGATCAGATGGCTAAAGCTGGGGCGTCTGGTTTCACATTCCACGTT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
    233 ATGTGGATCAGATGGCTAAAGCTGGGGCGTCTGGTTTCACATTCCACGTT

    300     .    :    .    :    .    :    .    :    .    :
    821 GAGGTGGCCCAAGGTA...CAGAGAATTGGCAAGAACTTGTGAAGAAGAT
        |||||||||||||>>>...>>>||||||||||||||||||||||||||||
    283 GAGGTGGCCCAAG         AGAATTGGCAAGAACTTGTGAAGAAGAT

    350     .    :    .    :    .    :    .    :    .    :
    952 TAAGGCTGCTGGGATGAGGCCAGGTGTGGCTCTAAAGCCTGGAACACCTG
        ||||||||||||||||||||||||||||||||||||||||||||||||||
    324 TAAGGCTGCTGGGATGAGGCCAGGTGTGGCTCTAAAGCCTGGAACACCTG

    400     .    :    .    :    .    :    .    :    .    :
   1002 TTGAACAAGTCTATCCTCTGGTA...CAGGTCGAAGGTACAAATCCGGTC
        ||||||||||||||||||||>>>...>>>|||||||||||||||||||||
    374 TTGAACAAGTCTATCCTCTG         GTCGAAGGTACAAATCCGGTC

    450     .    :    .    :    .    :    .    :    .    :
   1118 GAAATGGTTCTTGTGATGACTGTGGAGCCTGGATTTGGAGGCCAGAAGTT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
    415 GAAATGGTTCTTGTGATGACTGTGGAGCCTGGATTTGGAGGCCAGAAGTT

    500     .    :    .    :    .    :    .    :    .    :
   1168 CATGCCCAGCATGATGGACAAGGTT...TAGGTCAGGGCATTGAGGAACA
        ||||||||||||||||||||||>>>...>>>|||||||||||||||||||
    465 CATGCCCAGCATGATGGACAAG         GTCAGGGCATTGAGGAACA

    550     .    :    .    :    .    :    .    :    .    :
   1294 AGTACCCAACACTTGATATTGAGGTA...CAGGTGGACGGCGGCTTAGGC
        |||||||||||||||||||||||>>>...>>>||||||||||||||||||
    506 AGTACCCAACACTTGATATTGAG         GTGGACGGCGGCTTAGGC

    600     .    :    .    :    .    :    .    :    .    :
   1409 CCTTCCACAATCGATGCAGCAGCTGCAGCTGGAGCCAACTGTATCGTCGC
        ||||||||||||||||||||||||||||||||||||||||||||||||||
    547 CCTTCCACAATCGATGCAGCAGCTGCAGCTGGAGCCAACTGTATCGTCGC

    650     .    :    .    :    .    :    .    :    .    :
   1459 AGGAAGTTCAGTGTTTGGAGCTCCGAAGCCTGGGGACGTCATATCCCTTT
        ||||||||||||||||||||||||||||||||||||||||||||||||||
    597 AGGAAGTTCAGTGTTTGGAGCTCCGAAGCCTGGGGACGTCATATCCCTTT

    700     .    :    .    :    .    :    .
   1509 TGCGGGCTAGTGTTGAGAAAGCACAACCCTCCACTTAA
        ||||||||||||||||||||||||||||||||||||||
    647 TGCGGGCTAGTGTTGAGAAAGCACAACCCTCCACTTAA
EOA

print "# then check that the alignment looks right.\n";
ok($result->{alignment_string} eq $a);

print "# check that it returned the correct number of exon alignments.\n";
ok(scalar(@{$result->{exon_alignment_strings}}) == 7);

$a = << 'EOA';
GTGGACGGCGGCTTAGGCCCTTCCACAATCGATGCAGCAGCTGCAGCTGGAGCCAACTGTATCGTCGCAGGAAGTTCAGTGTTTGGAGCTCCGAAGCCTGGGGACGTCATATCCCTTTTGCGGGCTAGTGTTGAGAAAGCACAACCCTCCACTTAA
||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
GTGGACGGCGGCTTAGGCCCTTCCACAATCGATGCAGCAGCTGCAGCTGGAGCCAACTGTATCGTCGCAGGAAGTTCAGTGTTTGGAGCTCCGAAGCCTGGGGACGTCATATCCCTTTTGCGGGCTAGTGTTGAGAAAGCACAACCCTCCACTTAA
EOA

print "# and check that the last one looks right.\n";
ok($result->{exon_alignment_strings}->[6] eq $a);


print "#################\n# Reverse complement test (only try reverse orientation).\n#\n";

undef $result;
$result = sim4($genomic, $cDNA, {"R" => 2});

print "# check if sim4 returned a defined value.\n";
ok(defined($result));

print "# check that it returned the number of exons we expect.\n";
ok(scalar @{$result->{exons}}, 7);

print "# check that the alignment is on the reverse strand.\n";
ok($result->{match_orientation}, 'reverse');	

#########################
#
# third pass test, see if error handling works.
#

$cDNA = "wxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyzwxyz";
$genomic = <<EOG;
pdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdq
rpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqrpdqr
EOG
$genomic =~ s/\n//g;

undef $result;
$result = sim4($genomic, $cDNA);

print "#################\n# Error handling and valid sequence testing.\n#\n";
print "# test that checking for DNA sequences work.\n";
print "#  the result should be undefined.\n";
ok(!$result);
print "#  and GH::Sim4::err string should be the correct string.\n";
ok(GH::Sim4::err =~ m|^The genomic sequence is not a DNA sequence.|);

#########################
#
# Test poly-A (poly-T) trimming
#

# AT01047
$cDNA = slurp("t/cDNA-2.fasta");

# from AE003719
$genomic = slurp("t/genomic-2.fasta");

print "#################\n# Poly A/T trimming.\n#\n";
print "# confirm that alignment w/out options try's to include the poly-A's.\n";

undef $result;
$result = sim4($genomic, $cDNA, {"R" => 2});

ok($result->{exon_count} == 1 &&
   $result->{number_matches} == 594 &&
   $result->{coverage_float} < 1);

print "#\n# and check that alignment w/ option ignores the poly-A's.\n";

undef $result;
$result = sim4($genomic, $cDNA, {"R" => 2, "P" => 1});

ok($result->{exon_count} == 1 &&
   $result->{number_matches} == 591 &&
   $result->{coverage_float} == 1);

print "#\n# and check that it works with leading poly-T's.\n";

$cDNA = slurp("t/cDNA-2-rev.fasta");

undef $result;
$result = sim4($genomic, $cDNA, {"R" => 0, "P" => 1});

ok($result->{exon_count} == 1 &&
   $result->{number_matches} == 591 &&
   $result->{coverage_float} == 1);

#########################
#
# Test optional argument constraint testing
#

print "#\n# check all kinds of invalid arguments and their results\n";
undef $result;
$result = sim4($genomic, $cDNA, {"A" => 2});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^Alignment flag \(A\) must be 0 or 1.*|);

$result = sim4($genomic, $cDNA, {"R" => 100});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^Direction \(R\) must be 0, 1, or 2.*|);

$result = sim4($genomic, $cDNA, {"E" => 100});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^Cutoff \(E\) must be between 3 and 10.*|);

$result = sim4($genomic, $cDNA, {"E" => 1});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^Cutoff \(E\) must be between 3 and 10.*|);

$result = sim4($genomic, $cDNA, {"D" => -1});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^D must be greater than zero.*|);

$result = sim4($genomic, $cDNA, {"H" => -1});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^H must be greater than zero.*|);

$result = sim4($genomic, $cDNA, {"W" => -1});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^Cutoff \(W\) must be between 1 and 15.*|);

$result = sim4($genomic, $cDNA, {"W" => 20});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^Cutoff \(W\) must be between 1 and 15.*|);

$result = sim4($genomic, $cDNA, {"X" => -1});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^X must be greater than 0 \(zero\).*|);

$result = sim4($genomic, $cDNA, {"K" => -1});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^K must be greater than 0 \(zero\).*|);

$result = sim4($genomic, $cDNA, {"C" => -1});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^C must be greater than 0 \(zero\).*|);

$result = sim4($genomic, $cDNA, {"B" => -1});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^B must be either 0 \(zero\) or 1 \(one\).*|);

$result = sim4($genomic, $cDNA, {"S" => "just about anything"});
ok(!defined($result) &&
   GH::Sim4::err =~ m|^Setting S is unsupported.*|);

#########################
#
# Done.
#

exit(0);

sub revcomp {
  my($seq) = @_;
  my($rc);

  $rc = $seq;
  $rc =~ tr/acgtrymkswhbvdnxACGTRYMKSWHBVDNX/tgcayrkmswdvbhnxTGCAYRKMSWDVBHNX/;
  $rc = reverse scalar($rc);
  return($rc);
}

sub slurp {
  my($filename) = @_;
  my($oldSlash);
  my($name);
  my($sequence);

  open SLURP, "<$filename" || die "Unable to open $filename.";

  $name = <SLURP>;
  $oldSlash = $/;
  undef $/;
  $seq = <SLURP>;
  $seq =~ s/\n//g;

  $/ = $oldSlash;
  close SLURP;

  return($seq);
}
