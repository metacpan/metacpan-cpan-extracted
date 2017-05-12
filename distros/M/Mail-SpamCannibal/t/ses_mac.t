# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Socket;
use Mail::SpamCannibal::Session qw(
	mac
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

# push keys in order, response
my %testhash = qw(
	the	QM26qdKgbWqj230VLxdnPA
	quick	BtQkXKyskTlCvFnv8xrw2w
	brown	9c7pkA0eG0Ol_pTeyEWuPQ
	fox	DyXKCaJgHFW89BtGrm_jQQ
	jumped	KUENefziXMwmJk9_UYoWvw
	over	F1ucCHN5T9EdbxK2LgEwRw
	lazy	fsqofneA3wW9poEIl6MBxw
	dog	4JUK7wCGhh864tPw5wuDaA
	12345	gnzLDuqKcGxMNKFokfhOew
	67890	6Afx_PgtEy-bsBjKZzihnw
);

my @elements;
foreach my $key (sort keys %testhash) {
  push @elements, $key;
  print " $key got: $_, exp: $testhash{$key}\nnot "
	unless ($_ = mac(@elements)) eq $testhash{$key};
  &ok;
}
