#!/usr/local/bin/perl
#
# Copyright (c) 1998 Ugen Antsilevitch (ugen@freebsd.org)
# This software can be used anywhere anytime freely.
# This copyright has to be attached to any software or product that
# uses this code.
#
# This is a working example program that uses IMAPGet module.
# It has a set of rules to either move messages from inbox to other
# folders or delete them. The rules are my actual set, you have to write
# your own. The username and password are in this file so this 
# script HAS to have permissions of 500 (no Read/Execute for either
# group or other users).
#
# Add it's own directory to @INC;
BEGIN {
$0 =~ /(.+)\/.+/;
unshift @INC, $1;
}

use IMAPGet;
use NSErr;

#
#
# Rules go here, keep the format - 'IMAP search filter', 'MOV or DEL', 'folder'
#
@rules = ( 'OR (TO freebsd.org) (CC freebsd.org)' , 'MOV', 'Work/FreeBSD' ,
	   'OR (TO bugtraq@netspace.org) (CC bugtraq@netspace.org)', 'MOV', 'Work/Lists',
	   'FROM bugtraq@netspace.org', 'MOV', 'Work/Lists',
	   'SUBJECT "Netscape Mail Server Message Action Form"', 'MOV', 'Work/Postmaster-ACT',
	   'FROM Error-Handler', 'DEL', 'xxx');
	   

#
# This stuff is important but make sure this file is 700 in permissions
#
$password = "SECRET";
$username = "mr.user";
$imaphost = "imap.server.com";


$dump = 0;
$verbose = 0;


NSErr:nserr_setup();
my $test = IMAPGet->new(ImapHost => $imaphost , Username => $username, 
			Password => $password, Verbose => $verbose, Dump => $dump);

die "Can't connect to $imaphost\n" unless $test->connect();
die "Can't logon as $username\n" unless $test->logon();
$res = $test->select("inbox");
die "Can't select folder inbox\n" unless defined $res;

while  (($search = shift @rules) and 
	($action = shift @rules) and
	($folder = shift @rules)) {
	    	next unless @smsgs = $test->search($search);

		if ($action eq "MOV") {
			print "Can't copy\n" unless $res = $test->copy($folder, @smsgs);
			$action = "DEL" if $res;
		}

		if ($action eq "DEL") {
			print "Can't delete\n" unless $test->del(@smsgs);
		}
}

