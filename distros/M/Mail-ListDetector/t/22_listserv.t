#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'SOAP', 'listname');
is($list->listsoftware, 'LISTSERV-TCP/IP release 1.8d', 'list software');
is($list->posting_address, 'SOAP@DISCUSS.DEVELOP.COM', 'posting address');

__DATA__
From owner-soap@DISCUSS.DEVELOP.COM Wed Nov 28 14:18:07 2001
Received: from [63.111.243.6] (helo=la-infoserver.develop.com) by ns0 with
    smtp (Exim 3.33 #1) id 16958E-0002Uy-00 for acme@astray.com;
    Wed, 28 Nov 2001 13:52:10 +0000
Received: from listserv3 ([63.111.243.44]) by la-infoserver.develop.com
    with Microsoft SMTPSVC(5.0.2195.2966); Wed, 28 Nov 2001 02:09:36 -0800
Received: from DISCUSS.DEVELOP.COM by DISCUSS.DEVELOP.COM (LISTSERV-TCP/IP
    release 1.8d) with spool id 897536 for SOAP@DISCUSS.DEVELOP.COM;
    Wed, 28 Nov 2001 02:09:36 -0800
Received: from 194.213.203.154 by DISCUSS.DEVELOP.COM (SMTPL release 1.0d)
    with TCP; Wed, 28 Nov 2001 01:39:35 -0800
Received: (qmail 16376 invoked by uid 0); 28 Nov 2001 10:39:34 +0100
Received: from big.in.idoox.com (HELO BIG) (10.0.0.71) by
    bimbo.in.idoox.com with SMTP; 28 Nov 2001 10:39:34 +0100
References: <007001c1784c$eb8d5400$151010ac@visic21>
MIME-Version: 1.0
Content-Type: multipart/alternative;
    boundary="----=_NextPart_000_00E2_01C177F8.F80311B0"
X-Priority: 3
X-Msmail-Priority: Normal
X-Mailer: Microsoft Outlook Express 5.50.4807.1700
X-Mimeole: Produced By Microsoft MimeOLE V5.50.4807.1700
X-Virus-Scanned: by AMaViS
Message-Id: <00e501c177f0$965eb4d0$4700000a@in.idoox.com>
Date: Wed, 28 Nov 2001 10:39:33 +0100
Reply-To: SOAP <SOAP@DISCUSS.DEVELOP.COM>
Sender: SOAP <SOAP@DISCUSS.DEVELOP.COM>
From: Jan Alexander <alex@SYSTINET.COM>
Subject: Re: Authenticating Example Messages
To: SOAP@DISCUSS.DEVELOP.COM
X-Originalarrivaltime: 28 Nov 2001 10:09:36.0701 (UTC) FILETIME=[C8C2A6D0:
    01C177F4]

Example Message
