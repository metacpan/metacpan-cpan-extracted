#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'example@example.org', 'listname');
is($list->listsoftware, 'LetterRip 2.0', 'list software');
is($list->posting_address, 'example@example.org', 'posting address');

__DATA__
Received: by example.example.com with ADMIN;25 Jul 1997 12:41:05 U
Received: from example.net by example.org with SMTP; Fri, 25 Jul 97
 14:42:23 -0500
Message-Id: <1997072JLKDSJKGFJSAKltod-111.example.webtv.net>
From: example@webtv.net (bye bye)
Date: Fri, 25 Jul 1997 15:42:14 -0400
To: example@example.org (Example)
Subject: RE: Home example
Content-Type: TEXT/PLAIN; CHARSET=US-ASCII
Content-Transfer-Encoding: 7BIT
MIME-Version: 1.0 (WebTV)
Reply-To: Example <example@example.org>
Return-Path: <example@example.org>
Sender: <example@example.org>
Precedence: Bulk
List-Software: LetterRip 2.0 by Fog City Software, Inc.
List-Unsubscribe:
 <mailto:requests@example.org?subject=unsubscribe%20example>
List-Subscribe: <mailto:requests@example.org?subject=subscribe%20example

Another sample LetterRip message

