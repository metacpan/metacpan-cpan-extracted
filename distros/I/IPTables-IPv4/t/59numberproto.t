#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..2\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

$table->append_entry("INPUT", {'protocol'		=> 6,
							   'source'			=> "1.2.3.4/32",
							   'source-port'	=> 11111,
							   'jump'			=> "ACCEPT"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->flush_entries("INPUT");

exit(0);
# vim: ts=4
