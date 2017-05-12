#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'ryokoforever', 'listname');
is($list->listsoftware, 'Yahoo! Groups', 'list software');
is($list->posting_address, 'ryokoforever@yahoogroups.com', 'posting address');

__DATA__
From sentto-482527-3071-992625570-turner=mikomi.org@returns.onelist.com  Fri Jun 15 13:21:26 2001
Return-Path: <sentto-482527-3071-992625570-turner=mikomi.org@returns.onelist.com>
Received: from ef.egroups.com (ef.egroups.com [64.211.240.229]) by
    undef.jmac.org (8.11.0/8.11.0) with SMTP id f5FHLPl26276 for
    <turner@mikomi.org>; Fri, 15 Jun 2001 13:21:26 -0400
Received: from [10.1.4.54] by ef.egroups.com with NNFMP; 15 Jun 2001
    17:19:30 -0000
Received: (qmail 74089 invoked from network); 15 Jun 2001 17:19:29 -0000
Received: from unknown (10.1.10.26) by l8.egroups.com with QMQP;
    15 Jun 2001 17:19:29 -0000
Received: from unknown (HELO c9.egroups.com) (10.1.2.66) by mta1 with SMTP;
    15 Jun 2001 17:19:29 -0000
X-Egroups-Return: turner@undef.jmac.org
Received: from [10.1.2.91] by c9.egroups.com with NNFMP; 15 Jun 2001
    17:19:28 -0000
X-Egroups-Approved-BY: lordtenchimasaki@planetjurai.com via web; 15 Jun
    2001 17:19:26 -0000
X-Sender: turner@undef.jmac.org
X-Apparently-To: ryokoforever@yahoogroups.com
Received: (EGP: mail-7_1_3); 15 Jun 2001 15:04:27 -0000
Received: (qmail 72431 invoked from network); 15 Jun 2001 15:04:26 -0000
Received: from unknown (10.1.10.26) by l7.egroups.com with QMQP;
    15 Jun 2001 15:04:26 -0000
Received: from unknown (HELO undef.jmac.org) (199.232.41.30) by mta1 with
    SMTP; 15 Jun 2001 15:04:26 -0000
Received: (from turner@localhost) by undef.jmac.org (8.11.0/8.11.0) id
    f5FF54H25878 for ryokoforever@yahoogroups.com; Fri, 15 Jun 2001 11:05:04
    -0400
To: ryokoforever@yahoogroups.com
Message-Id: <20010615110504.F23926@mikomi.org>
References: <65.15c83c77.285a1ed0@aol.com> <9gc0tj+9u4r@eGroups.com>
User-Agent: Mutt/1.2.5i
In-Reply-To: <9gc0tj+9u4r@eGroups.com>; from gensao@yahoo.com on Fri,
    Jun 15, 2001 at 03:54:27AM -0000
From: Andrew Turner <turner@mikomi.org>
MIME-Version: 1.0
Mailing-List: list ryokoforever@yahoogroups.com; contact
    ryokoforever-owner@yahoogroups.com
Delivered-To: mailing list ryokoforever@yahoogroups.com
Precedence: list
List-Unsubscribe: <mailto:ryokoforever-unsubscribe@yahoogroups.com>
Date: Fri, 15 Jun 2001 11:05:04 -0400
Reply-To: ryokoforever@yahoogroups.com
Subject: [ryokoforever] Re: [ryokoforever] Re: Fan Fiction Websites
Content-Type: text/plain; charset=US-ASCII
Content-Transfer-Encoding: 7bit
Status: RO
Content-Length: 631
Lines: 16

Yeah, I'm really sorry about all this.  The stupid cable company has been
very unhelpful in getting my cable modem back online... I'll be moving my
machine (and thus, the domains hosted with it like tmffa.com) to a colo
environment very soon, which should put an end to down time.

--
Andy <turner@mikomi.org>


To unsubscribe from this group, send an email to:
ryokoforever-unsubscribe@egroups.com

 

Your use of Yahoo! Groups is subject to http://docs.yahoo.com/info/terms/ 




