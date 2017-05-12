#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'xlist', 'listname');
is($list->listsoftware, 'ListSTAR v2.0', 'list software');
is($list->posting_address, 'xlist@example.com', 'posting address');

__DATA__
From xlist@example.com Tue Jan 01 03:33:29 2002
Received: (qmail 70792 invoked from network); 1 Jan 2002 11:33:29 -0000
Received: from unknown (216.115.97.167)
	by m3.grp.snv.yahoo.com with QMQP; 1 Jan 2002 11:33:29 -0000
Received: from unknown (HELO cipsafe.org) (144.232.51.58)
	by mta1.grp.snv.yahoo.com with SMTP; 1 Jan 2002 11:33:29 -0000
Received: from xlist.cipsafe.org (192.168.1.15) by cipsafe.org with SMTP
	(Eudora Internet Mail Server 3.0.3); Tue, 1 Jan 2002 05:16:30 -0600
Message-ID: <n1202260307.outx014292@example.com>
From: "XList" <xlist@example.com>
Subject: Monthly Help File
To: "XList" <xlist@example.com>
Precedence: Bulk
X-List-Software: ListSTAR v2.0 by StarNine Technologies, a Quarterdeck Company
Errors-To: "Mailing List Public Address" <xlist@example.com>
Sender: "Mailing List Public Address" <xlist@example.com>
List-Subscribe: <mailto:xlist@example.com?subject=subscribe>
List-Unsubscribe: <mailto:xlist@example.com?subject=unsubscribe>
List-Archive: <mailto:xlist@example.com?subject=digests>
List-Owner: <mailto:xlist-moderator@example.com>
List-Post: <mailto:xlist@example.com>
List-Help: <mailto:xlist@example.com?subject=help>
Date: Tue, 1 Jan 2002 05:16:26 -0600
 
at least some version 2 is easy to work out!
