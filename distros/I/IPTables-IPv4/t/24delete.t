#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..19\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

@testrules = ({'in-interface'		=> "tap0",
			   'protocol'			=> "icmp"},
			  {'in-interface'		=> "tap0",
			   'protocol'			=> "icmp",
			   'icmp-type'			=> "ping"},
			  {'in-interface'		=> "tap0",
			   'matches'			=> ['limit']},
			  {'in-interface'		=> "tap0",
			   'matches'			=> ['limit'],
			   'limit'				=> "5/sec"},
			  {'in-interface'		=> "tap0",
			   'matches'			=> ['limit'],
			   'protocol'			=> "icmp",
			   'icmp-type'			=> "ping"},
			  {'in-interface'		=> "tap0",
			   'protocol'			=> "icmp",
			   'icmp-type'			=> "ping",
			   'matches'			=> ['limit']});

foreach my $rule (@testrules) {
	$table->append_entry("FORWARD", $rule) || print "# $!\nnot ";
	print "ok ", $testiter++, "\n";
	$table->delete_entry("FORWARD", $rule) || print "# $!\nnot ";
	print "ok ", $testiter++, "\n";
	$table->delete_entry("FORWARD", $rule) && print "not ";
	print "ok ", $testiter++, "\n";
}

foreach my $chain ($table->list_chains()) {
	$table->flush_entries($chain);
}

exit(0);
# vim: ts=4
