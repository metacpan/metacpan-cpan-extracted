# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use GH::MspTools qw(findBestInclusionBulk);
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

$array[0] = ["t/D287a", $s2];
$array[1] = ["t/D287b", $s2];
$resultRef = findBestInclusionBulk($s1, \@array);
Not() if (scalar @{$resultRef} != 2); Ok($i++);

($cost, $ls, $le, $rs, $re) = @{$$resultRef[0]};
Not() if ($cost != 27); Ok($i++);
Not() if ($ls != 34098); Ok($i++);
Not() if ($le != 86374); Ok($i++);
Not() if ($rs != 0); Ok($i++);
Not() if ($re != 52275); Ok($i++);

($cost, $ls, $le, $rs, $re) = @{$$resultRef[1]};
Not() if ($cost != 27); Ok($i++);
Not() if ($ls != 34098); Ok($i++);
Not() if ($le != 86374); Ok($i++);
Not() if ($rs != 0); Ok($i++);
Not() if ($re != 52275); Ok($i++);

# this should fail cuz the second arg. is not the right kind.
$resultRef = findBestInclusionBulk($s1, @array);
Not() if (defined($resultRef)); Ok($i++);

# this should fail cuz the args are fubar
$array[0] = {"t/D287a" => $s2};
$array[1] = {"t/D287b" => $s2};
$resultRef = findBestInclusionBulk($s1, \@array);
Not() if (defined($resultRef)); Ok($i++);

# this should fail cuz are too few args in the inner arrays.
$array[0] = [$s2];
$array[1] = [$s2];
$resultRef = findBestInclusionBulk($s1, \@array);
Not() if (defined($resultRef)); Ok($i++);

# this should fail cuz there are too many values in the inner arrays.
$array[0] = ["t/D287a", $s2, "bullwinkle"];
$array[1] = ["t/D287b", $s2, "moose"];
$resultRef = findBestInclusionBulk($s1, \@array);
Not() if (defined($resultRef)); Ok($i++);
