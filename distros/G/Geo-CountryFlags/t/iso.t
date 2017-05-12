# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#use diagnostics;

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

use Geo::CountryFlags::ISO;
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my $gn;

## test 2
print "failed to get method pointer\nnot "
	unless ($gn = hashptr Geo::CountryFlags::ISO);
&ok;

## test 3

my $exp = 'United States';
print "got: $_, exp: $exp\nnot "
	unless ($_ = $gn->{US}) && ($_ = $gn->{US}) eq $exp;
&ok;

