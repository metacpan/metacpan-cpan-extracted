#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'example', 'listname');
is($list->listsoftware, 'Lyris 3.0', 'list software');
is($list->posting_address, 'example@lists.example.org', 'posting address');

__DATA__
From bounce-example-846@lists.example.org  Thu Dec  2 17:45:52 1999
Received: from lists.example.org (lists.example.org [10.147.7.94])
    by example.org (8.9.3/8.9.3/1.13) with SMTP id RAA13812
    for <lyris.example@example.org>; Thu, 2 Dec 1999 17:45:51 -0600 (CST)
Message-Id: <LYR846-52906-1999.12.02-18.00.00--lyris.example#example.org@lists.example.org>
X-Sender: sender@example.com
Date: Thu, 02 Dec 1999 15:43:10 -0800
To: " Special Lyris Group" <example@lists.example.org>
From: Mr User <mruser@example.com>
Subject: [example] Example
Mime-Version: 1.0
Content-Type: text/plain; charset="us-ascii"
List-Unsubscribe: <mailto:leave-example-846W@lists.example.org>
List-Software: Lyris Server version 3.0
List-Subscribe: <mailto:subscribe-example@lists.example.org>
List-Owner: <mailto:owner-example@lists.example.org>
X-List-Host: Lyris Example <http://www.example.org>
Reply-To: "Special Lyris Group" <example@lists.example.org>
X-Message-Id: <3.0.3.16.19991202154310.35079f6a@example.com>
Sender: bounce-example-846@lists.example.org
Precedence: bulk


A Lyris sample message!
