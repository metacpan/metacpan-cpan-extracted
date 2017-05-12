#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'experts@lists.example.com', 'listname');
is($list->listsoftware, 'LetterRip Pro 3.0.7', 'list software');
is($list->posting_address, 'experts@lists.example.com', 'posting address');

__DATA__
Received: by mail.example.net from localhost
    (router,SLMail V3.2); Mon, 09 Apr 2001 16:01:44 -0400
Received: by mail.example.net from lists.example.com
    (10.30.2.2::mail daemon; unverified,SLMail V3.2); Mon, 09 Apr 2001 16:01:42 -0400
Received: from example.net by lists.example.com with SMTP;
 Tue, 10 Apr 2001 06:59:10 +1100
Message-ID: <3AAAAD7.E99426@example.net>
Date: Mon, 09 Apr 2001 15:59:36 -0400
From: Hello Hello <hello@example.net>
X-Mailer: Mozilla 4.7 [en] (WinNT; U)
X-Accept-Language: en
MIME-Version: 1.0
To: "experts@lists.example.com" <experts@lists.example.com>
Subject: Example Question
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: 7bit
Reply-To: "Experts" <experts@lists.example.com>
Sender: <experts@lists.example.com>
Precedence: Bulk
List-Software: LetterRip Pro 3.0.7 by Fog City Software, Inc.
List-Subscribe: <mailto:experts-on@lists.example.com>
List-Digest: <mailto:experts-digest@lists.example.com>
List-Unsubscribe: <mailto:experts-off@lists.example.com>
X-SLUIDL: 9B5EE073-823989-Bhsdj0-C88F2CC


--
To unsubscribe: send an email to <experts-off@lists.example.com>
experts is hosted at Example Networks <http://www.example.com/>
