#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Mail::Internet;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'mld', 'list name');
is($list->listsoftware, 'Google Groups', 'list software');
is($list->posting_address, 'mld@googlegroups.com', 'posting address');

__DATA__
Received: from mproxy.google.com ([216.239.56.250] verified)
  by freeonline.com.au (CommuniGate Pro SMTP 4.1.1)
  with SMTP id 599341 for perl@walker.wattle.id.au; Sat, 05 Jun 2004 02:41:33 +0000
Received: by mproxy.google.com with SMTP id u36so822958cwc
        for <perl@walker.wattle.id.au>; Fri, 04 Jun 2004 19:41:37 -0700 (PDT)
Received: by 10.11.100.73 with SMTP id x73mr4229cwb;
        Fri, 04 Jun 2004 19:41:37 -0700 (PDT)
X-Sender: perl@walker.wattle.id.au
X-Apparently-To: mld@googlegroups.com
Received: by 10.11.122.14 with SMTP id u14mr3130cwc; Fri, 04 Jun 2004 19:41:36 -0700 (PDT)
X-Original-Return-Path: <perl@walker.wattle.id.au>
Received: from 216.239.56.244 (HELO mproxy.google.com) by mx.googlegroups.com with SMTP id v23si459419cwb; Fri, 04 Jun 2004 19:41:36 -0700 (PDT)
Received:perlby mproxy.google.com with SMTP id x30so916139cwb for <mld@googlegroups.com>; Fri, 04 Jun 2004 19:41:36 -0700 (PDT)
Received: by 10.11.122.14 with SMTP id u14mr3129cwc; Fri, 04 Jun 2004 19:41:36 -0700 (PDT)
Message-Id: <1086403296794863@googlegroups.com>
From: perl@walker.wattle.id.au
To: mld@googlegroups.com
Subject: Mail::ListDetector Sample message
Date: Fri, 04 Jun 2004 19:41:36 -0700
User-Agent: G2/0.1
MIME-Version: 1.0
Content-Type: text/plain; charset="iso-8859-1"
Reply-To: mld@googlegroups.com
Precedence: bulk
X-Google-Loop: groups
Mailing-List: list mld@googlegroups.com;
	contact mld-owner@googlegroups.com
List-Id: <mld.googlegroups.com>
List-Post: <mailto:mld@googlegroups.com>
List-Help: <mailto:mld-help@googlegroups.com>


An email so I can add recognition to Mail::ListDetector

PS. do not look for this group at Google, it doesn't exist!


