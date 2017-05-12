#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'doewatch', 'listname');
is($list->listsoftware, 'ONElist', 'list software');
is($list->posting_address, 'doewatch@onelist.com', 'posting address');

__DATA__
Received: from pop5.onelist.com (HELO onelist.com) (209.207.164.53)
  by mta133.mail.yahoo.com with SMTP; 30 Dec 1999 02:43:49 -0000
Received: (qmail 26572 invoked by alias); 30 Dec 1999 02:39:41 -0000
Received: (qmail 23938 invoked from network); 30 Dec 1999 02:38:00 -0000
Received: from unknown (209.207.164.239) by pop5.onelist.com with QMQP; 30 Dec 1999 02:38:00 -0000
Received: from unknown (HELO imo-d06.mx.example.com) (10.18.17.8) by 209.207.164.239 with SMTP; 30 Dec 1999 02:38:05 -0000
Received: from XXXX@example.com by imo-d06.mx.example.com (mail_out_v24.6.) id h.0.c414a638 (1813) for <doewatch@onelist.com>; Wed, 29 Dec 1999 21:38:04 -0500 (EST)
From: XXXX@example.com
Message-ID: <0.c414a638.259c1f8b@example.com>
Date: Wed, 29 Dec 1999 21:38:03 EST
To: doewatch@onelist.com
MIME-Version: 1.0
X-Mailer: AOL 3.0 for Windows 95 sub 52
Mailing-List: list doewatch@onelist.com; contact doewatch-owner@onelist.com
Delivered-To: mailing list doewatch@onelist.com
Precedence: bulk
List-Unsubscribe: <mailto:doewatch-unsubscribe@ONElist.com>
Subject: [DOEWatch] TV Programming announcement--Premiere of "Declassified: Human Experimentation" 
Content-Type: multipart/mixed; boundary="onelist.6253.13394"
Content-Length: 2284

onelist has since been eaten by egroups which then morphed ? to  yahoo groups
and they call it ONElist

