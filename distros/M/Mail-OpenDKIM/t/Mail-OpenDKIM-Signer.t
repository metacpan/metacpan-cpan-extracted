#!/usr/bin/perl -wT

use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mail-OpenDKIM-Signer.t'

#########################

use Test::More tests => 11;
BEGIN { use_ok('Mail::OpenDKIM::Signer') };

#########################

my $pk = Mail::OpenDKIM::PrivateKey->load(File => 't/example.key');

ok(defined($pk));

isa_ok($pk, 'Mail::OpenDKIM::PrivateKey');

my $dkim = new_ok('Mail::OpenDKIM::Signer' => [
		Algorithm => 'rsa-sha1',
		Method => 'relaxed',
		Domain => 'example.com',
		Selector => 'example',
		Key => $pk
	]
);

my $msg = <<'EOF';
From: Nigel Horne <njh@example.com>
To: Tester <dktest@blackops.org>
Subject: Testing O

Can you hear me, Mother?
EOF

$msg =~ s/\n/\r\n/g;

$dkim->PRINT($msg);

$dkim->CLOSE();

my $signature = $dkim->signature;

ok(defined($signature));

isa_ok($signature, 'Mail::OpenDKIM::Signature');

my $sig = $signature->as_string;

ok(defined($sig),'got a signature');

like($sig, qr/^DKIM-Signature: /,'signature header');
like($sig, qr/a=rsa-sha1/,'signature type rsa-sha1');
like($sig, qr/d=example.com/,'signature domain example.com');

my $dkim1 = new_ok('Mail::OpenDKIM::Signer' => [
		Algorithm => 'rsa-sha1',
		Method => 'relaxed',
		Domain => 'example.com',
		Selector => 'example',
		KeyFile => 't/example.key'
	]
);
