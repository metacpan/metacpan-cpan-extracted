#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'CGnet', 'listname');
is($list->listsoftware, 'CommuniGate List 1.4', 'list software');
is($list->posting_address, 'CGnet@total.example.com', 'posting address');

__DATA__
From adm-bounce@oasys.net Mon Jun  4 06:41:14 2001
Received: from [10.80.0.8] by mail.example.com
	(SMTPD32-3.04) id A3CCCC1700AC; Mon, 02 Feb 1998 20:25:33 -0700
Received: from total.example.com (du-226.example.com [10.80.0.226])
	by poseidon.example.com (8.8.6/8.8) with SMTP id QBB30808; Mon, 2 Feb 1998 04:08:00 GMT
Subject: CommuniGate List example
Message-Id: <00000038942968439085@total.example.com>
To: subscribers:;
X-ListServer: CommuniGate List 1.4
From: test@example.com (Test Account)
Sender: CGnet@total.example.com (CGnet)
Date: Mon, 02 Feb 1998 13:57:22 +1000
Organization: Example Limited
X-Mailer: CommuniGate 2.9.8
Errors-To: Greene@total.example.com
Reply-To: CGnet@total.example.com
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="__==========0000000003894==total.example.com==__"
 

This is a MIME-encapsulated message
 If you read this, you may want to switch to a better mailer
--__==========0000000003894==total.example.com==__
Content-Type: text/plain; charset=ISO-8859-1
Content-Transfer-Encoding: 8bit
 

List content goes here.

--__==========0000000003894==total.example.com==__
Content-Type: text/plain; charset=ISO-8859-1
Content-Transfer-Encoding: 8bit


++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
You have received this message because you are subscribed to
CGnet.

To unsubscribe, send any message to: CGnet-off@total.example.com
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--__==========0000000003894==total.example.com==__--

