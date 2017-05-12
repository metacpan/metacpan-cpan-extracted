use Test;
use strict;

BEGIN { plan tests => 6 };

use Mail::MboxParser::Mail;

ok(1);

my ($header, $body, $all) = 
    do {    local $/ = ""; my $hd = <DATA>;
            local $/;      my $bd = <DATA>;
            my $al = "$hd\n$bd";
            ("$hd\n", $bd, $al)    };


ok(my $m1 = Mail::MboxParser::Mail->new($header, $body));
ok(my $m2 = Mail::MboxParser::Mail->new( [ split /\n/, $header ],
                                         [ split /\n/, $body ] ));
ok($m1->body eq $m2->body);
ok($m1->header->{subject} eq $m2->header->{subject});
ok($m1 eq $m2);

__DATA__
Received: from ethan ([127.0.0.1] helo=localhost)
	by ethan with esmtp (Exim 3.35 #1 (Debian))
	id 18Fw3L-0001G1-00
	for <ethan@localhost>; Sun, 24 Nov 2002 13:39:59 +0100
Received: from ms-dienst.rz.rwth-aachen.de [134.130.3.132]
	by localhost with POP3 (fetchmail-5.9.11)
	for ethan@localhost (single-drop); Sun, 24 Nov 2002 13:39:59 +0100 (CET)
Received: from ue250-1.rz.RWTH-Aachen.DE
 (ue250-1.rz.RWTH-Aachen.DE [134.130.3.33]) by ms-dienst.rz.rwth-aachen.de
 (iPlanet Messaging Server 5.2 (built Feb 21 2002))
 with ESMTP id <0H62009MSYYOED@ms-dienst.rz.rwth-aachen.de> for
 tp517810@ims-ms-daemon (ORCPT tassilo.parseval@post.rwth-aachen.de); Sun,
 24 Nov 2002 13:35:12 +0100 (MET)
Received: from ms-1 (ms-1.rz.RWTH-Aachen.DE [134.130.3.130])
	by ue250-1.rz.RWTH-Aachen.DE (8.12.1/8.11.3-3) with ESMTP id gAOCZCsc016474
	for <tassilo.parseval@post.rwth-aachen.de>; Sun,
 24 Nov 2002 13:35:12 +0100 (MET)
Received: from ue250-1.rz.RWTH-Aachen.DE ([134.130.3.33])
	by ms-1 (MailMonitor for SMTP v1.2.0 Beta3) ; Sun,
 24 Nov 2002 13:35:11 +0100 (MET)
Received: from onion.perl.org (onion.valueclick.com [64.70.54.95])
	by ue250-1.rz.RWTH-Aachen.DE (8.12.1/8.11.3/24) with SMTP id gAOCZ5BU016407
	for <tassilo.parseval@post.rwth-aachen.de>; Sun,
 24 Nov 2002 13:35:10 +0100 (MET)
Received: (qmail 26579 invoked by uid 1008); Sun, 24 Nov 2002 12:35:04 +0000
Received: (qmail 26569 invoked by uid 76); Sun, 24 Nov 2002 12:35:04 +0000
Received: from root@[212.40.160.59] (HELO pause.perl.org) (212.40.160.59)
 by onion.perl.org (qpsmtpd/0.12) with SMTP; 2002-11-24 12:35:03Z
Received: (from root@localhost)	by pause.perl.org (8.11.6/8.11.6)
 id gAOCZ0f29640; Sun, 24 Nov 2002 13:35:00 +0100
Date: Sun, 24 Nov 2002 13:35:00 +0100
From: PAUSE <upload@p11.speed-link.de>
Subject: CPAN Upload: V/VP/VPARSEVAL/Mail-MboxParser-0.36.tar.gz
To: Tassilo von Parseval <VPARSEVAL@cpan.org>, cpan-testers@perl.org
Reply-to: cpan-testers@perl.org
Message-id: <200211241235.gAOCZ0f29640@pause.perl.org>
MIME-version: 1.0
Content-type: Text/Plain; Charset=UTF-8
Content-transfer-encoding: 8bit
Delivered-to: cpanmail-VPARSEVAL@cpan.org
X-SMTPD: qpsmtpd/0.12, http://develooper.com/code/qpsmtpd/
X-Spam-Status: No, hits=1.0 required=5.0
	tests=FROM_NAME_NO_SPACES,DOUBLE_CAPSWORD
	version=2.31
X-Spam-Level: *
Status: RO
Content-Length: 459
Lines: 18

The uploaded file

    Mail-MboxParser-0.36.tar.gz

has entered CPAN as

  file: $CPAN/authors/id/V/VP/VPARSEVAL/Mail-MboxParser-0.36.tar.gz
  size: 35589 bytes
   md5: 8d278ce52fb4fb018905084c273281b5

No action is required on your part
Request entered by: VPARSEVAL (Tassilo von Parseval)
Request entered on: Sun, 24 Nov 2002 12:34:21 GMT
Request completed:  Sun, 24 Nov 2002 12:35:00 GMT

	Virtually Yours,
	Id: paused,v 1.81 2002/08/02 11:34:24 k Exp k 

