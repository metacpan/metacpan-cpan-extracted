# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use GH::MspTools qw(findBestOverlap);
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

open FH, "<t/poodle1";
$s1 = <FH>;
close FH;
$s1 =~ s/\n//g;

open FH, "<t/poodle2";
$s2 = <FH>;
close FH;
$s2 =~ s/\n//g;

$bestOverlapRef = findBestOverlap($s1, $s2);
($cost, $ls, $le, $rs, $re) = @{$bestOverlapRef};
Not() if ($cost != 3); Ok($i++);
Not() if ($ls != 15050); Ok($i++);
Not() if ($le != 15246); Ok($i++);
Not() if ($rs != 0); Ok($i++);
Not() if ($re != 199); Ok($i++);

