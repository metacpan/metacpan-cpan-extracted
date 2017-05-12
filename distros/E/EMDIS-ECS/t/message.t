#!/usr/bin/perl -w
#
# Copyright (C) 2002-2016 National Marrow Donor Program. All rights reserved.

use strict;
use File::Spec::Functions qw(catfile);
use Test;
use vars qw($filename $msg $msg2 $tmpdir $txt);
use FindBin;
use lib "$FindBin::Bin";
use MIME::QuotedPrint qw( encode_qp decode_qp );
require 'setup';

# print test plan before loading modules
BEGIN { plan(tests => 97); }
use EMDIS::ECS::Message;

# [1] Was module successfully loaded?
ok(1);

# [2] Is module version consistent?
require EMDIS::ECS;
ok($EMDIS::ECS::VERSION == $EMDIS::ECS::Message::VERSION);

# redirect STDERR to STDOUT (suppress STDERR output during "make test")
open STDERR, ">&STDOUT" or die "Unable to dup STDOUT: $!\n";
select STDERR; $| = 1;   # make unbuffered
select STDOUT; $| = 1;   # make unbuffered

# [3..11] valid meta-message
$msg = new EMDIS::ECS::Message(<<EOF);
Received: from ftp-dmz.nmdp.org (localhost [127.0.0.1])
        by smtp.nmdp.org (8.9.3+Sun/8.9.1) with ESMTP id AAA09650
        for <emdis\@insidesmtp>; Wed, 9 Apr 2003 00:00:41 -0500 (CDT)
X-Authentication-Warning: smtp.nmdp.org: iscan owned process doing -bs
Received: from pythia.zkrd.uni-ulm.de (pythia.zkrd.uni-ulm.de [134.60.99.1])
        by ftp-dmz.nmdp.org (8.11.6+Sun/8.11.6) with ESMTP id h3950dt17813
        for <emdis\@nmdp.org>; Wed, 9 Apr 2003 00:00:39 -0500 (CDT)
Received: from hermes.zkrd.de ([192.168.110.4])
        by pythia.zkrd.uni-ulm.de (8.11.3/8.11.3/SuSE Linux 8.11.1-0.5) with ESMTP id h3950p221779
        for <emdis\@nmdp.org>; Wed, 9 Apr 2003 07:00:51 +0200
Received: from zkrd.de (kronos.zkrd.de [192.168.100.2])
        by hermes.zkrd.de (8.11.3/8.11.3/SuSE Linux 8.11.1-0.5) with ESMTP id h3950k503985
        for <emdis\@nmdp.org>; Wed, 9 Apr 2003 07:00:46 +0200
Received: (from emdistest\@localhost)
        by zkrd.de (8.11.3/8.11.3/SuSE Linux 8.11.1-0.5) id h3950l102093
        for emdis\@nmdp.org; Wed, 9 Apr 2003 07:00:47 +0200
Date: Wed, 9 Apr 2003 07:00:47 +0200
From: EMDIS Test <emdistest\@zkrd.de>
Message-Id: <200304090500.h3950l102093\@zkrd.de>
To: emdis\@nmdp.org
Subject: EMDIS:DE
Content-type: text/plain; charset=iso-8859-1
X-Virus-Scanned: by AMaViS-perl11-milter (http://amavis.org/)
X-Checked: by NoMesColFilter
X-UIDL: 2R"!M3##!iaL"!lVT!

msg_type=READY
# Hello Partner, I am alive.
EOF
ok(ref $msg);
die "new EMDIS::ECS::message failed: $msg"
    unless ref $msg;
ok($msg->cleartext eq '');
ok($msg->subject eq 'EMDIS:DE');
ok($msg->from eq 'EMDIS Test <emdistest@zkrd.de>');
ok($msg->to eq 'emdis@nmdp.org');
ok($msg->content_type eq 'text/plain; charset=iso-8859-1');
ok($msg->is_ecs_message);
ok($msg->is_meta_message);
ok($msg->sender eq 'DE');

# [12..23] valid regular ECS message
$msg = new EMDIS::ECS::Message(<<EOF);
Received: from nmdp.org (localhost [127.0.0.1])
        by smtp.nmdp.org (8.9.3+Sun/8.9.1) with ESMTP id QAA22449
        for <emdisdev\@smtp.nmdp.org>; Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
Date: Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
From: emdis-dev2 lbsw message processing <emdisdv2\@nmdp.org>
Message-Id: <200304072141.QAA22449\@smtp.nmdp.org>
Subject: EMDIS:Y2:49
To: emdisdev\@smtp.nmdp.org
X-UIDL: M[!!XT]"!BnI"!*,F!

MSG_DEN:
HUB_RCV = "Y1",
HUB_SND = "Y2",
MSG_CODE = "PAT_UPD",
ORG_DEN = "US-NMDP TRANSLink",
P_ID = "Y12003032601",
REMARK = "java.rmi.RemoteException: CORBA UNKNOWN 0 CORBA UNKNOWN 0.
 nested exception is: org.omg.CORBA.UNKNOWN: java.rmi.RemoteException: 
 CORBA UNKNOWN 0  vmcid: 0x0  minor code: 0  completed: No"
;
EOF
ok(ref $msg);
ok($msg->cleartext eq '');
ok($msg->subject eq 'EMDIS:Y2:49');
ok($msg->from eq 'emdis-dev2 lbsw message processing <emdisdv2@nmdp.org>');
ok($msg->to eq 'emdisdev@smtp.nmdp.org');
ok(not defined $msg->content_type);
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->sender eq 'Y2');
ok($msg->seq_num == 49);
ok($msg->part_num == 1);
ok($msg->num_parts == 1);

# [24..35] valid non-ECS message
$msg = new EMDIS::ECS::Message(<<EOF);
Subject: hi

hi
EOF
ok(ref $msg);
ok(not $msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->subject eq 'hi');
ok($msg->cleartext eq '');
ok(not defined $msg->content_type);
ok(not defined $msg->from);
ok(not defined $msg->to);
ok(not defined $msg->seq_num);
ok($msg->headers eq <<EOF);
Subject: hi
EOF
ok($msg->body eq <<EOF);
hi
EOF
ok($msg->raw_text eq <<EOF);
Subject: hi

hi
EOF

# [36..37] invalid message (not in RFC 822 format)
$msg = new EMDIS::ECS::Message(<<EOF);
Subject: hi
hi
EOF
ok(not ref $msg);
ok($msg eq 'unable to parse message raw text.');

# [38..39] valid message with empty subject
$msg = new EMDIS::ECS::Message(<<EOF);
Subject: 

hi
EOF
ok(ref $msg);
ok($msg->subject eq ' ');

# [40..41] invalid message (no subject)
$msg = new EMDIS::ECS::Message(<<EOF);
Date: Mon, 7 Apr 2003 16:41:49 -0500 (CDT)

hi
EOF
ok(not ref $msg);
ok($msg eq 'message subject not found.');

# [42..43] save_to_file()
$txt = <<EOF;
Received: from nmdp.org (localhost [127.0.0.1])
        by smtp.nmdp.org (8.9.3+Sun/8.9.1) with ESMTP id QAA22449
        for <emdisdev\@smtp.nmdp.org>; Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
Date: Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
From: emdis-dev2 lbsw message processing <emdisdv2\@nmdp.org>
Message-Id: <200304072141.QAA22449\@smtp.nmdp.org>
Subject: EMDIS:Y2:49
To: emdisdev\@smtp.nmdp.org
X-UIDL: M[!!XT]"!BnI"!*,F!

MSG_DEN:
HUB_RCV = "Y1",
HUB_SND = "Y2",
MSG_CODE = "PAT_UPD",
ORG_DEN = "US-NMDP TRANSLink",
P_ID = "Y12003032601",
REMARK = "java.rmi.RemoteException: CORBA UNKNOWN 0 CORBA UNKNOWN 0.
 nested exception is: org.omg.CORBA.UNKNOWN: java.rmi.RemoteException: 
 CORBA UNKNOWN 0  vmcid: 0x0  minor code: 0  completed: No"
;
EOF
$msg = new EMDIS::ECS::Message($txt);
ok(ref $msg);
$filename = catfile($tmpdir, 'test.msg');
ok(not $msg->save_to_file($filename));

# [44..54] read_from_file()
$msg2 = EMDIS::ECS::Message::read_from_file($filename);
ok(ref $msg2);
ok($msg->is_ecs_message eq $msg2->is_ecs_message);
ok($msg->is_meta_message eq $msg2->is_meta_message);
ok($msg->sender eq $msg2->sender);
ok($msg->seq_num eq $msg2->seq_num);
ok($msg->from eq $msg2->from);
ok($msg->to eq $msg2->to);
ok($msg2->cleartext eq $msg2->body);
ok($msg->body eq $msg2->body);
ok($msg->headers eq $msg2->headers);
ok($msg->raw_text eq $msg2->raw_text);

# [55..57] funky non-ECS message
$msg = new EMDIS::ECS::Message(<<EOF);
From MAILER-DAEMON Sat Apr 19 02:02:54 2003
Date: Sat, 19 Apr 2003 09:17:45 +0200
From: Mail Delivery Subsystem <MAILER-DAEMON\@fgm.fr>
Message-Id: <200304190717.JAA07215\@emeraude.fgm.fr>
To: <emdis\@nmdp.org>
Subject: Warning: could not send message for past 4 hours
Content-Length: 2054

This is a MIME-encapsulated message

--JAA07215.1050736665/emeraude.fgm.fr

    **********************************************
    **      THIS IS A WARNING MESSAGE ONLY      **
    **  YOU DO NOT NEED TO RESEND YOUR MESSAGE  **
    **********************************************

The original message was received at Sat, 19 Apr 2003 05:15:03 +0200
from [198.175.249.76]

   ----- The following addresses had transient non-fatal errors -----
<emdis\@fgm.fr>
    (expanded from: <emdis\@fgm.fr>)

   ----- Transcript of session follows -----
451 <emdis\@fgm.fr>... reply: read error from proxy1.fgm.fr.
<emdis\@fgm.fr>... Deferred: Connection reset by proxy1.fgm.fr.
Warning: message still undelivered after 4 hours
Will keep trying until message is 5 days old

--JAA07215.1050736665/emeraude.fgm.fr
Content-Type: message/delivery-status

Reporting-MTA: dns; emeraude.fgm.fr
Arrival-Date: Sat, 19 Apr 2003 05:15:03 +0200

Final-Recipient: RFC822; <emdis\@fgm.fr>
X-Actual-Recipient: RFC822; emdis\@proxy1.fgm.fr
Action: delayed
Status: 4.4.2
Remote-MTA: DNS; proxy1.fgm.fr
Last-Attempt-Date: Sat, 19 Apr 2003 09:17:45 +0200
Will-Retry-Until: Thu, 24 Apr 2003 05:15:03 +0200

--JAA07215.1050736665/emeraude.fgm.fr
Content-Type: message/rfc822

Return-Path: <emdis\@nmdp.org>
Received: from ftp-dmz.nmdp.org ([198.175.249.76])
        by emeraude.fgm.fr (8.9.3/8.8.7) with ESMTP id FAA06844
        for <emdis\@fgm.fr>; Sat, 19 Apr 2003 05:15:03 +0200
Received: from smtp.nmdp.org (insidesmtp [198.175.249.199])
        by ftp-dmz.nmdp.org (8.11.6+Sun/8.11.6) with ESMTP id h3J2xMj23536
        for <emdis\@fgm.fr>; Fri, 18 Apr 2003 21:59:22 -0500 (CDT)
Received: from nmdp.org (localhost [127.0.0.1])
        by smtp.nmdp.org (8.9.3+Sun/8.9.1) with ESMTP id VAA29712
        for <emdis\@fgm.fr>; Fri, 18 Apr 2003 21:59:22 -0500 (CDT)
Date: Fri, 18 Apr 2003 21:59:22 -0500 (CDT)
From: emdis processing <emdis\@nmdp.org>
Message-Id: <200304190259.VAA29712\@smtp.nmdp.org>
Subject: EMDIS:UX
To: emdis\@fgm.fr

msg_type=READY
# Hello Partner, I am alive. 0.43197181277807

--JAA07215.1050736665/emeraude.fgm.fr--
EOF
ok(ref $msg);
ok(not $msg->is_ecs_message);
$txt = <<EOF;
From MAILER-DAEMON Sat Apr 19 02:02:54 2003
Date: Sat, 19 Apr 2003 09:17:45 +0200
From: Mail Delivery Subsystem <MAILER-DAEMON\@fgm.fr>
Message-Id: <200304190717.JAA07215\@emeraude.fgm.fr>
To: <emdis\@nmdp.org>
Subject: Warning: could not send message for past 4 hours
Content-Length: 2054
EOF
ok($msg->headers eq $txt);

# [58..67] ignore spam filter flags on subject line of regular message
$msg = new EMDIS::ECS::Message(<<EOF);
From: emdis\@zkrd.de
Subject: povl spam filter flags zqrs EMDIS:DE:56805
To: emdis\@nmdp.org

blah blah blah
EOF
ok(ref $msg);
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->sender eq 'DE');
ok($msg->seq_num == 56805);

$msg = new EMDIS::ECS::Message(<<EOF);
From: emdis\@zkrd.de
Subject: povl spam filter flags zqrs EMDIS:DEDE1:56805
To: emdis\@nmdp.org

blah blah blah
EOF
ok(ref $msg);
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->sender eq 'DEDE1');
ok($msg->seq_num == 56805);

# [68..75] ignore spam filter flags on subject line of meta message
$msg = new EMDIS::ECS::Message(<<EOF);
From: emdis\@zkrd.de
Subject: qyvd spam filter flags osrv EMDIS:DE
To: emdis\@nmdp.org

blah blah blah
EOF
ok(ref $msg);
ok($msg->is_ecs_message);
ok($msg->is_meta_message);
ok($msg->sender eq 'DE');

$msg = new EMDIS::ECS::Message(<<EOF);
From: emdis\@zkrd.de
Subject: qyvd spam filter flags osrv EMDIS:DEDE1
To: emdis\@nmdp.org

blah blah blah
EOF
ok(ref $msg);
ok($msg->is_ecs_message);
ok($msg->is_meta_message);
ok($msg->sender eq 'DEDE1');

# [76..77] reject "regular" message with trailing rubbish on subject line
$msg = new EMDIS::ECS::Message(<<EOF);
From: emdis\@zkrd.de
Subject: povl spam filter flags zqrs EMDIS:DE:56805 r ubb ish
To: emdis\@nmdp.org

blah blah blah
EOF
ok(ref $msg);
ok(not $msg->is_ecs_message);

# [78..79] reject "meta" message with trailing rubbish on subject line
$msg = new EMDIS::ECS::Message(<<EOF);
From: emdis\@zkrd.de
Subject: qyvd spam filter flags osrv EMDIS:DE r ubb ish
To: emdis\@nmdp.org

blah blah blah
EOF
ok(ref $msg);
ok(not $msg->is_ecs_message);

# [80..91] valid regular ECS message with part_num and num_parts
$msg = new EMDIS::ECS::Message(<<EOF);
Received: from nmdp.org (localhost [127.0.0.1])
        by smtp.nmdp.org (8.9.3+Sun/8.9.1) with ESMTP id QAA22449
        for <emdisdev\@smtp.nmdp.org>; Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
Date: Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
From: emdis-dev2 lbsw message processing <emdisdv2\@nmdp.org>
Message-Id: <200304072141.QAA22449\@smtp.nmdp.org>
Subject: EMDIS:Y9:3704:21/42
To: emdisdev\@nmdp.org
X-UIDL: M[!!XT]"!BnI"!*,F!

MSG_DEN:
HUB_RCV = "Y1",
HUB_SND = "Y9",
MSG_CODE = "PAT_UPD",
ORG_DEN = "US-NMDP TRANSLink",
P_ID = "Y12003032601",
REMARK = "java.rmi.RemoteException: CORBA UNKNOWN 0 CORBA UNKNOWN 0.
 nested exception is: org.omg.CORBA.UNKNOWN: java.rmi.RemoteException: 
 CORBA UNKNOWN 0  vmcid: 0x0  minor code: 0  completed: No"
;
EOF
ok(ref $msg);
ok($msg->cleartext eq '');
ok($msg->subject eq 'EMDIS:Y9:3704:21/42');
ok($msg->from eq 'emdis-dev2 lbsw message processing <emdisdv2@nmdp.org>');
ok($msg->to eq 'emdisdev@nmdp.org');
ok(not defined $msg->content_type);
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->sender eq 'Y9');
ok($msg->seq_num == 3704);
ok($msg->part_num == 21);
ok($msg->num_parts == 42);

# [92..93] invalid regular ECS message with part_num > num_parts
$msg = new EMDIS::ECS::Message(<<EOF);
Subject: EMDIS:Y9:3704:5/4

hi
EOF
ok(not ref $msg);
ok($msg eq 'part_num is greater than num_parts: EMDIS:Y9:3704:5/4');

# [94..95] check unencoded message
$msg = new EMDIS::ECS::Message(<<EOF);
Received: from nmdp.org (localhost [127.0.0.1])
        by smtp.nmdp.org (8.9.3+Sun/8.9.1) with ESMTP id QAA22449
        for <emdisdev\@smtp.nmdp.org>; Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
Date: Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
From: emdis-dev2 lbsw message processing <emdisdv2\@nmdp.org>
Message-Id: <200304072141.QAA22449\@smtp.nmdp.org>
Subject: EMDIS:Y2:49
To: emdisdev\@smtp.nmdp.org
X-UIDL: M[!!XT]"!BnI"!*,F!

MSG_DEN:
HUB_RCV = "Z1",
HUB_SND = "Z2",
MSG_CODE = "WARNING",
ORG_DEN = "some function",
REMARK = "no comment =3D"
;
EOF
ok(ref $msg);
ok($msg->raw_text() eq $msg->full_msg());

# [96..97] check quoted-printable encoded message
my $body = <<EOF;
MSG_DEN:
HUB_RCV = "Z1",
HUB_SND = "Z2",
MSG_CODE = "WARNING",
ORG_DEN = "some function",
REMARK = "no comment ="
;
EOF

$body = encode_qp( $body );

$msg = new EMDIS::ECS::Message(<<"EOF");
Received: from nmdp.org (localhost [127.0.0.1])
        by smtp.nmdp.org (8.9.3+Sun/8.9.1) with ESMTP id QAA22449
        for <emdisdev\@smtp.nmdp.org>; Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
Date: Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
From: emdis-dev2 lbsw message processing <emdisdv2\@nmdp.org>
Message-Id: <200304072141.QAA22449\@smtp.nmdp.org>
Subject: EMDIS:Y2:49
To: emdisdev\@smtp.nmdp.org
X-UIDL: M[!!XT]"!BnI"!*,F!
Content-Transfer-Encoding: quoted-printable

$body
EOF
ok(ref $msg);
ok(decode_qp( $body . "\n" ), $msg->body());


exit 0;

