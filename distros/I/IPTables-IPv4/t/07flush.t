#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..9\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

$table->create_chain("foo") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("foo", {}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->flush_entries("foo") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
unless (scalar($table->list_rules("foo")) == 0) {
	print "# $!\nnot ";
}
print "ok ", $testiter++, "\n";

$table->flush_entries("foo") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
unless (scalar($table->list_rules("foo")) == 0) {
	print "# $!\nnot ";
}
print "ok ", $testiter++, "\n";

$table->delete_chain("foo") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->flush_entries("foo") && print "not ";
print "ok ", $testiter++, "\n";

exit(0);
# vim: ts=4
