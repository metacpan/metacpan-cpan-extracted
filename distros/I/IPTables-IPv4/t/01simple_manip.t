#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..14\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

foreach my $chain (qw/INPUT FORWARD OUTPUT/) {
	$table->append_entry($chain, {}) || print "# $!\nnot ";
	print "ok ", $testiter++, "\n";
	$table->delete_entry($chain, {}) || print "# $!\nnot ";
	print "ok ", $testiter++, "\n";
}

my @targets = (qw/ACCEPT DROP RETURN/);
foreach my $target (@targets) {
	$table->append_entry("FORWARD", {jump => $target}) || print "# $!\nnot ";
	print "ok ", $testiter++, "\n";
}

my @rules = $table->list_rules("FORWARD");
if (scalar(@rules) != 3) {
	print "# $!\nnot ";
}
print "ok ", $testiter++, "\n";

foreach my $rule (@rules) {
	my @keylist = keys(%$rule);
	my $target = shift(@targets);
	if(scalar(@keylist) != 3 || $$rule{'jump'} ne $target) {
		print "# $!\nnot ";
	}
	print "ok ", $testiter++, "\n";
}

$table->flush_entries("FORWARD");
exit(0);
# vim: ts=4
