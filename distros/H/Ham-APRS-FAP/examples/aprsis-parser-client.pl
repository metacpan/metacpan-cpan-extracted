#!/usr/bin/perl

use Ham::APRS::IS;
use Ham::APRS::FAP qw(parseaprs);

my $is = new Ham::APRS::IS('rotate.aprs.net:10152', 'N0CALL', 'appid' => 'IS-pm-test 1.0');
$is->connect('retryuntil' => 3) || die "Failed to connect: $is->{error}";

for (my $i = 0; $i < 10; $i += 1) {
	my $l = $is->getline_noncomment();
	next if (!defined $l);
	
	print "\n--- new packet ---\n";
	print "$l\n";
	
	my %packetdata;
	my $retval = parseaprs($l, \%packetdata);
	
	if ($retval == 1) {
		while (my ($key, $value) = each(%packetdata)) {
			print "$key: $value\n";
		}
	} else {
		warn "Parsing failed: $packetdata{resultmsg} ($packetdata{resultcode})\n";
	}
}

$is->disconnect() || die "Failed to disconnect: $is->{error}";

