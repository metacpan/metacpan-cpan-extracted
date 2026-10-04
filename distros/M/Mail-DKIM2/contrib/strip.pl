#!/usr/bin/perl -w

use 5.020;
use Path::Tiny;
use Email::MIME;

my $f1 = shift || die;

my $msg1 = Email::MIME->new(path($f1)->slurp);
$msg1->header_raw_set('MailVersion');
$msg1->header_raw_set('Mail-Version');
$msg1->header_raw_set('Message-Instance');
$msg1->header_raw_set('DKIM2-Signature');

print $msg1->as_string();
