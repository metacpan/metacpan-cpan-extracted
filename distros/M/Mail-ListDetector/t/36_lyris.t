#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 8;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'rapa', 'listname');
is($list->listsoftware, 'Lyris 2.54', 'list software');
is($list->posting_address, 'rapa@maillist.example.com', 'posting address');

$mail->head->replace('List-Unsubscribe', '<mailto:unsubscribe-rapa@maillist.example.com>');

$list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'rapa', 'listname');
is($list->listsoftware, 'Lyris 2.54', 'list software');
is($list->posting_address, 'rapa@maillist.example.com', 'posting address');

__DATA__
Return-Path: <rapa-admin@maillist.example.com>
Received: from rly-zc05.mx.example.com (rly-zc05.mail.example.com [172.3.3.35]) by
	air-zc02.mail.example.com (v51.29) with SMTP; Fri, 20 Nov 1998 06:57:57 1900
Received: from webserver.example.com ([10.180.140.158])
	by rly-zc05.mx.example.com (8.8.8/8.8.5/AOL-4.0.0)
	with SMTP id GAA18883 for <otherone@example.com>;
	Fri, 20 Nov 1998 16:47:55 -0500 (EST)
Received: from 10.4.66.51 by maillist.example.com (Lyris SMTP service)
	20 Nov 98 16:45:43 EST5 from:<tfield@example.com> to:<rapa@maillist.example.com>
Received: from EXAMPLE-Message_Server by example.com
	with Novell_GroupWise; Fri, 20 Nov 1998 16:45:27 -0500
Message-Id: <946-289@maillist.example.com>
Date: Fri, 20 Nov 1998 16:44:41 -0500
From: "Some Person" <someone@example.com>
To: "RAPA. list" <rapa@maillist.example.com>
Subject: [rapa] 10 green bottles hanging on the wall
Content-Disposition: inline
X-Message-Id: <s51823f.09@example.com>
List-Unsubscribe: <mailto:unsubscribe-rapa@maillist.example.com?subject=[otherone@example.com]>
List-Software: Lyris Server version 2.54, <http://www.lyris.net>
List-Subscribe: <mailto:subscribe-rapa@maillist.example.com>
List-Owner: <mailto:owner-rapa@maillist.example.com>
List-Help: <mailto:help@maillist.example.com>
X-List-Host: Listserver for FPLC <http://maillist.example.com>
Reply-To: "RAPA. list" <rapa@maillist.example.com>
Sender: rapa-admin@maillist.example.com
Precedence: bulk
X-Lyris-To: [otherone@example.com]
X-Lyris-MemberID: 289
X-Lyris-MessageID: 946
Mime-Version: 1.0
Content-type: text/plain; charset=US-ASCII
Content-transfer-encoding: 7bit

Old school Lyris :)
