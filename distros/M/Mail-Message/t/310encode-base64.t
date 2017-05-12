#!/usr/bin/env perl
#
# Encoding and Decoding of Base64
# Could use some more tests....
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body::Lines;
use Mail::Message::TransferEnc::Base64;

use Test::More tests => 11;

my $decoded = <<DECODED;
This text is used to test base64 encoding and decoding.  Let
see whether it works.
DECODED

my $encoded = <<ENCODED;
VGhpcyB0ZXh0IGlzIHVzZWQgdG8gdGVzdCBiYXNlNjQgZW5jb2RpbmcgYW5kIGRlY29kaW5nLiAg
TGV0CnNlZSB3aGV0aGVyIGl0IHdvcmtzLgo=
ENCODED

my $codec = Mail::Message::TransferEnc::Base64->new;
ok(defined $codec);
is($codec->name, 'base64');

# Test encoding

my $body   = Mail::Message::Body::Lines->new
  ( mime_type => 'text/html'
  , data      => $decoded
  );

is($body->mimeType, 'text/html');

my $enc    = $codec->encode($body);
ok($body!=$enc);
is($enc->mimeType, 'text/html');
is($enc->transferEncoding, 'base64');
is($enc->string, $encoded);

# Test decoding

$body   = Mail::Message::Body::Lines->new
  ( transfer_encoding => 'base64'
  , mime_type         => 'text/html'
  , data              => $encoded
  );

my $dec = $codec->decode($body);
ok($dec!=$body);
is($enc->mimeType, 'text/html');
is($dec->transferEncoding, 'none');
is($dec->string, $decoded);

