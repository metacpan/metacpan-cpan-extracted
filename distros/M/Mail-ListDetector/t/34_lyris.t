#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'emailxlmi', 'listname');
is($list->listsoftware, 'Lyris', 'list software');
is($list->posting_address, 'emailxlmi@xlmi.example.com', 'posting address');

__DATA__
Return-Path: <bounce-emailxlmi-42403@xlmi.example.com>
Received: from xlmi.example.com ([10.9.5.7])
 by mail.example.net (Example Mail Service) with SMTP id 19shajdhaj
 for <superduper@example.org>; Tue, 24 Jun 2003 13:17:12 +1000 (EDT)
X-Mailer: Lyris ListManager Web Interface
Date: Tue, 24 Jun 2003 14:37:14 -0700
Subject: XLMI Usage
To: "XLMI" <emailxlmi@xlmi.example.com>
From: "XLMI" <emailxlmi@xlmi.example.com>
List-Unsubscribe: <mailto:leave-emailxlmi-42403F@xlmi.example.com>
Reply-To: emailxlmi@xlmi.example.com
X-LYRIS-Message-Id: <LYRIS-44203-20002-2003.06.24-04.37.15--superduper#example.org@xlmi.example.com>
Message-Id: <200306240334.19shajdhaj@mail.example.net>

This one uses the X-Lyris-Message-Id instead of Message-Id

