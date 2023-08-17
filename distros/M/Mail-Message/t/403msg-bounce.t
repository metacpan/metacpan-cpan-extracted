#!/usr/bin/env perl
#
# Test the creation of bounce messages
#

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;
use Mail::Message::Head;
use Mail::Message::Body::Lines;
use Mail::Message::Construct::Bounce;

use Test::More tests => 2;
use IO::Scalar;


#
# First produce a message to reply to.
#

my $head = Mail::Message::Head->build
 ( To      => 'me@example.com (Me the receiver)'
 , From    => 'him@somewhere.else.nl (Original Sender)'
 , Cc      => 'the.rest@world.net'
 , Subject => 'Test of Bounce'
 , Date    => 'Wed, 9 Feb 2000 15:44:05 -0500'
 , 'Content-Something' => 'something'
 );

my $body = Mail::Message::Body::Lines->new
  ( mime_type => 'text/plain'
  , data      => <<'TEXT'
First line of orig message.
Another line of message.
TEXT
  );

my $msg  = Mail::Message->new(head => $head);
$msg->body($body);
ok(defined $msg);

#
# Create a bounce
#

my $bounce = $msg->bounce
 ( To         => 'new@receivers.world'
 , From       => 'I was between'
 , Received   => 'by me'
 , Date       => 'Fri, 7 Dec 2001 15:44:05 -0100'
 , 'Message-ID' => '<simple>'
 );

my $filedata;
my $file = IO::Scalar->new(\$filedata);
$bounce->print($file);

compare_message_prints($filedata, <<'EXPECTED', 'bounce print')
To: me@example.com (Me the receiver)
From: him@somewhere.else.nl (Original Sender)
Cc: the.rest@world.net
Subject: Test of Bounce
Date: Wed, 9 Feb 2000 15:44:05 -0500
Content-Something: something
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 8bit
Received: by me
Resent-Date: Fri, 7 Dec 2001 15:44:05 -0100
Resent-From: I was between
Resent-To: new@receivers.world
Resent-Message-ID: <simple>

First line of orig message.
Another line of message.
EXPECTED
