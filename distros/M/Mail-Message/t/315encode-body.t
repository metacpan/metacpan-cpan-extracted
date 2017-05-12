#!/usr/bin/env perl

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;
use Mail::Message::Body::Lines;
use Mail::Message::TransferEnc::Base64;

use Test::More tests => 13;
use IO::Scalar;

my $decoded = <<DECODED;
This text is used to test base64 encoding and decoding.  Let
see whether it works.
DECODED

my $encoded = <<ENCODED;
VGhpcyB0ZXh0IGlzIHVzZWQgdG8gdGVzdCBiYXNlNjQgZW5jb2RpbmcgYW5kIGRlY29kaW5nLiAg
TGV0CnNlZSB3aGV0aGVyIGl0IHdvcmtzLgo=
ENCODED

my $body   = Mail::Message::Body::Lines->new
  ( mime_type => 'text/html'
  , transfer_encoding => 'base64'
  , data      => $encoded
  );

ok(defined $body);

my $dec = $body->encode(transfer_encoding => 'none');
ok(defined $dec);
isa_ok($dec, 'Mail::Message::Body');
ok(!$dec->checked, 'checked?');
is($dec->string, $decoded);
is($dec->transferEncoding, 'none');

my $enc = $dec->encode(transfer_encoding => '7bit', charset => 'utf-8');
ok(defined $enc);
isa_ok($enc, 'Mail::Message::Body');
ok($enc->checked, 'checked?');
is($enc->string, $decoded);

my $msg = Mail::Message->buildFromBody($enc, From => 'me', To => 'you'
  , Date => 'now', 'Message-Id' => '<simple>');
ok($msg);
ok($msg->body->checked);

my $fakeout;
my $g = IO::Scalar->new(\$fakeout);
$msg->print($g);

compare_message_prints($fakeout, <<'MSG', 'build from body');
From: me
To: you
Date: now
Message-Id: <simple>
Content-Type: text/html; charset="utf-8"
Content-Transfer-Encoding: 7bit
MIME-Version: 1.0

This text is used to test base64 encoding and decoding.  Let
see whether it works.
MSG
