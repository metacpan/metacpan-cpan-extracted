#!/usr/local/bin/perl

use IMAP::Admin;

if (scalar(@ARGV) < 1) {
	print "usage: $0 mailbox [mailbox ...]
}

$imap = IMAP::Admin->new('Server' => 'my.server.com', 'Login' => 'admin',
			 'Password' => 'adminpass');

foreach $mailbox (@ARGV) {
	$err = $imap->delete($mailbox);
	if ($err != 0) {
		print "Error occurred destroying $mailbox\n\t$imap->{'Error'}\n";
	}
}
