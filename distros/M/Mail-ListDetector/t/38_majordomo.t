#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Mail::Internet;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'seminar-13', 'list name');
is($list->listsoftware, 'majordomo', 'list software');
is($list->posting_address, 'seminar-13@lists.village.example.org', 'posting address');

__DATA__
From owner-seminar-13@lists.village.example.org  Fri Jun 30 10:51:21 2000
Received: (from domo@localhost)
        by lists.village.example.org (8.9.3/8.9.0) id KAA55822
        for seminar-13-outgoing; Fri, 30 Jun 2000 10:50:54 GMT
X-Authentication-Warning: lists.village.example.org: domo set sender to owner-seminar-13@localhost using -f
Received: from mb1i0.ns.example.org (mb1i0.ns.example.org [10.12.16.245])
        by lists.village.example.org (8.9.3/8.9.0) with ESMTP id GAA54528;
        Fri, 30 Jun 2000 06:50:12 -0400
Received: from bgnet.bgsu.edu ("port 1406"@[10.12.243.7])
 by mb1i0.ns.pitt.edu (PMDF V5.2-32 #41462)
 with ESMTP id <01JR7DXX1VYO001CTX@mb1i0.ns.example.org>; Fri,
 30 Jun 2000 06:50:02 EST
Date: Fri, 30 Jun 2000 06:38:53 -0400
From: Jet D <jetd@bgnet.example.org>
Subject: [Fwd: [] Scope of majordomo installs]
To: sa-cyborgs@lists.village.example.org,
        seminar-13@lists.village.example.org,
        technology@lists.village.example.org
Message-id: <395C78BD.EF28BF42@bgnet.example.org>
MIME-version: 1.0
X-Mailer: Mozilla 4.05 [en] (Win95; I)
Content-type: text/plain; charset=US-ASCII
Sender: owner-seminar-13@lists.village.example.org
Precedence: bulk
Reply-To: seminar-13@lists.village.example.org

This majordomo uses domo as its unix username.
