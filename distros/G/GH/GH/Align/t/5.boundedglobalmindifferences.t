# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..114\n"; }
END {print "not ok 1\n" unless $loaded;}
use GH::Align qw(boundedGlobalMinDifferences);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use lib "../../EditOp/blib/lib";
use lib "../../EditOp/blib/arch";

use GH::EditOp;

sub Not {
  print "not ";
}

sub Ok {
  my($i) = @_;
  print "ok $i\n";
}
  
$i = 2;

# check that it gets a single edit operation that aligns
# all of these bases.
$s1 = "ACGTACGTATCCGTACGTAC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 0); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 20); Ok($i++);

# check that it handles a single base missing at the beginning.
$s1 = "CGTACGTATCCGTACGTAC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 1); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 19); Ok($i++);

# check that it handles a single base missing at offset 1
$s1 = "AGTACGTATCCGTACGTAC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 1); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);
$e = $$opsRef[2];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 18); Ok($i++);

# check that it handles a single base missing at offset 2
$s1 = "ACTACGTATCCGTACGTAC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 1); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 2); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);
$e = $$opsRef[2];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 17); Ok($i++);


# check that it handles a single base missing at offset 3
$s1 = "ACGACGTATCCGTACGTAC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 1); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 3); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);
$e = $$opsRef[2];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 16); Ok($i++);


# check that it handles a single base missing at offset 4
$s1 = "ACGTCGTATCCGTACGTAC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 1); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 4); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);
$e = $$opsRef[2];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 15); Ok($i++);

# check that it handles a single base missing at offset 4
$s1 = "ACGTAGTATCCGTACGTAC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 1); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 5); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);
$e = $$opsRef[2];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 14); Ok($i++);

# check that it handles a single base missing at offset 19
$s1 = "ACGTACGTATCCGTACGTA";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 1); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 19); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);

# check that it handles a single base missing at offset 18
$s1 = "ACGTACGTATCCGTACGTC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 1); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 18); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);
$e = $$opsRef[2];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);

# check that it handles a single base missing at offset 17
$s1 = "ACGTACGTATCCGTACGAC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 1); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 17); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);
$e = $$opsRef[2];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 2); Ok($i++);

# check that it handles a single base missing at offset 16
$s1 = "ACGTACGTATCCGTACTAC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 1); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 16); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);
$e = $$opsRef[2];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 3); Ok($i++);

# check that it handles a missing final three bases
# (w/ bound of two, should'nt work).
$s1 = "ACGTACGTATCCGTACT";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != -6); Ok($i++); # bound too tight....


# check that it handles a missing final three bases
# (w/ bound of two, should'nt work).
$s1 = "ACGTACGTACGTACGTAC";
$s2 = "ACGTACGTATCCGTACGTAC";
$aRef = boundedGlobalMinDifferences($s1, $s2, 2);
$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 2); Ok($i++);
$opsRef = $$aRef[2];
$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 9); Ok($i++);
$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 2); Ok($i++);
$e = $$opsRef[2];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 9); Ok($i++);

# now do some bigger sequences.

$s1 = <<MOOSE;
GGAAGACGAGATCGGAAGTGAGTCATTGTGGTGGGCTCCTCGGGTGTGCTGTCGGAGCGGTTGAA
GGAGTCGGTCCCACATAACTCGCCAACCACCGTGGTGCTTGAGGAAGCTGCTGCTGCAGTCGCAG
CCACAAGCGACAAGCGTCCATTGTTTGTTTGGATTGAACTTTGCTGCTTTAGCTTCGACTGTTTG
TGCTCAAAAAGTTCGAGTTCGCCGAGAGAAGCGTGAAAATCCGATATCGAAACTACGTTTTTTTT
TTAGTCATTATACCGATTGGCTATGCAAATTTAATTGCGGATCTCCCAAATCATCGAAAAGCCAA
CAGGTCGCCCCTCAACCAAAATAAACACAACAATCGAGCCGCAAATGAAACGGGCAAAAACAGCA
AAGGCAACTGGCGAACCGCTTAACCGGTTTCGAAATATCCATCGTAGCACAGTTTCCTCGTCCAT
ATAATATTCCGATTGCAGTGGATCAAAATATACACACACACACTCGCATATAAATTCGCAGATAT
ACGTTGTTTGTGTGAGTTTCTGTTTGTGGTTCGCGTGAAAAATAGTTTTGACAAATAAATACAAA
GCCAGACGCCGACATAACTGTGAAAATAAACCATAAGCCAGACAGCAGCCATGGGTTATTCCATT
AAGAACTGCGAAACGGTGAGTTGGAGTACTTCTACACAGACACCGTCCGCGTTAATAGACCGGC
CTTCGATGAGGAGACCGGTGAACCGATCCACGACCAGGTGACCAAGGTTCACTTCCGCAAACACA
CGAATTTCCATGTACCCAAGCACTATCTCCGCGGAACCATATGCGATGAGGTAGACGACGAGCTG
GCCAATACGGTGAGATATGGGGCAGCCACCGCGATTCCCAACAGGGGAAGACGAGATCGGCACCC
AAAAAGGTCACTCCGGGCTACGAACGCGAGGACTATTGTCAAATGGATGGCGTGAGCAACAACAT
AATCCTGGGCTACAACCGCAACCCCTACTTGCTGTTCCTGGTGCCCACGCTCTTCTGCTACAACT
TCGTCATTGGAGCCACGCTGGCCCTCATCGAGATCGTCCTGCACATGATGTCCCACCACAGGAAC
GGTCTCACCATGCAGAAGAGCCTGTACTTCCGTAGTCCACTCAACGTGCTGTCCTCGCAGTTCTG
CGCCATCTGCCGCACGGAAACCGACAGCAAGTACAACCGCATCTTCGATATCCTTAACAAGCAGA
TGCGCAACGCACATCGCTCCGAGGCGCTGAAGACATGGCCAAGGCAATTGGATAAGCTGGGAGA
GATTCGATTTGATATGGTCCATATATTTAACACAAATGTTTTTGTCACACGGTCAACAAAAAATA
AATGCACTCGTTTATCACTCAAAAAAAAAAAAAAAAA
MOOSE

$s2 = <<MOOSE;
GGAAGACGAGATCGGAAGTGAGTCATTGTGGTGGGCTCCTCGGGTGTGCTGTCGGAGCGGTTGAA
GGAGTCGGTCCCACATAACTCGCCAACCACCGTGGTGCTTGAGGAAGCTGCTGCTGCAGTCGCAG
CCACAAGCGACAAGCGTCCATTGTTTGTTTGGATTGAACTTTGCTGCTTTAGCTTCGACTGTTTG
TGCTCAAAAAGTTCGAGTTCGCCGAGAGAAGCGTGAAAATCCGATATCGAAACTACGTTTTTTTT
TTAGTCATTATACCGATTGGCTATGCAAATTTAATTGCGGATCTCCCAAATCATCGAAAAGCCAA
CAGGTCGCCCCTCAACCAAAATAAACACAACAATCGAGCCGCAAATGAAACGGGCAAAAACAGCA
AAGGCAACTGGCGAACCGCTTAACCGGTTTCGAAATATCCATCGTAGCACAGTTTCCTCGTCCAT
ATAATATTCCGATTGCAGTGGATCAAAATATACACACACACACTCGCATATAAATTCGCAGATAT
ACGTTGTTTGTGTGAGTTTCTGTTTGTGGTTCGCGTGAAAAATAGTTTTGACAAATAAATACAAA
GCCAGACGCCGACATAACTGTGAAAATAAACCATAAGCCAGACAGCAGCCATGGGTTATTCCATT
AAGAACTGCGAAACGGGTGAGTTGGAGTACTTCTACACAGACACCGTCCGCGTTAATAGACCGGC
CTTCGATGAGGAGACCGGTGAACCGATCCACGACCAGGTGACCAAGGTTCACTTCCGCAAACACA
CGAATTTCCATGTACCCAAGCACTATCTCCGCGGAACCATATGCGATGAGGTAGACGACGAGCTG
GCCAATACGGTGAGATATGGGGCAGCCACCGCGATTCCCAACAGGGGAAGACGAGATCGGCACCC
AAAAAGGTCACTCCGGGCTACGAACGCGAGGACTATTGTCAAATGGATGGCGTGAGCAACAACAT
AATCCTGGGCTACAACCGCAACCCCTACTTGCTGTTCCTGGTGCCCACGCTCTTCTGCTACAACT
TCGTCATTGGAGCCACGCTGGCCCTCATCGAGATCGTCCTGCACATGATGTCCCACCACAGGAAC
GGTCTCACCATGCAGAAGAGCCTGTACTTCCGTAGTCCACTCAACGTGCTGTCCTCGCAGTTCTG
CGCCATCTGCCGCACGGAAACCGACAGCAAGTACAACCGCATCTTCGATATCCTTAACAAGCAGA
TGCGCAACGCACATCGCTCCGAGGCGCTGAAGGACATGGCCAAGGCAATTGGATAAGCTGGGAGA
GATTCGATTTGATATGGTCCATATATTTAACACAAATGTTTTTGTCACACGGTCAACAAAAAATA
AATGCACTCGTTTATCACTCAAAAAAAAAAAAAAT
MOOSE

$s1 =~ s/\n//g;
$s2 =~ s/\n//g;

$aRef = boundedGlobalMinDifferences($s1, $s2, 5);

$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 5); Ok($i++);

$opsRef = $$aRef[2];

#printOps($opsRef);

Not() if (scalar(@{$opsRef}) != 8); Ok($i++);

$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 664); Ok($i++);

$e = $$opsRef[1];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);

$e = $$opsRef[2];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 601); Ok($i++);

$e = $$opsRef[3];
Not() if ($e->getType != 4); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);

$e = $$opsRef[4];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 118); Ok($i++);

$e = $$opsRef[5];
Not() if ($e->getType != 3); Ok($i++);
Not() if ($e->getCount != 2); Ok($i++);

$e = $$opsRef[6];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 14); Ok($i++);

$e = $$opsRef[7];
Not() if ($e->getType != 2); Ok($i++);
Not() if ($e->getCount != 1); Ok($i++);


open FH, "<t/D287";
<FH>;			# snarf the title line.
$s1 = "";
while (<FH>) {
  chomp;
  $s1 .= $_;
}
close FH;

open FH, "<t/D287.hacked";
<FH>;			# snarf the title line.
$s2 = "";
while (<FH>) {
  chomp;
  $s2 .= $_;
}
close FH;

$aRef = boundedGlobalMinDifferences($s1, $s2, 5);

$status = $$aRef[0];
Not() if ($status != 0); Ok($i++);
$cost = $$aRef[1];
Not() if ($cost != 0); Ok($i++);

$opsRef = $$aRef[2];

#printOps($opsRef);

Not() if (scalar(@{$opsRef}) != 1); Ok($i++);

$e = $$opsRef[0];
Not() if ($e->getType != 1); Ok($i++);
Not() if ($e->getCount != 52276); Ok($i++);


exit 0;

