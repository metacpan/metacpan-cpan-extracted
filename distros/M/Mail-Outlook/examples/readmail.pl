#!/usr/bin/perl -w
use strict;

use lib qw(lib);
use Mail::Outlook;

my $mail = new Mail::Outlook();
die "Cannot create mail object\n"	unless $mail;

my $folder = $mail->folder('Inbox');
die "Cannot create folder object\n"	unless $folder;

my $message = $folder->first;
printf "[first]\nTo: [%s]\nSubject: [%s]\n", $message->To(), $message->Subject();
printf "From: [%s]\n\n", $message->SenderName();
$message = $folder->next;
printf "[next]\nTo: [%s]\nSubject: [%s]\n", $message->To(), $message->Subject();
printf "From: [%s]\n\n", $message->SenderName();
$message = $folder->last;
printf "[last]\nTo: [%s]\nSubject: [%s]\n", $message->To(), $message->Subject();
printf "From: [%s]\n\n", $message->SenderName();
$message = $folder->previous;
printf "[previous]\nTo: [%s]\nSubject: [%s]\n", $message->To(), $message->Subject();
printf "From: [%s]\n\n", $message->SenderName();
