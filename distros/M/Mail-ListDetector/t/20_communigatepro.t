#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'black-example.lists.example.com', 'listname');
is($list->listsoftware, 'CommuniGate Pro LIST 4.1.3', 'list software');
is($list->posting_address, 'black-example@lists.example.com', 'posting address');

__DATA__
From: Bowdler <ise@example.com>
Date: Thu Oct 2, 2003  5:07:13  AM Asia/Jakarta
To: "Black-Mac" <black-example@lists.example.com>
Subject: [BTM] T610 vs T616
Reply-To: "Black-Mac" <black-example@lists.example.com>
Return-Path: <black-example-report@lists.example.com>
Delivered-To: bowd-ler@example.com
Received: (qmail 2001 invoked from network); 1 Oct 2003 22:08:23 -0000
Received: from unknown (HELO beach.example.net) (10.66.173.12) by 0 with SMTP; 1 Oct 2003 22:08:23 -0000
Received: (qmail 14994 invoked from network); 1 Oct 2003 22:22:42 -0000
Received: from mail.example.com (10.35.9.48) by 10.39.73.2 with SMTP; 1 Oct 2003 22:22:42 -0000
X-Listserver: CommuniGate Pro LIST 4.1.3
List-Unsubscribe: <mailto:black-example-off@lists.example.com>
List-Id: <black-example.lists.example.com>
List-Archive: <http://lists.example.com:80/Lists/black-example/List.html>
Message-Id: <list-8603715@mail.example.com>
Sender: "Black-Mac" <black-example@lists.example.com>
Precedence: list
X-Original-Message-Id: <BBA0C786.3972%jffdcksn@example.com>
Mime-Version: 1.0
Content-Type: text/plain; charset=US-ASCII
X-Spam-Checker-Version: SpamAssassin 2.60 (1.212-2003-09-23-exp)
X-Spam-Report:
X-Spam-Status: No, hits=0.0 required=0.6 tests=none autolearn=no version=2.60
X-Spam-Level:

lfdslkf;a
