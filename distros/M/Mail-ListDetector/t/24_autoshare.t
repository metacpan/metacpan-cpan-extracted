#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'non', 'listname');
is($list->listsoftware, 'AutoShare 2.1', 'list software');
is($list->posting_address, 'non@example.com', 'posting address');

__DATA__
Return-Path: <listmaster@example.com>
Received: from  rly-zb03.mx.example.com (rly-zb03.mail.example.com [172.31.41.3]) by
        air-zb04.mail.example.com (v40.16) with SMTP; Sun, 29 Mar 1998 11:38:18
        -0500
Received: from example.com (example.com [172.76.185.51])
          by rly-zb03.mx.example.com (8.8.5/8.8.5/AOL-4.0.0)
          with ESMTP id LCC83502 for <user@example.com>;
          Sun, 29 Mar 1998 11:32:14 -0500 (EST)
Received: from mgate.example.com (10.3.63.100) by example.com with
 ESMTP (Eudora Internet Mail Server 1.1.2); Sun, 29 Mar 1998 08:32:24 +0000
Received: from [192.168.185.50] (imagic.example.com [192.168.185.50])
        by mgate.nwnexus.com (8.8.8/8.8.8) with ESMTP id IFF09949
        for <non@example.com>; Sun, 29 Mar 1998 08:30:39 -0800
X-Sender: user@mail.example.com
Date: Sun, 29 Mar 1998 08:29:56 -0800 
Reply-To: news@example.com
Errors-To: listmaster@example.com (Example Center Listmaster)
X-Sender: user@example.com
Precedence: bulk
List-Subscribe: <mailto:autoshare@example.com?body=subscribe%20non>
List-Unsubscribe: <mailto:autoshare@example.com?body=unsubscribe%20non>
X-List-Digest: <mailto:autoshare@example.com?body=set%20non%20digest>
List-Archive: <mailto:autoshare@example.com?body=index%20non>
List-Post: <mailto:non@example.com>
List-Owner: news@example.com (Example Online news)
List-Help: http://www.example.com/news
List-Software: AutoShare 2.1 by Mikael Hansen
X-To-Unsubscribe: autoshare@example.com, body: unsub non
To: non@example.com (Subscribers of non)
From: news@example.com
Subject: News through Example
Message-Id: <892558743954370908778@example.com>
Mime-Version: 1.0
Content-type: text/plain; charset=US-ASCII
Content-transfer-encoding: 7bit

Example Online News

