#!/usr/bin/env perl
#
# Encoding and Decoding of 7bit
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body::Lines;
use Mail::Message::TransferEnc::SevenBit;

use Test::More tests => 6;

my $decoded = <<DECODED;
yefoiuhéòsjhkw284ÊÈÓUe\000iouoi\013wei
sdfulÓÈËäjlkjliua\000aba
DECODED

my $encoded = <<ENCODED;
yefoiuhirsjhkw284JHSUeiouoiwei
sdfulSHKdjlkjliuaaba
ENCODED

my $codec = Mail::Message::TransferEnc::SevenBit->new;
ok(defined $codec);
is($codec->name, '7bit');

# Test encoding

my $body   = Mail::Message::Body::Lines->new
  ( mime_type => 'text/html'
  , data      => $decoded
  );

my $enc    = $codec->encode($body);
ok($body!=$enc);
is($enc->mimeType, 'text/html');
is($enc->transferEncoding, '7bit');
is($enc->string, $encoded);

# Test decoding

