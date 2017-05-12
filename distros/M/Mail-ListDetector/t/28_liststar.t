#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'info-mac', 'listname');
is($list->listsoftware, 'ListSTAR v1.2', 'list software');
is($list->posting_address, 'digest@info-mac.org', 'posting address');

__DATA__
Return-Path: <info-mac@starnine.com>
Received: from mail05.rapidsite.net (mail05.rapidsite.net [207.158.192.42])
        by woody.wcnet.org (8.9.1/8.9.1) with SMTP id EAA11417 
        for <ktweney@wcnet.org>; Fri, 16 Apr 1999 04:57:30 -0400 (EDT)
Received: from bulk.starnine.com (198.211.93.99)
        by mail05.rapidsite.net (RS ver 1.0.2) with SMTP id 7312
        for <kathleen@tweney.com>; Fri, 16 Apr 1999 04:57:13 -0400 (EDT)
Received: from liststar3.starnine.com (liststar3.starnine.com [198.211.93.47])
        by bulk.starnine.com (8.8.7/8.8.7) with SMTP id BAA11082;
        Fri, 16 Apr 1999 01:51:27 -0700 (PDT)
Date: Fri, 16 Apr 1999 04:34:11 -0400 (EDT)
Message-Id: <199904160834.EAA09513@info-mac.org>
Subject: Info-Mac Digest V16 #287
Content-Type: multipart/mixed; boundary="Info-Mac-Digest"
From: "Info-Mac" <info-mac@starnine.com>
Sender: "Info-Mac" <info-mac@starnine.com>
Reply-To: "Info-Mac" <info-mac@starnine.com>
Errors-To: "Info-Mac" <info-mac@starnine.com>
Mime-Version: 1.0
Precedence:  Bulk
List-Unsubscribe: <mailto:info-mac@starnine.com?subject=unsubscribe>
List-Post: <mailto:digest@info-mac.org> (Postings are moderated)
List-Subscribe: <mailto:info-mac@starnine.com?subject=subscribe>
List-Help: <http://info-mac.starnine.com/>
List-Archive: <http://hyperarchive.lcs.mit.edu/HyperArchive/Abstracts/per/im/HyperDate.html>
List-Owner: <mailto:moderator@info-mac.org> (Info-Mac Moderators)
List-Software: "ListSTAR v1.2 by StarNine Technologies, Inc."
List-URL: <http://www.info-mac.org/>
To: kathleen@tweney.com
X-Loop-Detect: 1
Status:  O

Another sample Liststar message.

