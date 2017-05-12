#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'snglist-aol', 'listname');
is($list->listsoftware, 'Lyris', 'list software');
is($list->posting_address, 'snglist-aol@snglist.msfc.nasa.gov', 'posting address');

__DATA__
Return-Path: <bounce-snglist-aol.example-999999@snglist.msfc.nasa.gov>
Received: from  rly-xi03.mx.aol.example.com (rly-xi03.mail.aol.example.com
  [172.20.116.8]) by air-xi03.mail.aol.example.com (v89.10) with ESMTP id
  MAILINXI31-1007181331; Mon, 07 Oct 2002 18:13:31 -0400
Received: from  lyris.msfc.nasa.gov (lyris.msfc.nasa.gov [192.77.84.74])
  by rly-xi03.mx.aol.example.com (v89.10) with ESMTP id
  MAILRELAYINXI37-1007181310; Mon, 07 Oct 2002 18:13:10 2000
X-Mailer: Lyris Web Interface
Date: Mon, 7 Oct 2002 16:12:04 -0500
Subject: Hubble spots the biggest world since Pluto
To: "NASA Science News" <snglist-aol@snglist.msfc.nasa.gov>
From: NASA Science News <snglist@snglist.msfc.nasa.gov>
List-Unsubscribe: <mailto:leave-snglist-aol-999999K@snglist.msfc.nasa.gov>
List-Subscribe: <mailto:subscribe-snglist-aol@snglist.msfc.nasa.gov>
List-Owner: <mailto:owner-snglist-aol@snglist.msfc.nasa.gov>
X-URL: <http://science.nasa.gov>
X-List-Host: Science@NASA Web Server <http://science.nasa.gov>
Reply-To: "NASA Science News" <snglist-aol.example@snglist.msfc.nasa.gov>
Sender: bounce-snglist-aol.example-999999@snglist.msfc.nasa.gov
Message-Id: <LISTMANAGER-999999-583404-2002.10.07-16.18.23--cbgb#aol.example.com@snglist.msfc.nasa.gov>
Content-Type: text/plain; charset="US-ASCII"
Content-Transfer-Encoding: 7bit

NASA Science News for October 7, 2002

Astronomers using the Hubble Space Telescope have measured a distant world
more than half the size of Pluto. It's the biggest object found in our
solar system since the discovery of Pluto itself 72 years ago.

FULL STORY at

<a href="http://science.nasa.gov/headlines/y2002/07oct_newworld.htm?aol999999">Hubble spots the biggest world since Pluto -
http://science.nasa.gov/headlines/y2002/07oct_newworld.htm </a>

---
You are currently subscribed to snglist-aol as: cbgb@aol.example.com

This is a free service.

To UNSUBSCRIBE, or CHANGE your address on this service, go to <a href="http://science.nasa.gov/news/subscribe.asp?e=cbgb@aol.example.com">our subscription web page</a>
or send a blank email to leave-snglist-aol-999999K@snglist.msfc.nasa.gov.

