#!/usr/local/bin/perl

#
# $Header: /cvsroot/Net::EasyTCP/util/client.pl,v 1.5 2003/02/28 19:50:10 mina Exp $
#

$| = 1;

use Net::EasyTCP;

$hostname = shift || "localhost";

$client = new Net::EasyTCP(
	mode => "client",
	host => $hostname,
	port => 2345,
  )
  || die "ERROR CREATING CLIENT: $@\n";

$encryption  = $client->encryption()  || "NO";
$compression = $client->compression() || "NO";

print "Using $encryption encryption and $compression compression\n\n";

#Send and receive a simple string
print "Sending simple string . . . ";
$string = "HELLO THERE";
$client->send($string) || die "ERROR SENDING: $@\n";
print "receiving . . . ";
$reply = $client->receive() || die "ERROR RECEIVING: $@\n";
if ($reply ne $string) {
	print "ERROR: REPLY MISMATCHED SENT . . . ";
}
print "done\n\n";

#Send and receive complex objects/strings/arrays/hashes by reference
print "Sending hashref . . . ";
%hash = ("to be or" => "not to be", "just another" => "perl hacker");
$client->send(\%hash) || die "ERROR SENDING: $@\n";
print "receiving . . . ";
$reply = $client->receive() || die "ERROR RECEIVING: $@\n";
foreach (keys %{$reply}) {
	print "Received key: $_ = $reply->{$_}\n";
}
print "done\n\n";

#Send and receive large binary data
print "Sending large binary data . . . ";
for (1 .. 4096) {
	for (0 .. 255) {
		$largedata .= chr($_);
	}
}
$client->send($largedata) || die "ERROR SENDING: $@\n";
print "receiving . . . ";
$reply = $client->receive() || die "ERROR RECEIVING: $@\n";
if ($largedata ne $reply) {
	print "WARNING : RECEIVED DATA MISMATCHED MISMATCH . . . ";
}
print "done\n\n";

$client->close();

