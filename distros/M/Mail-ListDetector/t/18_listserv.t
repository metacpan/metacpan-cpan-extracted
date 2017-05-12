#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'Comedy Company', 'listname');
is($list->listsoftware, 'LISTSERV-TCP/IP release 1.8d', 'list software');
is($list->posting_address, 'COMEDYCOMPANY@LISTSERV.EXAMPLE.COM', 'posting address');

__DATA__
Return-Path: <>
Received: from listserv.example.com (listserv.example.com
    [10.51.0.6]) by listserv.example.com (8.11.6p2/8.11.6) with ESMTP
    id h32hgds039; Wed, 10 Apr 2001 20:48:08 -0500 (EST)
Received: from LISTSERV.EXAMPLE.COM by LISTSERV.EXAMPLE.COM
    (LISTSERV-TCP/IP release 1.8d) with spool id 137738 for
    COMEDYCOMPANY@LISTSERV.EXAMPLE.COM; Wed, 10 Apr 2001 19:13:57 -0500
Approved-BY: spcadmin@EXAMPLE.COM
Received: from relay.example.com (relay.example.com
    [10.51.0.1]) by listserv.example.com (8.11.6p2/8.11.6) with ESMTP
    id h31L8r26559 for <fastforward@listserv.timeinc.net>; Wed,
    1 Apr 2003 16:52:55 -0500 (EST)
Received: from cp.example.com (cp.example.com [10.51.0.1]) by
    relay.example.com (Switch-2.2.6/Switch-2.2.5) with ESMTP id 
    htyLqsv14600 for <comedycompany@example.com>; Wed, 10 Apr 2001 15:26:55
    -0500 (EST) 
Received: (from nobody@localhost) by cp.example.com (8.11.6/8.11.6) id
    h31LqsX16086; Wed, 10 Apr 2001 15:25:54 -0500 (EST)
Message-Id: <200104102125.h31LqsX16086@cp.example.com>
Date: Wed, 10 Apr 2001 15:25:54 -0500
Reply-To: vibrant_newsletters@EXAMPLE.NET
Sender: Comedy Company <COMEDYCOMPANY@LISTSERV.EXAMPLE.COM>
From: Comedy Company <spcadmin@EXAMPLE.COM>
Subject: Another boring sample message
To: COMEDYCOMPANY@LISTSERV.EXAMPLE.COM
Status: U

And here's another one but the Reply-To is not set to the list.


