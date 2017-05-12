#!/usr/bin/perl
use lib "lib", "t";
use MIME::Lite;
use Test::More;
use Utils;

if (eval { require MIME::Types; MIME::Types->VERSION(1.28); 1 }) {
  plan tests => 1;
} else {
  plan skip_all => "MIME::Types >= 1.28 not available";
}

$MIME::Lite::VANILLA = 1;

# warn "#\n#Testing MIME::Types interaction\n";
my $msg = MIME::Lite->new(
  From    => 'me@myhost.com',
  To      => 'you@yourhost.com',
  Cc      => 'some@other.com, some@more.com',
  Subject => 'Helloooooo, nurse!',
  Data    => "How's it goin', eh?"
);

# this test requires output in a particular order, so specify it
$msg->field_order(qw(
  Content-Transfer-Encoding
  Content-Type
  MIME-Version
  From
  To
  Cc
  Subject
));

$msg->attach(
  Type     => 'AUTO',
  Path     => "./testin/test.html",
  ReadNow  => 1,
  Filename => "test.html",
);

(my $ret=$msg->stringify)=~s/^Date:.*\n//m;

    my $expect=<<'EOFEXPECT';
Content-Transfer-Encoding: 7bit
Content-Type: multipart/mixed; boundary="_----------=_0"
MIME-Version: 1.0
From: me@myhost.com
To: you@yourhost.com
Cc: some@other.com, some@more.com
Subject: Helloooooo, nurse!

This is a multi-part message in MIME format.

--_----------=_0
Content-Disposition: inline
Content-Transfer-Encoding: 8bit
Content-Type: text/plain

How's it goin', eh?
--_----------=_0
Content-Disposition: inline; filename="test.html"
Content-Transfer-Encoding: 8bit
Content-Type: text/html; name="test.html"

This isn't really html. We are only checking the filename silly.
--_----------=_0--

EOFEXPECT

is($ret, $expect, "we got the message we expected");

