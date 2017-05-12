#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'Autoshare-Talk.lists.example.com', 'listname');
is($list->listsoftware, 'AutoShare 4.2b3', 'list software');
is($list->posting_address, 'autoshare-talk@lists.example.com', 'posting address');

__DATA__
Return-Path: <AutoShare-Talk-errors@lists.example.com>
Received: from turing.example.com (10.20.11.46) by another.example.com with
 ESMTP (Eudora Internet Mail Server 2.2.2); Sat, 8 Apr 2000 09:30:14 -0500
Received: from oberon.example.com (207.181.194.97) by turing.example.com with
 ESMTP (Eudora Internet Mail Server 3.0) for <autoshare-talk@lists.example.com>;
 Sat, 8 Apr 2000 08:11:54 -0700
Received: from triton.example.com (sendmail@triton.example.com [207.181.195.20])
      by oberon.example.com (8.9.3/8.9.3) with ESMTP id IBB56145
      for <autoshare-talk@lists.example.com>; Sat, 8 Apr 2000 08:12:04 -0700 (PDT)
Received: from localhost (meh@localhost)
      by triton.example.com (8.8.7/8.8.7) with SMTP id IBB59797
      for <autoshare-talk@lists.example.com>; Sat, 8 Apr 2000 08:12:04 -0700 (PDT)
      (envelope-from user@example.com)
Date: Sat, 8 Apr 2000 08:12:04 -0700 (PDT)
Reply-To: autoshare-talk@lists.example.com (Subscribers of AutoShare-Talk)
Errors-To: AutoShare-Talk-errors@lists.example.com (List Administrator)
Precedence: bulk
List-Subscribe: <mailto:autoshare-talk-request@lists.example.com?body=subscribe>
List-Unsubscribe: <mailto:autoshare-talk-request@lists.example.com?body=unsubscribe>
List-Archive: <mailto:autoshare@lists.example.com?body=index%20Autoshare-Talk>
List-Post: <mailto:autoshare-talk@lists.example.com>
List-Owner: listmaster@lists.example.com (Example Mailing List Admin)
List-Help: <http://www.example.com/~user/autoshare/> 
List-Id: <Autoshare-Talk.lists.example.com>
List-Software: AutoShare 4.2b3 by Mikael Hansen
From: Example User <user@example.com>
To: autoshare-talk@lists.example.com (Subscribers of AutoShare-Talk)
Subject: Re: An Interesting Example
MIME-Version: 1.0
Content-Type: TEXT/PLAIN; charset=US-ASCII
Message-Id: <128338349534862@lists.example.com>

A sample Autoshare message

