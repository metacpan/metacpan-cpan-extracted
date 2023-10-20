#!/usr/bin/env perl
# Detection of existing-but-empty, preamble.  Github issue #18

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message;

use Test::More;

#### with empty preamble

my $msg = Mail::Message->read(<<'END-OF-MESSAGE', strip_status_fields => 0);
Subject: empty preamble multipart test message
Content-Type: multipart/alternative;	boundary="_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_"
MIME-Version: 1.0


--_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_
Content-Type: text/plain; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

In this test message there should be two blank lines after the message header.
The first blank line separates the header from the body.
The second blank line is the first line of the message body, and in this
multipart body it's an empty preamble.  It should be preserved when the message
is processed.
        
--_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_
Content-Type: text/html; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

<html>
<head>
</head>
<body>
This is the text/html part.
</body>
</html>

--_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_--
END-OF-MESSAGE

ok defined $msg, 'message with empty preamble';

my $body = $msg->body;
ok $body->isMultipart, '... is multipart';

my $preamble = $body->preamble;
ok defined $preamble, '... has preamble';
isa_ok $preamble, 'Mail::Message::Body::Lines', '... ';
is $preamble->string, '', '... preamble is empty';
cmp_ok $preamble->nrLines, '==', 1, '... contains nothing';

### without preamble

my $msg2 = Mail::Message->read(<<'END-OF-MESSAGE', strip_status_fields => 0);
Subject: empty preamble multipart test message
Content-Type: multipart/alternative;	boundary="_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_"
MIME-Version: 1.0

--_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_
Content-Type: text/plain; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

Only a single blank line before parts: no preamble.

--_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_
Content-Type: text/html; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

<html />

--_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_--
END-OF-MESSAGE

ok defined $msg2, 'message without preamble';

my $body2 = $msg2->body;
ok $body2->isMultipart, '... is multipart';

my $preamble2 = $body2->preamble;
ok ! defined $preamble2, '... has no preamble';

done_testing;
