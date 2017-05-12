#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;
use Mail::Internet;
use Mail::ListDetector;

my $mail = new Mail::Internet(\*DATA);
my $list = new Mail::ListDetector($mail);
ok(defined($list), 'list is defined');
is($list->listname, 'london.pm', 'listname is london.pm');
is($list->listsoftware, 'GNU Mailman version 2.0.1', 'List is mailman 2.0.1');
is($list->posting_address, 'london.pm@london.pm.org', 'posting address is london.pm@london.pm.org');

$mail->head->delete('Sender');

$list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'london.pm', 'listname is london.pm');
is($list->listsoftware, 'GNU Mailman version 2.0.1', 'List is mailman 2.0.1');
is($list->posting_address, 'london.pm@london.pm.org', 'posting address is london.pm@london.pm.org');

__DATA__
From london.pm-admin@london.pm.org Fri Aug 17 13:47:55 2001
Return-Path: <london.pm-admin@london.pm.org>
Received: from punt-2.mail.demon.net by mailstore for
    lpm@mirth.demon.co.uk id 998052475:20:20927:5; Fri, 17 Aug 2001 12:47:55
    GMT
Received: from penderel.state51.co.uk ([193.82.57.128]) by
    punt-2.mail.demon.net id aa2103774; 17 Aug 2001 12:47 GMT
Received: from penderel ([127.0.0.1] helo=penderel.state51.co.uk) by
    penderel.state51.co.uk with esmtp (Exim 3.03 #1) id 15Xj23-0004Oi-00;
    Fri, 17 Aug 2001 13:47:23 +0100
Received: from plough.barnyard.co.uk ([195.149.50.61]) by
    penderel.state51.co.uk with esmtp (Exim 3.03 #1) id 15Xj1T-0004OQ-00 for
    london.pm@london.pm.org; Fri, 17 Aug 2001 13:46:47 +0100
Received: from richardc by plough.barnyard.co.uk with local (Exim 3.13 #1)
    id 15Xj1E-0006Wp-00 for london.pm@london.pm.org; Fri, 17 Aug 2001 13:46:32
    +0100
From: Richard Clamp <richardc@unixbeard.net>
To: london.pm@london.pm.org
Subject: Re: better header
Message-Id: <20010817134539.A9368@mirth.demon.co.uk>
References: <170801229.13787@webbox.com>
    <20010817122254.B18192@mccarroll.demon.co.uk>
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline
In-Reply-To: <20010817122254.B18192@mccarroll.demon.co.uk>
User-Agent: Mutt/1.3.20i
Sender: london.pm-admin@london.pm.org
Errors-To: london.pm-admin@london.pm.org
X-Beenthere: london.pm@london.pm.org
X-Mailman-Version: 2.0.1
Precedence: bulk
Reply-To: london.pm@london.pm.org
List-Id: London.pm Perl M[ou]ngers <london.pm.london.pm.org>
List-Archive: <http://london.pm.org/pipermail/london.pm/>
Date: Fri, 17 Aug 2001 13:45:39 +0100
Status: RO
Content-Length: 439
Lines: 12

On Fri, Aug 17, 2001 at 12:22:54PM +0100, Greg McCarroll wrote:
> testing a reply to the announce list

Could someone extend the hacks committed into changing the
headers and the like, then they'd not be auto-filtered to the same
place by such fine modules as Mail::ListDetector or lesser homebrew
systems such as my own.

The announce lists rocks, but that'd just make it rock so much harder.

-- 
Richard Clamp <richardc@unixbeard.net>


