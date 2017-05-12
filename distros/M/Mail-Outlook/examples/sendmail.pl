#!/usr/bin/perl -w
use strict;

use lib qw(lib);
use Mail::Outlook;

my $mail = new Mail::Outlook();
die "Cannot create mail object\n"	unless $mail;

my $message = $mail->create();
die "Cannot create message object\n"	unless $message;

$message->To('test@example.com');
$message->Cc('Test <test@example.com>');
$message->XHeader('X-Header2','That');
$message->Subject('Blah Blah Blah');
$message->Body('Yadda Yadda Yadda');

my $status = $message->display;
print STDERR "message status was [$status]\n";
#$message->send;
