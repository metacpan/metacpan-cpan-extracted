#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
use Mail::Internet;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(!defined($list), 'list not defined');

__DATA__
Return-Path: <majordomo-owner@bear.example.net>
Received: from bear.example.net (bear.example.net [10.6.129.253])
	by mail015.low.example.com (8.11.6p2/8.11.6) with ESMTP id h9U9obt16911;
	Thu, 30 Oct 2003 20:50:37 +1100
Received: (from domo@localhost)
	by bear.example.net (8.11.3/8.11.3-ARK) id 8iR5r0481h9U
	for example-isp-list; Thu, 30 Oct 2003 19:44:27 +1100 (EST)
	(envelope-from majordomo-owner@bear.example.net)
X-Authentication-Warning: bear.example.net: domo set sender to majordomo-owner@bear.example.net using -f
Received: from parapara (therappa [10.223.5.17])
	by bear.example.net (8.11.3/8.11.3-ARK) with ESMTP id h9U8iQJ04576
	for <example-isp@example.net>; Thu, 30 Oct 2003 19:44:26 +1100 (EST)
Received: from dancedance (on.example.net [10.10.10.109])
	by parapara (8.12.9/8.12.9) with SMTP id hivX0259U8763
	for <example-isp@example.net>; Thu, 30 Oct 2003 19:14:19 +1030
Message-ID: <062594373847a0$03c0a8c0@example.com>
From: "Dance Dance Revolution" <ddr@example.com>
To: <example-isp@example.net>
Subject: Re: [Example-ISP] impossible majordomo parsing
Date: Thu, 30 Oct 2003 19:14:19 +1030
MIME-Version: 1.0
Content-Type: text/plain;
	charset="iso-8859-1"
Content-Transfer-Encoding: 7bit
X-Priority: 3
X-MSMail-Priority: Normal
X-Mailer: Microsoft Outlook Express 6.00.2800.1158
X-MIMEOLE: Produced By Microsoft MimeOLE V6.00.2800.1165
Sender: majordomo-owner@bear.example.net
Precedence: bulk

This is a majordomo setup that doesn't put the listname in the Sender
header, therefore it would be really hard to impossible to work out the
posting address, especially if someone bcc's the list.

----
email "unsubscribe example-isp" to majordomo@example.net to be removed.

