#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..20\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

$table->create_chain("PPP") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->create_chain("LOGDROP") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->append_entry("INPUT", {'in-interface'		=> "ppp0",
							   'jump'				=> "PPP"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->append_entry("PPP", {'source'				=> "10.0.0.0/8",
							 'jump'					=> "LOGDROP"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("PPP", {'source'				=> "127.0.0.0/8",
							 'jump'					=> "LOGDROP"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("PPP", {'source'				=> "192.168.0.0/16",
							 'jump'					=> "LOGDROP"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("PPP", {'source'				=> "172.16.0.0/12",
							 'jump'					=> "LOGDROP"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("PPP", {'protocol'				=> "tcp",
							 'destination-port'		=> 25,
							 'jump'					=> "ACCEPT"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("PPP", {'source'				=> "195.116.50.204",
							 'jump'					=> "ACCEPT"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("PPP", {'source'				=> "195.116.50.3",
							 'jump'					=> "ACCEPT"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("PPP", {'source'				=> "212.160.112.131",
							 'jump'					=> "ACCEPT"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("PPP", {'source'				=> "212.244.102.188",
							 'jump'					=> "ACCEPT"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("PPP", {'protocol'				=> "tcp",
							 'destination-port'		=> ":1023",
							 'jump'					=> "LOGDROP"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("PPP", {'protocol'				=> "udp",
							 'destination-port'		=> ":1023",
							 'jump'					=> "LOGDROP"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("LOGDROP", {'jump' => "LOG"}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("LOGDROP", {'jump' => "DROP"}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

%expected_counts = ('PPP' => 11, 'INPUT' => 1, 'LOGDROP' => 2);

foreach my $key (keys(%expected_counts)) {
	my $count = $table->list_rules($key);
	if ($count != $expected_counts{$key}) {
		print "# expected ", $expected_counts{$key},
			  " rules in chain $key, got $count\nnot ";
	}
	print "ok ", $testiter++, "\n";
}

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
