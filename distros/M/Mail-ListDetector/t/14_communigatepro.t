#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'Mail-ListDetector.gunzel.org', 'listname');
is($list->listsoftware, 'CommuniGate Pro LIST 4.0.6', 'list software');
is($list->posting_address, 'Mail-ListDetector@gunzel.org', 'posting address');

__DATA__
Return-Path: <Mail-ListDetector-report@gunzel.org>
Received: from <mld@walker.wattle.id.au>
  by freeonline.com.au (CommuniGate Pro RULES 4.0.6)
  with RULES id 360012; Fri, 14 Mar 2003 01:00:12 +0000
X-ListServer: CommuniGate Pro LIST 4.0.6
List-Unsubscribe: <mailto:Mail-ListDetector-off@gunzel.org>
List-ID: <Mail-ListDetector.gunzel.org>
Message-ID: <list-360011@freeonline.com.au>
Reply-To: <Mail-ListDetector@gunzel.org>
Sender: <Mail-ListDetector@gunzel.org>
To: <Mail-ListDetector@gunzel.org>
Precedence: list
X-Original-Message-Id: <a05200e2dba96da10d185@[192.168.14.36]>
Date: Fri, 14 Mar 2003 12:00:05 +1100
From: Matthew Walker <mld@walker.wattle.id.au>
Subject: Hello to the Mail-ListDetector Mailing List at gunzel.org
MIME-Version: 1.0
Content-Type: text/plain; charset="us-ascii" ; format="flowed"

<x-flowed>This is a sample message for use in automated testing.

Regards

Matthew

#############################################################
This message is sent to you because you are subscribed to
  the mailing list <Mail-ListDetector@gunzel.org>.
To unsubscribe, E-mail to: <Mail-ListDetector-off@gunzel.org>
To switch to the DIGEST mode, E-mail to <Mail-ListDetector-digest@gunzel.org>
To switch to the INDEX mode, E-mail to <Mail-ListDetector-index@gunzel.org>
Send administrative queries to  <Mail-ListDetector-request@gunzel.org>


</x-flowed>

