#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..11\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

$table->create_chain("test") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("test", {jump => "LOG"}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("test", {jump => "REJECT"}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("test", {matches => ["limit"]}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("test", {protocol => "icmp", "icmp-type" => "ping" }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("test", {protocol => "tcp", "source-port" => 100}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("test", {protocol => "udp", "source-port" => 100}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("test", {matches => ["unclean"]}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->flush_entries("test") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->delete_chain("test") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

exit(0);
# vim: ts=4
