#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..17\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

foreach my $chain (qw/INPUT FORWARD OUTPUT test/) {
	$table->rename_chain($chain, "input") && print "not ";
	print "ok ", $testiter++, "\n";
}

$table->create_chain("test") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

foreach my $chain (qw/INPUT FORWARD OUTPUT ACCEPT DROP this-is-really-a-ridiculously-long-name-for-a-chain test/) {
	$table->rename_chain("test", $chain) && print "not ";
	print "ok ", $testiter++, "\n";
}

$table->rename_chain("test", "test2") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->is_chain("test") && print "not ";
print "ok ", $testiter++, "\n";

$table->is_chain("test2") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->delete_chain("test2") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

exit(0);
# vim: ts=4
