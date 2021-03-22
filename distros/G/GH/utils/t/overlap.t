######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
BEGIN { $| = 1; print "1..10\n"; }

sub Not {
  print "not ";
}

sub Ok {
  my($i) = @_;
  print "ok $i\n";
}
  
$i = 1;

################################################################
print "# simplest usage.  should find 116 base overlap.\n";

open EXEC, "perl -I.. -MGH::Status::Status ./overlap -s1 t/test1.fasta -s2 t/test2.fasta|" ||
  die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

$expected = << "MOOSE";
s1 name: test.1, length: 200
s2 name: test.2, length: 200

    insert_s1      84 bases.
        match     116 bases.
    insert_s2      84 bases.
MOOSE

Not() if ($output ne $expected); Ok($i++);

################################################################
print "# test the conversational output style\n";

open EXEC, "perl -I.. -MGH::Status::Status ./overlap -s1 t/test1.fasta -s2 t/test2.fasta -outputFormat 1|" ||
  die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

$expected = << "MOOSE";
s1 name: test.1, length: 200
s2 name: test.2, length: 200

There is a 84 base INSERT in sequence 1, starting at position 1.
There is a 116 base MATCH starting at position 85 in sequence 1 and position 1 in sequence 2.
There is a 84 base INSERT in sequence 2, starting at position 117.
MOOSE

Not() if ($output ne $expected); Ok($i++);

################################################################
print "# test the alignment output style\n";

open EXEC, "perl -I.. -MGH::Status::Status ./overlap -s1 t/test1.fasta -s2 t/test2.fasta -outputFormat 2 |" ||
  die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

$expected = << "MOOSE";
s1 name: test.1, length: 200
s2 name: test.2, length: 200

0         GTGCAGTACTGCGTCGATACGACAAACCCAATCGTTCCGTTCTTACAAGC
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          --------------------------------------------------

50        CCTTAAATCAAATAAATTACATATCAGAATTCGCGAATTCTTTAGCACAT
          ++++++++++++++++++++++++++++++++++||||||||||||||||
          ----------------------------------GAATTCTTTAGCACAT

100       CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG
          ||||||||||||||||||||||||||||||||||||||||||||||||||
          CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG

150       AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA
          ||||||||||||||||||||||||||||||||||||||||||||||||||
          AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA

200       --------------------------------------------------
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          CTGTTTTCCTCATCACGGTCCTTTATGTTTCACTACACGCGTCCTAAATC

250       ----------------------------------                
          ++++++++++++++++++++++++++++++++++                
          AATTACGAAAAGCAGAACAACAGCAGAGAAGAGC                

MOOSE

Not() if ($output ne $expected); Ok($i++);

################################################################
print "# test some internal substitutions.\n";

open EXEC, "perl -I.. -MGH::Status::Status ./overlap -s1 t/test1a.fasta -s2 t/test2.fasta -outputFormat 2 |" ||
  die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

$expected = << "MOOSE";
s1 name: test.1 with two substitutions., length: 200
s2 name: test.2, length: 200

0         GTGCAGTACTGCGTCGATACGACAAACCCAATCGTTCCGTTCTTACAAGC
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          --------------------------------------------------

50        CCTTAAATCAAATAAATTACATATCAGAATTCGCGAATTCTTGAGCACAT
          ++++++++++++++++++++++++++++++++++||||||||X|||||||
          ----------------------------------GAATTCTTTAGCACAT

100       CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG
          ||||||||||||||||||||||||||||||||||||||||||||||||||
          CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG

150       AACCATATATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA
          |||||||X||||||||||||||||||||||||||||||||||||||||||
          AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA

200       --------------------------------------------------
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          CTGTTTTCCTCATCACGGTCCTTTATGTTTCACTACACGCGTCCTAAATC

250       ----------------------------------                
          ++++++++++++++++++++++++++++++++++                
          AATTACGAAAAGCAGAACAACAGCAGAGAAGAGC                

MOOSE

Not() if ($output ne $expected); Ok($i++);

################################################################
print "# test a single internal deletion in seq 1.\n";

open EXEC, "perl -I.. -MGH::Status::Status ./overlap -s1 t/test1b.fasta -s2 t/test2.fasta -outputFormat 2 |" ||
  die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

$expected = << "MOOSE";
s1 name: test.1, with a single deletion i..., length: 199
s2 name: test.2, length: 200

0         GTGCAGTACTGCGTCGATACGACAAACCCAATCGTTCCGTTCTTACAAGC
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          --------------------------------------------------

50        CCTTAAATCAAATAAATTACATATCAGAATTCGCGAATTCTTTAGCACAT
          ++++++++++++++++++++++++++++++++++||||||||||||||||
          ----------------------------------GAATTCTTTAGCACAT

100       CAAATTTGGGTCAATGCTATATTC-TAACTATCAACTTACTGTTGATTCG
          ||||||||||||||||||||||||+|||||||||||||||||||||||||
          CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG

150       AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA
          ||||||||||||||||||||||||||||||||||||||||||||||||||
          AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA

200       --------------------------------------------------
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          CTGTTTTCCTCATCACGGTCCTTTATGTTTCACTACACGCGTCCTAAATC

250       ----------------------------------                
          ++++++++++++++++++++++++++++++++++                
          AATTACGAAAAGCAGAACAACAGCAGAGAAGAGC                

MOOSE

Not() if ($output ne $expected); Ok($i++);


################################################################
print "# test a single substitution in seq 1 at the start of the overlap\n";

open EXEC, "perl -I.. -MGH::Status::Status ./overlap -s1 t/test1c.fasta -s2 t/test2.fasta -outputFormat 2 |"
  || die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

$expected = << "MOOSE";
s1 name: test.1, with substitution at fir..., length: 200
s2 name: test.2, length: 200

0         GTGCAGTACTGCGTCGATACGACAAACCCAATCGTTCCGTTCTTACAAGC
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          --------------------------------------------------

50        CCTTAAATCAAATAAATTACATATCAGAATTCGCCAATTCTTTAGCACAT
          ++++++++++++++++++++++++++++++++++X|||||||||||||||
          ----------------------------------GAATTCTTTAGCACAT

100       CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG
          ||||||||||||||||||||||||||||||||||||||||||||||||||
          CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG

150       AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA
          ||||||||||||||||||||||||||||||||||||||||||||||||||
          AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA

200       --------------------------------------------------
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          CTGTTTTCCTCATCACGGTCCTTTATGTTTCACTACACGCGTCCTAAATC

250       ----------------------------------                
          ++++++++++++++++++++++++++++++++++                
          AATTACGAAAAGCAGAACAACAGCAGAGAAGAGC                

MOOSE

Not() if ($output ne $expected); Ok($i++);

################################################################
print "# test a single substitution in seq 1 at the end of the overlap\n";

open EXEC, "perl -I.. -MGH::Status::Status ./overlap -s1 t/test1d.fasta -s2 t/test2.fasta -outputFormat 2 |"
  || die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

$expected = << "MOOSE";
s1 name: test.1, with substitution at las..., length: 200
s2 name: test.2, length: 200

0         GTGCAGTACTGCGTCGATACGACAAACCCAATCGTTCCGTTCTTACAAGC
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          --------------------------------------------------

50        CCTTAAATCAAATAAATTACATATCAGAATTCGCGAATTCTTTAGCACAT
          ++++++++++++++++++++++++++++++++++||||||||||||||||
          ----------------------------------GAATTCTTTAGCACAT

100       CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG
          ||||||||||||||||||||||||||||||||||||||||||||||||||
          CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG

150       AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCT
          |||||||||||||||||||||||||||||||||||||||||||||||||X
          AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA

200       --------------------------------------------------
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          CTGTTTTCCTCATCACGGTCCTTTATGTTTCACTACACGCGTCCTAAATC

250       ----------------------------------                
          ++++++++++++++++++++++++++++++++++                
          AATTACGAAAAGCAGAACAACAGCAGAGAAGAGC                

MOOSE

Not() if ($output ne $expected); Ok($i++);


################################################################
print "# test a single deletion in seq 1 at the end of the overlap\n";

open EXEC, "perl -I.. -MGH::Status::Status ./overlap -s1 t/test1e.fasta -s2 t/test2.fasta -outputFormat 2 |"
  || die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

$expected = << "MOOSE";
s1 name: test.1, with last base of overla..., length: 199
s2 name: test.2, length: 200

0         GTGCAGTACTGCGTCGATACGACAAACCCAATCGTTCCGTTCTTACAAGC
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          --------------------------------------------------

50        CCTTAAATCAAATAAATTACATATCAGAATTCGCGAATTCTTTAGCACAT
          ++++++++++++++++++++++++++++++++++||||||||||||||||
          ----------------------------------GAATTCTTTAGCACAT

100       CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG
          ||||||||||||||||||||||||||||||||||||||||||||||||||
          CAAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCG

150       AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCC-
          |||||||||||||||||||||||||||||||||||||||||||||||||+
          AACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA

200       --------------------------------------------------
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          CTGTTTTCCTCATCACGGTCCTTTATGTTTCACTACACGCGTCCTAAATC

250       ----------------------------------                
          ++++++++++++++++++++++++++++++++++                
          AATTACGAAAAGCAGAACAACAGCAGAGAAGAGC                

MOOSE

Not() if ($output ne $expected); Ok($i++);

################################################################
print "# test a single deletion in seq 1 at the start of the overlap\n";

open EXEC, "perl -I.. -MGH::Status::Status ./overlap -s1 t/test1f.fasta -s2 t/test2.fasta -outputFormat 2 |"
  || die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

$expected = << "MOOSE";
s1 name: test.1, with first base of overl..., length: 199
s2 name: test.2, length: 200

0         GTGCAGTACTGCGTCGATACGACAAACCCAATCGTTCCGTTCTTACAAGC
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          --------------------------------------------------

50        CCTTAAATCAAATAAATTACATATCAGAATTCGCAATTCTTTAGCACATC
          +++++++++++++++++++++++++++++++++X||||||||||||||||
          ---------------------------------GAATTCTTTAGCACATC

100       AAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCGA
          ||||||||||||||||||||||||||||||||||||||||||||||||||
          AAATTTGGGTCAATGCTATATTCTTAACTATCAACTTACTGTTGATTCGA

150       ACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCA-
          |||||||||||||||||||||||||||||||||||||||||||||||||+
          ACCATACATATGTACATATATGGCTCATATCCCCCATAGGCAATACCCAC

200       --------------------------------------------------
          ++++++++++++++++++++++++++++++++++++++++++++++++++
          TGTTTTCCTCATCACGGTCCTTTATGTTTCACTACACGCGTCCTAAATCA

250       ---------------------------------                 
          +++++++++++++++++++++++++++++++++                 
          ATTACGAAAAGCAGAACAACAGCAGAGAAGAGC                 

MOOSE

Not() if ($output ne $expected); Ok($i++);

################################################################
print "# test when there is NO overlap.\n";

open EXEC, "perl -I.. -MGH::Status::Status ./overlap -s1 t/aaa.fasta -s2 t/ttt.fasta |" ||
  die "Could not exec command.";
$/ = undef;
$output = <EXEC>;
close EXEC;

$expected = << "MOOSE";
s1 name: poly-a sequence, length: 320
s2 name: poly-t sequence, length: 320

doOverlap returned status = "fail" (-1)
MOOSE

Not() if ($output ne $expected); Ok($i++);

