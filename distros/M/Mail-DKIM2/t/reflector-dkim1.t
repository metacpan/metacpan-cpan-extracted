#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
BEGIN { eval { require Mail::DKIM::Signer; 1 } or plan skip_all => 'Mail::DKIM not installed'; }
use lib 'lib', 't/lib';
use Mail::DKIM2::Reflector;
use DKIM2TestKeys;

my $msg = "From: a\@test2.dkim2.com\r\nTo: b\@example.test\r\nSubject: hi\r\n"
        . "Date: Tue, 01 Jan 2030 00:00:00 +0000\r\nMessage-ID: <x\@test2.dkim2.com>\r\n"
        . "MIME-Version: 1.0\r\nContent-Type: text/plain\r\n\r\nbody here\r\n";

# one spec -> one well-formed DKIM-Signature
my $pem = DKIM2TestKeys::private_key_pem('test2.dkim2.com', 'sel1');
my $out = Mail::DKIM2::Reflector::sign_dkim1($msg,
    { domain => 'test2.dkim2.com', selector => 'sel1', key => $pem });
my @sigs = $out =~ /^DKIM-Signature:/mg;
is(scalar @sigs, 1, 'one spec -> one DKIM-Signature');
like($out, qr/\bd=test2\.dkim2\.com\b/, 'd= set');
like($out, qr/\bs=sel1\b/, 's= set');
like($out, qr/a=rsa-sha256/, 'a=rsa-sha256');
like($out, qr{c=relaxed/relaxed}, 'c=relaxed/relaxed');
like($out, qr/\bbh=/, 'has a body hash');
like($out, qr/\r\n\r\nbody here\r\n\z/, 'body preserved at end');

# two specs -> two signatures, distinct domains
my $out2 = Mail::DKIM2::Reflector::sign_dkim1($msg,
    { domain => 'test1.dkim2.com', selector => 'dkim2test',
      key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'dkim2test') },
    { domain => 'test2.dkim2.com', selector => 'sel1', key => $pem });
my @s2 = $out2 =~ /^DKIM-Signature:/mg;
is(scalar @s2, 2, 'two specs -> two DKIM-Signature headers');
like($out2, qr/\bd=test1\.dkim2\.com\b/, 'brand d= present');
like($out2, qr/\bs=dkim2test\b/, 'brand s=dkim2test present');

done_testing;
