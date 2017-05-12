# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..63\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Math::Base::Convert;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

$test = 2;

my $bc = new Math::Base::Convert;

sub ok {
  print "ok $test\n";
  ++$test;
}

# test 2 - 3
foreach(0,1) {
  print "is power of 2 - $_\nnot "
	if $bc->isnotp2($_);
  &ok;
}

# test 4 - 63
foreach(2..31) {

  my $n = 2 ** $_;
  print "is power of 2 - $n\nnot "
	if $bc->isnotp2($n);
  &ok;
  $n++;
  print "is NOT power of 2 - $n\nnot "
	unless $bc->isnotp2($n);
  &ok;
}
