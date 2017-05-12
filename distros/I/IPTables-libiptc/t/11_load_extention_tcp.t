#!/usr/bin/perl

use IPTables::libiptc;

# Notice, tests will be skipped if not run as root.
BEGIN {
    $| = 1; print "1..";

    if ($< == 0) { # UID check
	print "3\n"; # (number of tests)
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
    exit(1);
}
#print "ok\n";
print "ok $testiter \n";
$testiter++;

my $chainname = "testchain2";
# TEST: create_chain
if(! $table->create_chain("$chainname")) {
 print STDERR "$!\n";
 print "not ";
}
print "ok $testiter\n";
$testiter++;

# TEST: Rules
my @arguments = ("-I", "$chainname", "-p", "tcp", "--dport", "123");
if(! $table->iptables_do_command(\@arguments)) {
 print STDERR "$!\n";
 print "not ";
}
print "ok $testiter\n";
$testiter++;

# TEST: commit
#if(! $table->commit()) {
# print "not ";
#}
#print "ok $testiter\n";
#$testiter++;
