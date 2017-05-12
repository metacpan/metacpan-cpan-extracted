#!/usr/bin/perl

use IPTables::IPv4;

BEGIN { $| = 1; print "1..29\n"; }
$testiter = 1;

my $table = IPTables::IPv4::init('filter');
unless ($table) {
	print "not ok 1\n";
	exit(1);
}
print "ok ", $testiter++, "\n";

$table->create_chain("ppp") || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->append_entry("INPUT", {'in-interface'		=> "ppp0",
							   'jump'				=> "ppp"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("INPUT", {'in-interface'		=> "lo",
							   'protocol'			=> "udp",
			       			   'destination-port'	=> 53,
							   'jump'				=> "ACCEPT"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("INPUT", {'in-interface'		=> "lo",
							   'protocol'			=> "tcp",
							   'destination-port'	=> 53,
							   'jump'				=> "ACCEPT"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("INPUT", {'in-interface'		=> "lo",
							   'jump'				=> "ACCEPT"
							  }) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'source'			=> "194.217.242.0/24",
							 'destination-port'	=> 25,
							 'jump'				=> "ACCEPT"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'destination-port'	=> 113,
							 'jump'				=> "ACCEPT"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'destination-port'	=> 79,
							 'jump'				=> "ACCEPT"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'source-port'		=> 53,
							 'jump'				=> "ACCEPT"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'destination-port'	=> 1080,
							 'tcp-flags'		=> {'mask' => ['SYN', 'RST',
															   'ACK'],
													'comp' => ['SYN']
												   },
							 'jump'				=> "LOG"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'destination-port'	=> 1080,
							 'tcp-flags'		=> {'mask' => ['SYN', 'RST',
															   'ACK'],
													'comp' => ['SYN']
												   },
							 'jump'				=> "DROP"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'destination-port'	=> 8080,
							 'tcp-flags'		=> {'mask' => ['SYN', 'RST',
															   'ACK'],
													'comp' => ['SYN']
												   },
							 'jump'				=> "LOG",
							 'log-level'		=> "notice"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'destination-port'	=> 8080,
							 'tcp-flags'		=> {'mask' => ['SYN', 'RST',
															   'ACK'],
													'comp' => ['SYN']
												   },
							 'jump'				=> "DROP"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'destination-port'	=> "0:1024",
							 'tcp-flags'		=> {'mask' => ['SYN', 'RST',
															   'ACK'],
													'comp' => ['SYN']
												   },
							 'jump'				=> "LOG"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'destination-port'	=> "0:1024",
							 'tcp-flags'		=> {'mask' => ['SYN', 'RST',
															   'ACK'],
													'comp' => ['SYN']
												   },
							 'jump'				=> "DROP"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'destination-port'	=> "6000:6010",
							 'tcp-flags'		=> {'mask' => ['SYN', 'RST',
															   'ACK'],
													'comp' => ['SYN']
												   },
							 'jump'				=> "LOG",
							 'log-level'		=> "alert"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'destination-port'	=> "6000:6010",
							 'tcp-flags'		=> {'mask' => ['SYN', 'RST',
															   'ACK'],
													'comp' => ['SYN']
												   },
							 'jump'				=> "DROP"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "tcp",
							 'jump'				=> "ACCEPT"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->append_entry("ppp", {'protocol'			=> "udp",
							 'destination-port'	=> 53,
							 'jump'				=> "ACCEPT"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "udp",
							 'source-port'		=> 53,
							 'jump'				=> "ACCEPT"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "udp",
							 'source-port'		=> 4000,
							 'jump'				=> "ACCEPT"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "udp",
							 'source-port'		=> 437,
							 'jump'				=> "ACCEPT"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "udp",
							 'source-port'		=> 137,
							 'jump'				=> "LOG"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "udp",
							 'jump'				=> "DROP"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

$table->append_entry("ppp", {'protocol'			=> "icmp",
							 'icmp-type'		=> "redirect",
							 'jump'				=> "DROP"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";
$table->append_entry("ppp", {'protocol'			=> "icmp",
							 'jump'				=> "ACCEPT"
							}) || print "# $!\nnot ";
print "ok ", $testiter++, "\n";

%expected_counts = ('ppp' => 21, 'INPUT' => 4);

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
