#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, '14list', 'listname');
is($list->listsoftware, 'ListSTAR v2.2', 'list software');
is($list->posting_address, '14list@i14.org', 'posting address');

__DATA__
Return-Path: <14list@i14.org>
Received: from [63.196.3.242] (helo=adsl-63-196-3-242.dsl.snfc21.pacbell.net)
    by dfw-smtpin2.email.verio.net with esmtp id 15wR3B-0002TC-00
    for speplin@oh.verio.com; Wed, 24 Oct 2006:38:42 +0000
Received: from 63.196.3.242 by adsl-63-196-3-242.dsl.snfc21.pacbell.net
    with SMTP (Eudora Internet Mail Server 1.3.1); Wed, 24 Oct 2001 09:37:22 -0700
Date: Wed, 24 Oct 2001 16:25:41 +0000 (GMT)
Message-Id: <Pine.LNX.4.40.0110241616130.2655-100000@dukes.argonet.co.uk>
From: Andy Loukes <andy@loukes.com>
Subject: [I14] Guide to worlds proposals
To: 14list <maillist@i14.org>
Mime-Version: 1.0
Content-Type: TEXT/PLAIN; charset=US-ASCII
Precedence: Normal
Errors-to: "Rand Arnold" <listmaster@i14.org>
X-Administrator: listmaster@i14.org
X-Server: PowerMac 8500/250
X-Listserver: ListSTAR v2.2, by MCF Software, LLC
X-List-Subscribe: <mailto:14list@i14.org?subject=subscribe>
X-List-Unsubscribe: <mailto:14list@i14.org?subject=unsubscribe>

And yet another sample Liststar message.

