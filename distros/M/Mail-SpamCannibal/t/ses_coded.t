# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SpamCannibal::Session qw(
	encode
	decode
);

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
	
my $string = q
|1234567890
foo@bar.com
!#$%^&*()_+\=-"':;/?.>,<~`   !#$%^&*()_+\=-"':;/?.>,<~`
the QUICK brown FOX jumped OVER the VERY lazy DOG that WAS sleeping
THE quick BROWN fox JUMPED over THE very LAZY dog THAT was SLEEPING
|;

## test 2	encode
my $expected = 'MTIzNDU2Nzg5MApmb29AYmFyLmNvbQohIyQlXiYqKClfK1w9LSInOjsvPy4-LDx-YCAgICEjJCVeJiooKV8rXD0tIic6Oy8_Lj4sPH5gCnRoZSBRVUlDSyBicm93biBGT1gganVtcGVkIE9WRVIgdGhlIFZFUlkgbGF6eSBET0cgdGhhdCBXQVMgc2xlZXBpbmcKVEhFIHF1aWNrIEJST1dOIGZveCBKVU1QRUQgb3ZlciBUSEUgdmVyeSBMQVpZIGRvZyBUSEFUIHdhcyBTTEVFUElORwo';
my $encoded = encode($string);
print "got: $encoded\nexp: $expected\nnot "
	unless $encoded eq $expected;
&ok;

## test 3	decode
$expected = $string;
my $decoded = decode($encoded);
print "got: $decoded\nexp: $expected\nnot "
	unless $decoded eq $expected;
&ok;

## tests 4-9	check for padding the right length for decode
my $warn = '';
local $SIG{__WARN__} = sub { $warn = $_[0] };
foreach(4..9) {
  $warn = '';
  $string .= $_;
  $encoded = encode($string);
  $decoded = decode($encoded);
  print "warning generated\n$warn\nnot "
	if $warn;
  &ok;
}
