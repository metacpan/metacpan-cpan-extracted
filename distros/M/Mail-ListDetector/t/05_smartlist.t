#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Mail::Internet;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);
	
ok(defined($list), 'List is defined');
is($list->listname, 'debian-devel', 'list is debian-devel');
is($list->listsoftware, 'smartlist', 'software is smartlist');
is($list->posting_address, 'debian-devel@lists.debian.org', 'posting address');

# Email used with permission from roger, assuming tests only
# available to those downloading the archive.

__DATA__
From bounce-debian-devel=zal=debian.org@lists.debian.org Wed Jan  9 16:19:33 2002
X-Envelope-From: bounce-debian-devel=zal=debian.org@lists.debian.org  Wed Jan  9 16:19:33 2002
Return-Path: <bounce-debian-devel=zal=debian.org@lists.debian.org>
Delivered-To: laz+debian@clustermonkey.org
Received: from master.debian.org (master.debian.org [216.234.231.5])
	by x-o.clustermonkey.org (Postfix) with ESMTP id 0DCF661EB84
	for <laz+debian@clustermonkey.org>; Wed,  9 Jan 2002 16:19:33 -0500 (EST)
Received: from murphy.debian.org [216.234.231.6] 
	by master.debian.org with smtp (Exim 3.12 1 (Debian))
	id 16OQ8C-0004ll-00; Wed, 09 Jan 2002 15:19:32 -0600
Received: (qmail 22818 invoked by uid 38); 9 Jan 2002 21:07:42 -0000
X-Envelope-Sender: debbugs@master.debian.org
Received: (qmail 22385 invoked from network); 9 Jan 2002 21:07:37 -0000
Received: from master.debian.org (mail@216.234.231.5)
  by murphy.debian.org with SMTP; 9 Jan 2002 21:07:37 -0000
Received: from debbugs by master.debian.org with local (Exim 3.12 1 (Debian))
	id 16OPvY-0003bQ-00; Wed, 09 Jan 2002 15:06:28 -0600
X-Loop: owner@bugs.debian.org
Subject: Bug#128487: ITP: ferite -- Ferite programming language
Reply-To: Eric Dorland <eric@debian.org>, 128487@bugs.debian.org
Resent-From: Eric Dorland <eric@debian.org>
Original-Sender: Eric <eric@apocalypse>
Resent-To: debian-bugs-dist@lists.debian.org
Resent-Cc: debian-devel@lists.debian.org, wnpp@debian.org
Resent-Date: Wed, 09 Jan 2002 21:06:27 GMT
Resent-Message-ID: <handler.128487.B.101061021111054@bugs.debian.org>
X-Debian-PR-Message: report 128487
X-Debian-PR-Package: wnpp
Received: via spool by submit@bugs.debian.org id=B.101061021111054
          (code B ref -1); Wed, 09 Jan 2002 21:06:27 GMT
From: Eric Dorland <eric@debian.org>
To: Debian Bug Tracking System <submit@bugs.debian.org>
X-Reportbug-Version: 1.41.14213
X-Mailer: reportbug 1.41.14213
Date: Wed, 09 Jan 2002 16:03:25 -0500
Message-Id: <E16OPsb-0000u7-00@apocalypse>
Sender: Eric <eric@apocalypse.clustermonkey.org>
Delivered-To: submit@bugs.debian.org
X-Mailing-List: <debian-devel@lists.debian.org> archive/latest/105153
X-Loop: debian-devel@lists.debian.org
Precedence: list
Resent-Sender: debian-devel-request@lists.debian.org
Status: RO

Package: wnpp
Version: N/A; reported 2002-01-09
Severity: wishlist

* Package name    : ferite
  Version         : 0.99.4
  Upstream Author : Chris Ross (boris) <ctr@ferite.org>
* URL             : http://www.ferite.org/
* License         : BSD
  Description     : Ferite programming language

Ferite is a language that incorporates the design philosophies of other
languages, but without many of their drawbacks. It has strong
similiarities to perl, python, C, Java and pascal, while being both
lightweight, modular, and embeddable.

-- System Information
Debian Release: 3.0
Architecture: i386
Kernel: Linux apocalypse 2.4.16 #1 Fri Nov 30 14:38:38 EST 2001 i686
Locale: LANG=en_US, LC_CTYPE=



-- 
To UNSUBSCRIBE, email to debian-devel-request@lists.debian.org
with a subject of "unsubscribe". Trouble? Contact listmaster@lists.debian.org


