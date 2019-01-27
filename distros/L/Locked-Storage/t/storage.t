# -*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Locked::Storage;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $N = 2;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

my $a = new Locked::Storage 1;
$a->store("Hello world!", length("Hello world!")) or Not; OK;
$a->get eq "Hello world!" or Not; OK;
$a->lockall or OK; Not;

