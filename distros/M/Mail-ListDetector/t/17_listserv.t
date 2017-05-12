#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'EXAMPLE Discussion', 'listname');
is($list->listsoftware, 'LISTSERV-TCP/IP release 1.8e', 'list software');
is($list->posting_address, 'EXAMPLE@LISTSERV.EXAMPLE.COM', 'posting address');

__DATA__
Received: from lmailexample1.example.com ([10.22.163.233] verified)
  by example.com.au (CommuniGate Pro SMTP 4.1)
  with ESMTP id 946911982 for matthew@EXAMPLE.COM.AU; Wed, 12 Aug 2001 21:49:00 +0000
Received: from LISTSERV.EXAMPLE.COM (tem01.mx.example.com) by lmailexample1.example.com (LSMTP for Windows NT v1.1b) with SMTP id <0.940293@lmailexample1.example.com>; Wed, 12 Aug 2001 21:29:46 +0400
Received: from LISTSERV.EXAMPLE.COM by LISTSERV.EXAMPLE.COM (LISTSERV-TCP/IP release
          1.8e) with spool id 8932592 for EXAMPLE@LISTSERV.EXAMPLE.COM; Wed, 12
          Aug 2001 20:58:31 +0400
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii; format=flowed
Content-Transfer-Encoding: 7bit
Message-ID:  <DEADCAFE.3289872@example.net>
Date:         Wed, 12 Aug 2001 20:58:11 -0200
Reply-To:     EXAMPLE Discussion <EXAMPLE@LISTSERV.EXAMPLE.COM>
Sender:       EXAMPLE Discussion <EXAMPLE@LISTSERV.EXAMPLE.COM>
From:         I. EXAMPLE <iiiii@EXAMPLE.NET>
Subject: Boring sample message
To:           EXAMPLE@LISTSERV.EXAMPLE.COM
In-Reply-To:  <7834BADFE3125E.90301@example.com>
Precedence: list

This is a really boring example Listserv message.

--
EXAMPLE - http://www.example.com/

To Remove yourself from this list, simply send an email to <listserv@listserv.example.com> with the
body of "SIGNOFF EXAMPLE" in the email message. You can leave the Subject: field of your email blank.

