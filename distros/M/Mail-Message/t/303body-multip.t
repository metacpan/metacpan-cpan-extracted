#!/usr/bin/env perl
#
# Test processing of multipart message bodies.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body::Lines;
use Mail::Message::Body::Multipart;
use Mail::Message::Head::Complete;

use Test::More tests => 34;
use IO::Scalar;

my $body = Mail::Message::Body::Multipart->new
 ( transfer_encoding => '8bit'
 , boundary          => 'xyz'
 );

is($body->boundary, 'xyz');
$body->boundary('part-separator');
is($body->boundary, 'part-separator');
is($body->mimeType, 'multipart/mixed', 'is multipart mixed');

my $h1 = Mail::Message::Head::Complete->new;

my $b1 = Mail::Message::Body::Lines->new
 ( data              => ["p1 l1\n", "p1 l2\n" ]
 , checked           => 1
 , mime_type         => 'text/html'
 , transfer_encoding => '8bit'
 );

ok($b1, 'body 1');
is($b1->mimeType, 'text/html');
is($b1->transferEncoding, '8bit');
is($b1->disposition, 'none');

my $p1 = Mail::Message->new(head => $h1);
is($b1->charset, 'PERL');
my $b1b = $p1->body($b1);
is($b1b->charset, 'utf-8');
#$p1->print;

is($p1->get('Content-Transfer-Encoding'), '8bit');
ok(! defined $p1->get('Content-Disposition'));

my $h2 = Mail::Message::Head::Complete->new;

my $b2 = Mail::Message::Body::Lines->new
 ( data              => ["p2 l1\n", "p2 l2\n", "p2 l3\n", "p2 l4\n" ]
 , mime_type         => 'text/plain'
 , checked           => 1
 , transfer_encoding => '8bit'
 );

ok($b2, 'body 2');

my $p2 = Mail::Message->new(head => $h2);
is($b2->charset, 'PERL');
my $b2b = $p2->body($b2);
is($b2b->charset, 'utf-8');

# Empty multipart

my $fakeout;
my $g = IO::Scalar->new(\$fakeout);
cmp_ok($body->parts, "==", 0);
$body->print($g);
is($fakeout, "--part-separator--");

# First attachment

$fakeout = '';

my $newbody = $body->attach($p1);
ok($newbody != $body);
cmp_ok($newbody->parts, "==", 1);
$newbody->print($g);

compare_message_prints($fakeout."\n", <<'EXPECTED', 'print with attachment');
--part-separator
Content-Type: text/html; charset="utf-8"
Content-Transfer-Encoding: 8bit

p1 l1
p1 l2

--part-separator--
EXPECTED

# Second attachment

my $newerbody = $newbody->attach($p2);
ok($newerbody != $newbody);
cmp_ok($newerbody->parts, "==", 2);

$fakeout = '';
$newerbody->print($g);
compare_message_prints($fakeout."\n", <<'EXPECTED', 'print with two attachments');
--part-separator
Content-Type: text/html; charset="utf-8"
Content-Transfer-Encoding: 8bit

p1 l1
p1 l2

--part-separator
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit

p2 l1
p2 l2
p2 l3
p2 l4

--part-separator--
EXPECTED

# Add preamble and epilogue

my $newestbody
   = ref($newerbody)->new
      ( based_on => $newerbody
      , preamble => Mail::Message::Body::Lines->new
         ( data => [ "preamb1\n", "preamb2\n" ]
         , mime_type        => 'text/html'
         , charset          => 'us-ascii'
         , tranfer_encoding => '8bit'
         )
      , epilogue => Mail::Message::Body::Lines
                ->new(data => [ "epilogue\n" ])
      );
ok($newestbody != $newbody);

$fakeout = '';
$newestbody->print($g);
compare_message_prints($fakeout, <<'EXPECTED', 'with preamble and epilogue');
preamb1
preamb2

--part-separator
Content-Type: text/html; charset="utf-8"
Content-Transfer-Encoding: 8bit

p1 l1
p1 l2

--part-separator
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit

p2 l1
p2 l2
p2 l3
p2 l4

--part-separator--
epilogue
EXPECTED


# Body to message.  The info on preamble is used to create a whole message
# header.

my $message = Mail::Message->buildFromBody($newestbody,
    From => 'me', To => 'you', Date => 'now', 'Message-Id' => '<simple>');

$fakeout = '';
$message->print($g);
compare_message_prints($fakeout, <<'EXPECTED', 'build from multipart body');
From: me
To: you
Date: now
Message-Id: <simple>
Content-Type: multipart/mixed; boundary="part-separator"
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0

preamb1
preamb2

--part-separator
Content-Type: text/html; charset="utf-8"
Content-Transfer-Encoding: 8bit

p1 l1
p1 l2

--part-separator
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit

p2 l1
p2 l2
p2 l3
p2 l4

--part-separator--
epilogue
EXPECTED

### since 2.106: check partnumbers
my $pn = $message->partNumber;
defined $pn or $pn = 'undef';
is($pn, 'undef', 'partnr of top is undef');
is($message->body->part(0)->partNumber, '1', 'partNumber 1');
is($message->body->part(1)->partNumber, '2', 'partNumber 2');
is($message->body->part(0)->body->dispositionFilename('non-existent'), 'non-existent/part.html');

my $m1 = Mail::Message->buildFromBody($body, From => 'me', To => 'you',
   Date => 'now', 'Message-Id' => '<simple>');

$fakeout = '';
$m1->print($g);
compare_message_prints($fakeout."\n", <<'EXPECTED', 'build from multipart body');
From: me
To: you
Date: now
Message-Id: <simple>
Content-Type: multipart/mixed; boundary="part-separator"
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0

--part-separator--
EXPECTED

my $m2 = Mail::Message->buildFromBody($b1, From => 'me', To => 'you',
   Date => 'now', 'Message-Id' => '<simple>');

$fakeout = '';
$m2->print($g);
compare_message_prints($fakeout, <<'EXPECTED', 'build from multipart body');
From: me
To: you
Date: now
Message-Id: <simple>
Content-Type: text/html; charset="utf-8"
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0

p1 l1
p1 l2
EXPECTED

#
# Check copying.
#

my $m3 = $message->clone;
ok($m3);
ok($m3 != $message);
cmp_ok($m3->parts , "==",  $message->parts);
