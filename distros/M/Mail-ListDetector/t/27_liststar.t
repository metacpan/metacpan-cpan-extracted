#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'FAQ-Maintainers', 'listname');
is($list->listsoftware, 'ListSTAR v1.1', 'list software');
is($list->posting_address, 'FAQ-Maintainers@example.com', 'posting address');

__DATA__
Return-Path: <FAQ-Maintainers@example.com>
Received: from mail.example.net (mail3.example.net [157.22.1.19]) by mail5.example.com
	(8.6.13/Netcom) id NAA24464; Thu, 24 Apr 1997 13:08:20 -0700
Received: from lists.example.com (lists.example.com [157.22.240.8]) by mail.example.net
	(8.7.5/8.7.3) with SMTP id MAA04654; Thu, 24 Apr 1997 12:59:15 -0700 (PDT)
Date: Thu, 24 Apr 1997 12:54:13 -0700
Message-Id: <199704249999.MXX17950@mail6.example.com>
From: user@example.com (Will Call)
Subject: Your message was rejected by spam-killer
To: FAQ-Maintainers@example.com
Precedence: Bulk
X-Listserver: ListSTAR v1.1 by StarNine Technologies, a Quarterdeck Company
Reply-To: <FAQ-Maintainers@example.com>
Errors-To: <FAQ-Maintainers@example.com>
X-List-Subscribe: <mailto:FAQ-Maintainers@example.com?subject=subscribe>
X-List-Unsubscribe: <mailto:FAQ-Maintainers@example.com?subject=unsubscribe>
X-List-Help: <mailto:FAQ-Maintainers@example.com?subject=help>

A sample Liststar message

