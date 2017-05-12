#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'fwtk-users', 'listname');
is($list->listsoftware, 'Lyris', 'list software');
is($list->posting_address, 'fwtk-users@listserv.example.com', 'posting address');

__DATA__
Received: from sentry.gw.example.com (firewall-user@sentry.gw.example.com [10.9.9.9])
        by lists.example.com (8.9.1/8.9.1) with ESMTP id QAA07766
        Wed, 26 Feb 2003 16:33:40 -0500 (EST)
Received: by sentry.gw.example.com; id QAA01069; Wed, 26 Feb 2003 16:38:04 -0500 (EST)
Received: from listserv.example.com(10.27.2.6) by sentry.gw.example.com via smap (V5.5)
        id xma001048; Wed, 26 Feb 03 16:37:09 -0500
Message-ID: <LYRIS-303-134410-2003.02.26-15.15.57--fwtk-archive#lists.example.com@listserv.example.com>
From: "User" <user@example.com>
To: "fwtk-users" <fwtk-users@listserv.example.com>
Subject: [fwtk-users] Does anyone have a Lytris sample ?
Date: Wed, 26 Feb 2003 13:35:26 -0800
MIME-Version: 1.0
X-Mailer: Internet Mail Service (5.52.2560.1)
List-Unsubscribe: <mailto:leave-fwtk-users-303A@listserv.example.com>
Reply-To: "fwtk-users" <fwtk-users@listserv.example.com>
Content-Type: text/plain
Content-Length: 548

Lyris

---
You are currently subscribed to fwtk-users as: fwtk-archive@lists.example.com
To unsubscribe send a blank email to leave-fwtk-users-303A@listserv.example.com

