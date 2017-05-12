#!/usr/bin/env perl
#
# Test processing a message/rfc822
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message;

use Test::More tests => 2;
use IO::Scalar;

#
# Reading a very complicate message from scalar
#

my $msg = Mail::Message->read(<<'END-OF-MESSAGE', strip_status_fields => 0);
From: "you" <You@your.place>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="3/Cnt5Mj2+"
Content-Transfer-Encoding: 7bit
Message-ID: <15375.28519.265629.832146@tradef1-fe>
Date: Thu, 6 Dec 2001 14:15:19 +0100 (MET)
To: me@example.com
Subject: forwarded message from Pietje Puk
Status: RO

--3/Cnt5Mj2+
Content-Type: text/plain; charset=us-ascii
Content-Description: message body text
Content-Transfer-Encoding: 7bit

This is some text before a forwarded multipart!!

--3/Cnt5Mj2+
Content-Type: message/rfc822
Content-Description: forwarded message
Content-Transfer-Encoding: 7bit

MIME-Version: 1.0
Content-Type: multipart/alternative;
	boundary="----=_NextPart_000_0017_01C17E5E.A5657580"
Message-ID: <001a01c17e56$5fc02640$5f23643e@ibm5522ccd>
From: "Someone" <tux@fish.aq>
To: "Me" <me@example.com>
Subject: A multipart alternative

This is a multi-part message in MIME format.

------=_NextPart_000_0017_01C17E5E.A5657580
CONTENT-TRANSFER-ENCODING: quoted-printable
Content-Type: text/plain;
	charset="iso-8859-1"

Send me a postcard if you read this.
Oh, another line.

------=_NextPart_000_0017_01C17E5E.A5657580
CONTENT-TRANSFER-ENCODING: quoted-printable
Content-Type: text/html;
	charset="iso-8859-1"

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML><HEAD>
<META http-equiv=3DContent-Type content=3D"text/html; =
charset=3Diso-8859-1">
</HEAD>
<BODY bgColor=3D#ffffff>
Send me a postcard if you read this.<BR>
Oh, another line.<BR>
</BODY></HTML>

------=_NextPart_000_0017_01C17E5E.A5657580--

--3/Cnt5Mj2+--
END-OF-MESSAGE

ok(defined $msg);

my $dump;
my $catch   = IO::Scalar->new(\$dump);
$msg->printStructure($catch);

# if 1550 bytes is reported for the whole message, then the Status
# field hasn't been removed after reading.
is($dump, <<'DUMP');
multipart/mixed: forwarded message from Pietje Puk (1551 bytes)
   text/plain (164 bytes)
   message/rfc822 (1044 bytes)
      multipart/alternative: A multipart alternative (943 bytes)
         text/plain (148 bytes)
         text/html (358 bytes)
DUMP
