#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 8;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'sample@v2.listbox.com', 'listname');
is($list->listsoftware, 'listbox.com v2.0', 'list software');
is($list->posting_address, 'sample@v2.listbox.com', 'posting address');

$mail->head->delete('List-Software');

$list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'sample@v2.listbox.com', 'listname');
is($list->listsoftware, 'listbox.com v2.0', 'list software');
is($list->posting_address, 'sample@v2.listbox.com', 'posting address');

__DATA__
Return-Path: <owner-sample@v2.listbox.com>
Received: from rime.listbox.com ([216.65.124.73] verified) by
    freeonline.com.au (CommuniGate Pro SMTP 4.0.6) with ESMTP id 452321 for
    mld-listbox@walker.wattle.id.au; Tue, 17 Jun 2003 20:16:02 +0000
Received: by rime.listbox.com (Postfix, from userid 440) id 7378ADF7381;
    Tue, 17 Jun 2003 16:18:01 -0400 (EDT)
Received: from umbrella.listbox.com (umbrella.listbox.com
    [208.210.125.21]) by rime.listbox.com (Postfix) with ESMTP id 7378ADF7381
    for <sample@v2.listbox.com@fast.exploders.listbox.com>;
    Tue, 17 Jun 2003 16:18:00 -0400 (EDT)
Received: by umbrella.listbox.com (Postfix, from userid 440) id
    7378ADF7381; Tue, 17 Jun 2003 16:17:01 -0400 (EDT)
Received: from freeonline.com.au (a.mx.freeonline.com.au
    [127.0.0.126]) by umbrella.listbox.com (Postfix) with SMTP id
    7378ADF7381 for <sample@v2.listbox.com>; Tue, 17 Jun 2003 16:16:59
    -0400 (EDT)
Message-Id: <7378ADF7381aTjhj36@x>
Date: Tue, 17 Jun 2003 13:17:17 -0700
To: sample@v2.listbox.com
From: "Listbox Sample" <mld+listbox@walker.wattle.id.au>
Subject: [sample] Archive
Sender: owner-sample@v2.listbox.com
Precedence: list
Reply-To: sample@v2.listbox.com
List-Id: <sample@v2.listbox.com>
List-Software: listbox.com v2.0
List-Help: <http://v2.listbox.com/help?list_name=sample@v2.listbox.com>
List-Subscribe: <mailto:subscribe-sample@v2.listbox.com>,
    <http://v2.listbox.com/subscribe/?listname=sample@v2.listbox.com>
List-Unsubscribe: <mailto:unsubscribe-sample@v2.listbox.com>,
    <http://v2.listbox.com/member/unsubscribe/?listname=sample@v2.listbox.com>

An archive for this list is there ?

-------
Sample: http://example.com/
Archives at http://archives.listbox.com/sample/current/
To unsubscribe, change your address, or temporarily deactivate your subscription, 
please go to http://v2.listbox.com/member/?listname=sample@v2.listbox.com

