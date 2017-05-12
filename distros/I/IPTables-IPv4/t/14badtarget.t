#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..7\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

$table->append_entry("FORWARD", {jump => "DENY"}) && print "not ";
print "ok ", $testiter++, "\n";

foreach my $chain (qw/DROP input forward output/) {
	$table->append_entry($chain, {}) && print "not ";
	print "ok ", $testiter++, "\n";
}

$table->commit() || "# $!\nnot ";
print "ok ", $testiter++, "\n";

exit(0);
# vim: ts=4
