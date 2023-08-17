#!/usr/bin/env perl
#
# Test the creation of forwarded messages
#

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;
use Mail::Message::Head;
use Mail::Message::Body::Lines;
use Mail::Message::Construct::Forward;

use Test::More tests => 25;
use Mail::Address;

#
# First produce a message to forward to.
#

my $head = Mail::Message::Head->build
 ( To   => 'me@example.com (Me the receiver)'
 , From => 'him@somewhere.else.nl (Original Sender)'
 , Cc   => 'the.rest@world.net'
 , Subject => 'Test of forward'
 , Date => 'Wed, 9 Feb 2000 15:44:05 -0500'
 , 'Content-Something' => 'something'
 );

my ($text, $sig) = (<<'TEXT', <<'SIG');
First line of orig message.
Another line of message.
TEXT
--
And this is the signature
which
has
a
few lines
too
SIG

my @lines = split /^/, $text.$sig;
my $body = Mail::Message::Body::Lines->new
  ( mime_type => 'text/plain'
  , data      => \@lines
  );

ok(defined $body);

my $msg  = Mail::Message->new(head => $head);
$msg->body($body);

ok(defined $msg);

#
# Create a simple forward
#

my $forward = $msg->forward
  ( strip_signature => undef
  , prelude         => undef
  , postlude        => undef
  , quote           => undef
  , To              => 'dest@example.com (New someone)'
  );

ok(defined $forward,                     'created simple forward');
isa_ok($forward, 'Mail::Message');
my @f = $forward->body->string;
my @g = $msg->body->string;
is(@f, @g);
#$forward->print(\*STDERR);

#
# Create a real forward, which defaults to INLINE
#

my $dest = 'dest@test.org (Destination)';
$forward = $msg->forward
  ( quote    => '] '
  , To       => $dest
  );

ok($forward->body!=$msg->body);
is(  $forward->head->get('to'), $dest);
is($forward->head->get('from'), $msg->head->get('to'));
ok(! defined $forward->head->get('cc'));

#$forward->print;
is($forward->body->string, <<'EXPECT');
---- BEGIN forwarded message
From: him@somewhere.else.nl (Original Sender)
To: me@example.com (Me the receiver)
Cc: the.rest@world.net
Date: Wed, 9 Feb 2000 15:44:05 -0500

] First line of orig message.
] Another line of message.
---- END forwarded message
EXPECT

#
# Complicated forward
#

my $postlude = Mail::Message::Body::Lines->new
  ( data => [ "added to the end\n", "two lines\n" ]
  );

$forward = $msg->forward
  ( group_forward => 0
  , quote       => sub {chomp; "> ".reverse."\n"}
  , prelude     => "From me!\n"
  , postlude    => $postlude
  , Cc          => 'xyz'
  , Bcc         => Mail::Address->new('username', 'user@example.com')
  , To          => $dest
  );

is(  $forward->head->get('to'), $dest);
is($forward->head->get('from'), $msg->head->get('to'));
is($forward->head->get('cc'), 'xyz');
ok(!defined $forward->head->get('skip'));
is($forward->head->get('bcc'), 'username <user@example.com>');

#$forward->print;
is($forward->body->string, <<'EXPECT');
From me!
> .egassem giro fo enil tsriF
> .egassem fo enil rehtonA
added to the end
two lines
EXPECT

#
# Try forwardAttach
#

$msg = Mail::Message->build(To => 'you',
   'X-Loop' => 'yes', data => "greetings!\n");
my $preamble = Mail::Message::Body->new(data => "just checking\n");
my $fwd = $msg->forwardAttach(preamble => $preamble, To => 'us');

ok(defined $fwd,                        "create forwardAttach");
isa_ok($fwd, 'Mail::Message');
is(reproducable_text($fwd->string."\n"), <<ATTACH);
From: you
To: us
Subject: Forwarded
References: <removed>
Content-Type: multipart/mixed; boundary="boundary-<removed>"
Message-Id: <removed>
Date: <removed>
MIME-Version: 1.0

--boundary-<removed>
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 8bit

just checking

--boundary-<removed>
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 8bit

greetings!

--boundary-<removed>--
ATTACH

#
# Try forwardEncapsulate
#

my $fwd2 = $msg->forwardEncapsulate(preamble => $preamble, To => 'us');
ok(defined $fwd2,                        "create forwardEncapsulate");
is(reproducable_text($fwd2->string."\n"), <<ENCAPS);
From: you
To: us
Subject: Forwarded
References: <removed>
Content-Type: multipart/mixed; boundary="boundary-<removed>"
Message-Id: <removed>
Date: <removed>
MIME-Version: 1.0

--boundary-<removed>
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 8bit

just checking

--boundary-<removed>
Content-Type: message/rfc822

To: you
X-Loop: yes
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 8bit
Message-Id: <removed>
Date: <removed>
MIME-Version: 1.0

greetings!

--boundary-<removed>--
ENCAPS

#
# Try complex attach
#

my $one = Mail::Message::Body->new(data => "this is the first\n");
my $two = Mail::Message::Body->new(data => "this is the second\n",
   mime_type => 'application/pgp-signature');
my $multi = Mail::Message::Body::Multipart->new(parts => [ $one, $two ]);
$msg    = Mail::Message->buildFromBody($multi, To => 'you');
ok(defined $msg,                    'created complex multipart');
my $fwd3 = $msg->forwardAttach(preamble => $preamble, To => 'us');

is(reproducable_text($fwd3->string."\n"), <<ATTACH);
From: you
To: us
Subject: Forwarded
References: <removed>
Content-Type: multipart/mixed; boundary="boundary-<removed>"
Message-Id: <removed>
Date: <removed>
MIME-Version: 1.0

--boundary-<removed>
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 8bit

just checking

--boundary-<removed>
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 8bit

this is the first

--boundary-<removed>--
ATTACH

#
# Binary message used with inline, which becomes an attach
#

$body = Mail::Message::Body->new
 ( mime_type => 'application/octet-stream'
 , data => [ "line 1\n", "line2\n" ] 
 );
ok($body->isBinary);

$msg     = Mail::Message->buildFromBody($body, To => 'you');
#$msg->print(\*STDERR);

my $fwd4 = $msg->forwardInline
 ( prelude  => "Prelude\n"
 , postlude => "Postlude\n"
#, is_attached => "My own text\n"
 , To       => 'everyone'
 );

#$fwd4->print(\*STDERR);
is(reproducable_text($fwd4->string."\n"), <<'EXPECTED');
From: you
To: everyone
Subject: Forwarded
References: <removed>
Content-Type: multipart/mixed; boundary="boundary-<removed>"
Message-Id: <removed>
Date: <removed>
MIME-Version: 1.0

--boundary-<removed>
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 8bit

Prelude
[The forwarded message is attached]
Postlude

--boundary-<removed>
Content-Type: application/octet-stream
Content-Transfer-Encoding: base64

bGluZSAxCmxpbmUyCg==

--boundary-<removed>--
EXPECTED
