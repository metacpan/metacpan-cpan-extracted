# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

use IPTables::IPv4::DBTarpit::Tools qw(
	libversion
	bdbversion
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

sub checkversion {
  my($sub) = @_;
  my ($string,$major,$minor,$patch) = &$sub;
  my $strg_alone = &$sub;
  print "scalar and array context do not return the same data
scalar: $strg_alone
array : $string\nnot "
	unless $strg_alone eq $string;
  &ok;

  $strg_alone =~ /(\d+)\.(\d+).(\d+)/;
  print "major: $major, exp: $1\nnot "
	unless $major == $1;
  &ok;

  print "minor: $minor, exp: $2\nnot "
	unless $minor == $2;
  &ok;

  print "patch: $patch, exp: $3\nnot "
	unless $patch == $3;
  &ok;
}

foreach(\&libversion, \&bdbversion) {
  checkversion($_);
}
