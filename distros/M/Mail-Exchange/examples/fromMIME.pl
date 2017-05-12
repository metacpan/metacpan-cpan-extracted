#!/usr/bin/perl

# Read a MIME formatted message from a file, and create a .msg file from it.

use Email::MIME;
use Mail::Exchange::Message::Email;


my $file=$ARGV[0] || "examples/MIMEMail.eml";
open(MAIL, "<$file");
do {
	local $/;
	$mail=<MAIL>;
};
close MAIL;

my $parsed=Email::MIME->new($mail);
my $msg=Mail::Exchange::Message::Email->fromMIME($parsed);

$msg->save("fromMime.msg");

