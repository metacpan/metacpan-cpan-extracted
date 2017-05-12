#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
use Mail::Internet;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(!defined($list), "list not defined");

__DATA__
From root@home.etla.org Sat Jan 20 13:37:58 2001
Envelope-to: usenet@home.etla.org
Received: from root by pool.home.etla.org with local (Exim 3.12 #1 (Debian))
	id 14JyDO-00006n-00
	for <usenet@home.etla.org>; Sat, 20 Jan 2001 13:37:58 +0000
To: usenet@home.etla.org
Subject: innwatch warning: messages in /var/log/news/news.crit
Message-Id: <E14JyDO-00006n-00@pool.home.etla.org>
From: root <root@home.etla.org>
Date: Sat, 20 Jan 2001 13:37:58 +0000
Status: RO
Content-Length: 1824
Lines: 34

-rw-r--r--    1 root     news         1550 Jan 19 21:51 /var/log/news/news.crit
-----
Server running
Allowing remote connections
Parameters c 14 i 50 (0) l 1000000 o 1011 t 300 H 2 T 60 X 0 normal specified
Not reserved
Readers separate enabled
Perl filtering enabled
-----
Nov  7 23:37:27 pool innd: SERVER shutdown received signal 15
Nov  7 23:40:13 pool innd: SERVER shutdown received signal 15
Nov  8 00:02:11 pool innd: SERVER shutdown received signal 15
Nov  8 01:07:00 pool innd: SERVER shutdown received signal 15
Nov  9 23:37:20 pool innd: SERVER shutdown received signal 15
Nov 10 23:37:26 pool innd: SERVER shutdown received signal 15
Nov 12 01:35:44 pool innd: SERVER shutdown received signal 15
Nov 12 19:24:33 pool innd: SERVER shutdown received signal 15
Nov 12 23:33:52 pool innd: SERVER shutdown received signal 15
Nov 13 23:05:11 pool innd: SERVER shutdown received signal 15
Nov 14 22:09:04 pool innd: SERVER shutdown received signal 15
Nov 15 22:52:53 pool innd: SERVER shutdown received signal 15
Nov 18 14:31:53 pool innd: SERVER shutdown received signal 15
Nov 23 07:44:13 pool innd: SERVER shutdown received signal 15
Nov 24 08:11:38 pool innd: SERVER shutdown received signal 15
Nov 29 23:42:48 pool innd: SERVER shutdown received signal 15
Dec 17 18:07:43 pool innd: SERVER shutdown received signal 15
Dec 17 22:47:32 pool innd: SERVER shutdown received signal 15
Dec 23 15:50:30 pool innd: SERVER shutdown received signal 15
Jan 14 12:41:56 pool innd: SERVER shutdown received signal 15
Jan 14 12:45:33 pool innd: SERVER shutdown received signal 15
Jan 15 01:09:26 pool innd: SERVER shutdown received signal 15
Jan 17 23:42:55 pool innd: SERVER shutdown received signal 15
Jan 18 22:35:34 pool innd: SERVER shutdown received signal 15
Jan 19 21:51:19 pool innd: SERVER shutdown received signal 15

