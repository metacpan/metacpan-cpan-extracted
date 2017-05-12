#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 4;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'sitefinder-tech-discuss.lists.elistx.com', 'listname');
is($list->listsoftware, 'RFC2919', 'list software');
is($list->posting_address, 'sitefinder-tech-discuss@lists.elistx.com', 'posting address');

__DATA__
Return-Path: <sitefinder-tech-discuss-errors@lists.elistx.com>
Received: from ELIST-DAEMON.eListX.com by eListX.com (PMDF V6.0-025 #BADACE)
 id <0HMF00D04FHETX@eListX.com> (original mail from mloftis@wgops.com); Wed,
 08 Oct 2003 03:00:50 -0400 (EDT)
Received: from CONVERSION-DAEMON.eListX.com by eListX.com
 (PMDF V6.0-025 #BADACE) id <0HMF00D01FHDTV@eListX.com> for
 sitefinder-tech-discuss@elist.lists.elistx.com
 (ORCPT sitefinder-tech-discuss@lists.elistx.com); Wed,
 08 Oct 2003 03:00:50 -0400 (EDT)
Received: from DIRECTORY-DAEMON.eListX.com by eListX.com (PMDF V6.0-025 #BADACE)
 id <0HMF00D01FHDTU@eListX.com> for
 sitefinder-tech-discuss@elist.lists.elistx.com
 (ORCPT sitefinder-tech-discuss@lists.elistx.com); Wed,
 08 Oct 2003 03:00:49 -0400 (EDT)
Received: from shell.wgops.com (shell.wgops.com [66.92.192.108])
 by eListX.com (PMDF V6.0-025 #BADACE) with ESMTP id <0HMF00BAAFHCNK@eListX.com>
 for sitefinder-tech-discuss@lists.elistx.com; Wed,
 08 Oct 2003 03:00:49 -0400 (EDT)
Date: Wed, 08 Oct 2003 00:58:24 -0600
From: Michael Loftis <mloftis@wgops.com>
Subject: Re: [sitefinder-tech-discuss] A technical question
To: sitefinder-tech-discuss@lists.elistx.com
Message-id: <136654568.1065574704@[10.1.2.77]>
MIME-version: 1.0
X-Mailer: Mulberry/3.0.3 (Win32)
Content-type: text/plain; format=flowed; charset=us-ascii
Content-transfer-encoding: 7BIT
Content-disposition: inline
List-Owner: <mailto:sitefinder-tech-discuss-help@lists.elistx.com>
List-Post: <mailto:sitefinder-tech-discuss@lists.elistx.com>
List-Subscribe: <http://lists.elistx.com/subscribe>,
 <mailto:sitefinder-tech-discuss-request@lists.elistx.com?body=subscribe>
List-Unsubscribe: <http://lists.elistx.com/unsubscribe>,
 <mailto:sitefinder-tech-discuss-request@lists.elistx.com?body=unsubscribe>
List-Archive: <http://lists.elistx.com/archives/sitefinder-tech-discuss/>
List-Help: <http://lists.elistx.com/elists/admin.shtml>,
 <mailto:sitefinder-tech-discuss-request@lists.elistx.com?body=help>
List-Id: <sitefinder-tech-discuss.lists.elistx.com>

There used to be a message here!
