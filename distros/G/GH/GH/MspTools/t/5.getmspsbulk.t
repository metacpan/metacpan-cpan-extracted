# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use GH::MspTools qw(getMSPsBulk);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use lib "../../Msp/blib/lib";
use lib "../../Msp/blib/arch";

use GH::Msp;

sub Not {
  print "not ";
}

sub Ok {
  my($i) = @_;
  print "ok $i\n";
}
  
$i = 2;

open FH, "<t/D861";
<FH>;			# snarf the title line.
$s1 = "";
while (<FH>) {
  chomp;
  $s1 .= $_;
}
close FH;

open FH, "<t/D287";
<FH>;			# snarf the title line.
$s2 = "";
while (<FH>) {
  chomp;
  $s2 .= $_;
}
close FH;

$GH::MspTools::mspThreshold = 200;
$array[0] = $s2;
$array[1] = $s2;
$array[2] = $s1;
$resultRef = getMSPsBulk($s1, \@array);

use Data::Dumper;
print Dumper $resultRef;

$array[0] = "ATATATATATATATATATATATATATATATATATATATATATATATATAT";
$array[1] = "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC";
$array[2] = "TATATATATATATATATATATATATATATATATATATATATATATATATA";
$resultRef = getMSPsBulk("ATATATATATATATATATATATATATATATATATATATATATA",
			 \@array);

my($result);
foreach $result (@{$resultRef}) {
  if (defined($result)) {
    print "YEP\n";
  }
  else {
    print "NOPE\n";
  }
}

use Data::Dumper;
print Dumper $resultRef;

print $i;
