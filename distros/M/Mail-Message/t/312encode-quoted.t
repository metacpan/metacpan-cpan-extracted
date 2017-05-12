#!/usr/bin/env perl
#
# Encoding and Decoding quoted-print bodies
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body::Lines;
use Mail::Message::TransferEnc::QuotedPrint;

use Test::More tests => 10;

my $src = <<SRC;
In the source text, there are a few \010\r strange characters,
which \200\201 must become encoded.  There is also a \010== long line, which must be broken into pieces, and
there are = confusing constructions like this one: =0D, which looks
encoded, but is not.
SRC

my $encoded = <<ENCODED;
In the source text, there are a few =08=0D strange characters,
which =80=81 must become encoded.  There is also a =08=3D=3D long line, whi=
ch must be broken into pieces, and
there are =3D confusing constructions like this one: =3D0D, which looks
encoded, but is not.
ENCODED

my $codec = Mail::Message::TransferEnc::QuotedPrint->new;
ok(defined $codec);
is($codec->name, 'quoted-printable');

# Test encoding

my $body   = Mail::Message::Body::Lines->new
  ( mime_type => 'text/html'
  , data      => $src
  );

my $enc    = $codec->encode($body);
ok($body!=$enc);
is($enc->mimeType, 'text/html');
is($enc->transferEncoding, 'quoted-printable');
is($enc->string, $encoded);

# Test decoding

$body   = Mail::Message::Body::Lines->new
  ( transfer_encoding => 'quoted-printable'
  , mime_type         => 'text/html'
  , data              => $encoded
  );

my $dec = $codec->decode($body);
ok($dec!=$body);
is($enc->mimeType, 'text/html');
is($dec->transferEncoding, 'none');
is($dec->string, $src);

