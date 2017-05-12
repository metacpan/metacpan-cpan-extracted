use Test;
use File::Spec;

BEGIN { plan tests => 28 };
use lib qw(../blib/lib ../blib/arch);
use Mail::Transport::Dbx;

ok(1); # If we made it this far, we're ok.

my $header = <<'EOHEADER';
Return-path: <noreply@freshmeat.net>
Received: from ue250-1.rz.RWTH-Aachen.DE
 ("port 53613"@ue250-1.rz.RWTH-Aachen.DE [134.130.3.33])
 by mails.rz.rwth-aachen.de
 (Sun Internet Mail Server sims.4.0.2000.10.12.16.25.p8)
 with ESMTP id <0GXV006EF90614@mails.rz.rwth-aachen.de> for
 tp517810?post.rwth-aachen.de@sims-ms-daemon
 (ORCPT rfc822;Tassilo.Parseval@post.rwth-aachen.de); Mon,
 17 Jun 2002 22:02:30 +0200 (MET DST)
Received: from ue250-1.rz.RWTH-Aachen.DE (relay1.RWTH-Aachen.DE [134.130.3.3])
	by ue250-1.rz.RWTH-Aachen.DE (8.12.1/8.11.3-3) with ESMTP id g5HK2T1I000898
	for <Tassilo.Parseval@post.rwth-aachen.de>; Mon,
 17 Jun 2002 22:02:29 +0200 (MEST)
Received: from mail.freshmeat.net (mail.freshmeat.net [64.28.67.97])
	by ue250-1.rz.RWTH-Aachen.DE (8.12.1/8.11.3/23) with ESMTP id g5HK2O8W000801
	for <Tassilo.Parseval@post.rwth-aachen.de>; Mon,
 17 Jun 2002 22:02:29 +0200 (MEST)
Received: from localhost.localdomain (localhost.freshmeat.net [127.0.0.1])
	by localhost.freshmeat.net (Postfix) with ESMTP	id 4C63883025; Mon,
 17 Jun 2002 15:42:20 -0400 (EDT)
Received: from freshmeat.net (www2.freshmeat.net [10.2.35.2])
	by mail.freshmeat.net (Postfix) with SMTP	id DF10883011; Mon,
 17 Jun 2002 15:42:07 -0400 (EDT)
Date: Mon, 17 Jun 2002 15:42:07 -0400 (EDT)
From: noreply@freshmeat.net
Subject: [fmII] centericq 4.7.5 released (Default branch)
To: noreply@freshmeat.net
Message-id: <20020617194207.DF10883011@mail.freshmeat.net>
EOHEADER

my $body = <<EOBODY;
This email is to inform you of release '4.7.5' of 'centericq' through
freshmeat.net. All URLs and other useful information can be found at
http://freshmeat.net/projects/centericq/

The changes in this release are as follows:
Birthday reminders were implemented. An ability to store and load sets
of search information under profiles was added to the "Find/add"
dialog. IRC search only by email without channel specification was
added. A segfault was fixed in the MSN part. 

Project description:
centericq is a text mode menu- and window-driven IM interface that
supports the ICQ2000, Yahoo!, AIM, MSN, and IRC protocols. It allows
you to send, receive, and forward messages, URLs, SMSes (both through
the ICQ server and email gateways supported by Mirabilis), contacts,
and email express messages, and it has many other useful features. 

If you would like to cancel subscription to releases of this project,
login to freshmeat.net and choose 'home' from the personal menubar at the
top of the page. You'll be presented with a list of projects you're
subscribed to in the right column, which you may cancel by highlighting
the project in question and clicking the 'delete' button.

Sincerely,
freshmeat.net
EOBODY

s/\n/\015\012/g for $header, $body;
    
my $dbx = eval {
    Mail::Transport::Dbx->new(File::Spec->catfile("t", "test1.dbx"));
};

ok(!$@);
ok($dbx);
ok($dbx->msgcount, 1);
ok($dbx->errstr, "No error");

my $item = $dbx->get(0);

ok($dbx->errstr, "No error");
ok($item);
ok($item->isa("Mail::Transport::Dbx::Email"));
ok($item->as_string);
ok($item->header, $header);
ok($item->body, $body);
ok($item->subject, "[fmII] centericq 4.7.5 released (Default branch)");
ok($item->psubject, $item->subject);
ok($item->msgid, '<20020617194207.DF10883011@mail.freshmeat.net>');
ok($item->parents_ids, undef);
ok($item->sender_name, 'noreply@freshmeat.net');
ok($item->sender_address, 'noreply@freshmeat.net');
ok($item->recip_name, 'noreply@freshmeat.net');
ok($item->recip_address, '<noreply@freshmeat.net>');
ok($item->oe_account_name, "pbox.dialup.rwth-aachen.de");
ok($item->oe_account_num, "00000001");
ok($item->fetched_server, "pbox.dialup.rwth-aachen.de");
ok($item->rcvd_gmtime, "Mon Jun 17 20:02:30 2002");
ok($item->date_received);
ok($item->is_seen);
ok($item->is_email);
ok($item->is_folder, 0);

$dbx->get(1);
ok($dbx->errstr, "Index out of range");
