#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Mail::Internet;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'london-pm', 'list name');
is($list->listsoftware, 'majordomo', 'list software');
is($list->posting_address, 'london-pm@lists.dircon.co.uk', 'posting address');

__DATA__
From owner-london-pm@lists.dircon.co.uk Sun Jan 21 17:08:14 2001
Envelope-to: michael@etla.org
Received: from lists.dircon.co.uk [194.112.50.5] 
	by dayspring.firedrake.org with esmtp (Exim 3.12 #1 (Debian))
	id 14KNyQ-0007mp-00; Sun, 21 Jan 2001 17:08:14 +0000
Received: (from majordom@localhost)
	by lists.dircon.co.uk (8.9.3/8.9.3) id RAA28531
	for michael@etla.org; Sun, 21 Jan 2001 17:08:13 GMT
X-Authentication-Warning: lists.dircon.co.uk: majordom set sender to owner-london-pm@lists.dircon.co.uk using -f
Received: from dayspring.firedrake.org (mail@dayspring.firedrake.org [195.82.105.251])
	by lists.dircon.co.uk (8.9.3/8.9.3) with ESMTP id RAA28043
	for <london-pm@lists.dircon.co.uk>; Sun, 21 Jan 2001 17:07:23 GMT
Received: from mstevens by dayspring.firedrake.org with local (Exim 3.12 #1 (Debian))
	id 14KNxb-0007mH-00; Sun, 21 Jan 2001 17:07:23 +0000
Date: Sun, 21 Jan 2001 17:07:23 +0000
From: Michael Stevens <michael@etla.org>
To: london-pm@lists.dircon.co.uk
Subject: Mail::ListDetector - please test
Message-ID: <20010121170723.A29498@firedrake.org>
Mail-Followup-To: london-pm@lists.dircon.co.uk
Mime-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline
User-Agent: Mutt/1.2.5i
X-Phase-Of-Moon: The Moon is Waning Crescent (7% of Full)
Sender: owner-london-pm@lists.dircon.co.uk
Precedence: bulk
Reply-To: london-pm@lists.dircon.co.uk
Status: RO

Hi.

I have an (as yet unreleased) module called Mail::ListDetector,
which takes a Mail::Internet object, and attempts to tell you if the
message involved was posted to a mailing list, and if so, attempts to
get some details about that list.

I need testers - in particular, see if it builds and passes tests for
you, and throw lots of messages at the sample script and see if you
can get it to be inaccurate for any of them. If you can, please send
me the message in question. (if you don't want to give out the content,
just headers should do).

Currently it should know about majordomo, smartlist, ezmlm, and mailman,
although the majordomo and smartlist guessers are a bit experimental.

It's at:

http://www.etla.org/Mail-ListDetector-0.05.tar.gz

Michael

