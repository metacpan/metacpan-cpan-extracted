#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..45\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

$table->create_chain("foo") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->create_chain("foo") && print "not ";
print "ok ", $testiter++, "\n";

$table->delete_chain("foo") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->delete_chain("foo") && print "not ";
print "ok ", $testiter++, "\n";

my @builtins = (qw/INPUT FORWARD OUTPUT DROP ACCEPT RETURN QUEUE/);

foreach my $builtin (@builtins) {
	$table->delete_chain($builtin) && print "not ";
	print "ok ", $testiter++, "\n";
}

foreach my $builtin (@builtins) {
	$table->create_chain($builtin) && print "not ";
	print "ok ", $testiter++, "\n";
}

$table->create_chain("foo") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("foo", {}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->delete_chain("foo") && print "not ";
print "ok ", $testiter++, "\n";
$table->delete_entry("foo", {}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("foo", {}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->delete_num_entry("foo", 0) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->delete_chain("foo") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->create_chain("foo") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->create_chain("foo2") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("foo", {jump => "foo2"}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->delete_chain("foo2") && print "not ";
print "ok ", $testiter++, "\n";
$table->append_entry("foo2", {}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->delete_chain("foo2") && print "not ";
print "ok ", $testiter++, "\n";
$table->delete_num_entry("foo", 0) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->delete_chain("foo2") && print "not ";
print "ok ", $testiter++, "\n";
$table->delete_num_entry("foo2", 0) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->delete_chain("foo2") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->create_chain("foo2") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

my $rv = 1;
foreach my $chain ($table->list_chains()) {
	unless ($table->builtin($chain)) {
		($rv = 0) unless $table->delete_chain($chain);
	}
}

print(($rv ? "" : "# $!\nnot "), "ok ", $testiter++, "\n");

$table->create_chain("foo") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->create_chain("foo2") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$rv = 1;
foreach my $chain ($table->list_chains()) {
	($rv = 0) unless $table->flush_entries($chain);
}
print(($rv ? "" : "# $!\nnot "), "ok ", $testiter++, "\n");

$rv = 1;
foreach my $chain ($table->list_chains()) {
	unless ($table->builtin($chain)) {
		($rv = 0) unless $table->delete_chain($chain);
	}
}
print(($rv ? "" : "# $!\nnot "), "ok ", $testiter++, "\n");

$table->append_entry("FORWARD", {jump => "QUEUE"}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

my @rules = $table->list_rules("FORWARD");
if (scalar(@rules) != 1) {
	print "# $!\nnot ";
}
print "ok ", $testiter++, "\n";

my @keylist = keys(%{$rules[0]});
if(scalar(@keylist) != 3 || $rules[0]->{'jump'} ne "QUEUE") {
	print "# $!\nnot ";
}
print "ok ", $testiter++, "\n";

foreach my $chain ($table->list_chains()) {
	$table->flush_entries($chain);
}

foreach my $chain ($table->list_chains()) {
	unless ($table->builtin($chain)) {
		$table->delete_chain($chain);
	}
}

exit(0);
# vim: ts=4
