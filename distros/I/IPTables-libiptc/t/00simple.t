#!/usr/bin/perl

use IPTables::libiptc;

# Notice, tests will be skipped if not run as root.
BEGIN {
    $| = 1; print "1..";

    if ($< == 0) { # UID check
	print "2\n"; # (number of tests)
    } else {
	print "0 # Skip Need to be root\n";
	exit(0);
    }
}

my $testiter = 1;

# TEST: init
my $table = IPTables::libiptc::init('filter');
unless ($table) {
        print STDERR "$!\n";
	print "not ok $testiter\n";
        exit(0);
}
#print "ok\n";
print "ok $testiter \n";
$testiter++;

# TEST: is_chain
if(! $table->is_chain("FORWARD")) {
 print "not ";
}
print "ok $testiter\n";
$testiter++;
