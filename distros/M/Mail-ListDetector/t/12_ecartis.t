#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use Mail::Internet;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'adm', 'list name');
is($list->listsoftware, 'Ecartis v1.0.0', 'list name');
is($list->posting_address, 'adm@oasys.net', 'posting address');

__DATA__
From adm-bounce@oasys.net  Mon Jun  4 06:41:14 2001
Received: from thufir.oasys.net (oasys.net [216.227.134.4]) by
    nani.mikomi.org (8.9.3/8.9.3) with ESMTP id GAA08314 for
    <turner@mikomi.org>; Mon, 4 Jun 2001 06:41:13 -0400
Received: from thufir (thufir [127.0.0.1]) by thufir.oasys.net (Postfix)
    with ESMTP id 345138003; Mon,  4 Jun 2001 06:41:12 -0400 (EDT)
Received: with ECARTIS (v1.0.0; list adm); Mon, 04 Jun 2001 06:41:12 -0400
    (EDT)
Delivered-To: adm@oasys.net
Received: from nani.mikomi.org (nani.mikomi.org [216.227.135.6]) by
    thufir.oasys.net (Postfix) with ESMTP id 8AF917FC1 for <adm@oasys.net>;
    Mon,  4 Jun 2001 06:41:10 -0400 (EDT)
Received: (from turner@localhost) by nani.mikomi.org (8.9.3/8.9.3) id
    GAA08291; Mon, 4 Jun 2001 06:41:07 -0400
X-Authentication-Warning: nani.mikomi.org: turner set sender to
    turner@mikomi.org using -f
Date: Mon, 4 Jun 2001 06:41:07 -0400
From: Andrew Turner <turner@mikomi.org>
To: Seikihyougen <seikihyougen@mikomi.org>
Cc: adm@oasys.net
Subject: [adm] Marvin Minsky AI Talk
Message-Id: <20010604064107.A6940@mikomi.org>
Mail-Followup-To: Seikihyougen <seikihyougen@mikomi.org>, adm@oasys.net
MIME-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline
User-Agent: Mutt/1.3.14i
X-Archive-Position: 161
X-Ecartis-Version: Ecartis v1.0.0
Sender: adm-bounce@oasys.net
Errors-To: adm-bounce@oasys.net
X-Original-Sender: turner@mikomi.org
Precedence: list
Reply-To: adm@oasys.net
X-List: adm
Status: RO
Content-Length: 498
Lines: 21

An intersting talk he gave at the Game Developers Conference 2001.

Video:

rtsp://media.cmpnet.com/twtoday_media/realtest/tnc-gdc2k1-prog.rm

Audio:

http://199.125.85.76/ftp/technetcast/mp3/tnc-0526-24.mp3

Transcript:

http://technetcast.ddj.com/tnc_play_stream.html?stream_id=526

-- 
Andy <turner@mikomi.org> - http://anime.mikomi.org/ - Community Anime Reviews
  And the moral of this message is...
    Let the meek inherit the earth -- they have it coming to them.
    		-- James Thurber





