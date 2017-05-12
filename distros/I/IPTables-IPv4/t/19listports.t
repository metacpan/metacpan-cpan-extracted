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

$table->append_entry("INPUT", {protocol => "tcp", 'source-port' => "telnet", jump => "DROP"}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("INPUT", {protocol => "udp", 'source-port' => "domain", jump => "DROP"}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

my @rules = $table->list_rules("INPUT");
print "# $!\nnot " unless scalar(@rules) == 2;
print "ok ", $testiter++, "\n";

print "# $!\nnot " unless scalar(keys(%{$rules[0]})) == 5 && $rules[0]->{protocol} eq "tcp" && $rules[0]->{'source-port'} eq "telnet" && $rules[0]->{jump} eq "DROP";
print "ok ", $testiter++, "\n";

print "# $!\nnot " unless scalar(keys(%{$rules[1]})) == 5 && $rules[1]->{protocol} eq "udp" && $rules[1]->{'source-port'} eq "domain" && $rules[1]->{jump} eq "DROP";
print "ok ", $testiter++, "\n";

$table->flush_entries("INPUT") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

exit(0);
# vim: ts=4
