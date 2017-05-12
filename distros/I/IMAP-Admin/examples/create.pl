#!/usr/local/bin/perl

use IMAP::Admin;

if (scalar(@ARGV) < 1) {
	print "usage: $0 mailbox [mailbox ...]
}

$imap = IMAP::Admin->new('Server' => 'my.server.com', 'Login' => 'admin',
			 'Password' => 'adminpass');

foreach $mailbox (@ARGV) {
	$err = $imap->create($mailbox);
	if ($err != 0) {
		print "Error occurred building $mailbox\n\t$imap->{'Error'}\n";
	}
# if you have Cyrus IMAP you could also do lines like these
#	$err = $imap->set_quota($mailbox, 10000);
#	$err = $imap->set_acl($mailbox, 'admin', 'lrswipcda');
# the c and d are the minimum needed to delete mailboxes in cyrus 2.x
}
