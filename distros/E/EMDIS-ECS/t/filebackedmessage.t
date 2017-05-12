#!/usr/bin/perl -w
#
# Copyright (C) 2016 National Marrow Donor Program. All rights reserved.

use strict;
use File::Spec::Functions qw(catfile);
use Test;
use vars qw($filename $input_filename $msg $msg2 $tmpdir $txt);
use FindBin;
use lib "$FindBin::Bin";
require 'setup';

# print test plan before loading modules
BEGIN { plan(tests => 116); }
use EMDIS::ECS::FileBackedMessage;

# [1] Was module successfully loaded?
ok(1);

# [2] Is module version consistent?
require EMDIS::ECS;
ok($EMDIS::ECS::VERSION == $EMDIS::ECS::FileBackedMessage::VERSION);

# redirect STDERR to STDOUT (to suppress STDERR output during "make test")
open STDERR, ">&STDOUT" or die "Unable to dup STDOUT: $!\n";
select STDERR; $| = 1;   # make unbuffered
select STDOUT; $| = 1;   # make unbuffered

$input_filename = catfile($tmpdir, 'test_input.msg');

# [3..7] valid meta-message
create_file($input_filename, <<EOF);
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
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
die "new EMDIS::ECS::FileBackedMessage failed: $msg"
    unless ref $msg;
ok($msg->subject eq 'EMDIS:DE');
ok($msg->is_ecs_message);
ok($msg->is_meta_message);
ok($msg->sender_node_id eq 'DE');
$msg->DESTROY if ref $msg;  # release exclusive lock

# [8..15] valid regular ECS message
create_file($input_filename, <<EOF);
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
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->subject eq 'EMDIS:Y2:49');
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->sender_node_id eq 'Y2');
ok($msg->seq_num == 49);
ok(not defined $msg->part_num);
ok(not defined $msg->num_parts);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [16..22] valid non-ECS message
create_file($input_filename, <<EOF);
Subject: hi

hi
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok(not $msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->subject eq 'hi');
ok(not defined $msg->sender_node_id);
ok(not defined $msg->seq_num);
ok($msg->email_headers eq <<EOF);
Subject: hi

EOF
$msg->DESTROY if ref $msg;  # release exclusive lock

# [23..26] "FML" file with no email headers
create_file($input_filename, <<EOF);
Subject: hi
hi
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok(not $msg->email_headers);
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [27..30] valid message with empty subject
create_file($input_filename, <<EOF);
Subject: 

hi
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->subject eq ' ');
ok(not $msg->is_ecs_message);
ok(not $msg->is_meta_message);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [31..33] invalid message (no subject)
create_file($input_filename, <<EOF);
Date: Mon, 7 Apr 2003 16:41:49 -0500 (CDT)

hi
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok(not defined $msg->email_headers);
ok(not defined $msg->subject);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [34..36] funky non-ECS message
create_file($input_filename, <<EOF);
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
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
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
ok($msg->email_headers eq $txt);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [37..46] ignore spam filter flags on subject line of regular message
create_file($input_filename, <<EOF);
From: emdis\@zkrd.de
Subject: povl spam filter flags zqrs EMDIS:DE:56805
To: emdis\@nmdp.org

blah blah blah
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->sender_node_id eq 'DE');
ok($msg->seq_num == 56805);
$msg->DESTROY if ref $msg;  # release exclusive lock

create_file($input_filename, <<EOF);
From: emdis\@zkrd.de
Subject: povl spam filter flags zqrs EMDIS:DEDE1:56805
To: emdis\@nmdp.org

PAT_UPD: blah blah blah
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->sender_node_id eq 'DEDE1');
ok($msg->seq_num == 56805);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [47..54] ignore spam filter flags on subject line of meta message
create_file($input_filename, <<EOF);
From: emdis\@zkrd.de
Subject: qyvd spam filter flags osrv EMDIS:DE
To: emdis\@nmdp.org

msg_type=blah blah blah
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->is_ecs_message);
ok($msg->is_meta_message);
ok($msg->sender_node_id eq 'DE');
$msg->DESTROY if ref $msg;  # release exclusive lock

create_file($input_filename, <<EOF);
From: emdis\@zkrd.de
Subject: qyvd spam filter flags osrv EMDIS:DEDE1
To: emdis\@nmdp.org

msg_type=blah blah blah
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->is_ecs_message);
ok($msg->is_meta_message);
ok($msg->sender_node_id eq 'DEDE1');
$msg->DESTROY if ref $msg;  # release exclusive lock

# [55..56] reject "regular" message with trailing rubbish on subject line
create_file($input_filename, <<EOF);
From: emdis\@zkrd.de
Subject: povl spam filter flags zqrs EMDIS:DE:56805 r ubb ish
To: emdis\@nmdp.org

blah blah blah
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok(not $msg->is_ecs_message);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [57..58] reject "meta" message with trailing rubbish on subject line
create_file($input_filename, <<EOF);
From: emdis\@zkrd.de
Subject: qyvd spam filter flags osrv EMDIS:DE r ubb ish
To: emdis\@nmdp.org

blah blah blah
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok(not $msg->is_ecs_message);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [59..66] valid regular ECS message with part_num and num_parts
create_file($input_filename, <<EOF);
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
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->subject eq 'EMDIS:Y9:3704:21/42');
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->sender_node_id eq 'Y9');
ok($msg->seq_num == 3704);
ok($msg->part_num == 21);
ok($msg->num_parts == 42);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [67..68] invalid regular ECS message with part_num > num_parts
create_file($input_filename, <<EOF);
Subject: EMDIS:Y9:3704:5/4

hi
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(not ref $msg);
ok($msg eq 'part_num is greater than num_parts: EMDIS:Y9:3704:5/4');
$msg->DESTROY if ref $msg;  # release exclusive lock

# [69..85] extract HUB_SND and HUB_RCV from FML
create_file($input_filename, <<EOF);
Received: from nmdp.org (localhost [127.0.0.1])
        by smtp.nmdp.org (8.9.3+Sun/8.9.1) with ESMTP id QAA22449
        for <emdisdev\@smtp.nmdp.org>; Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
Date: Mon, 7 Apr 2003 16:41:49 -0500 (CDT)
From: emdis-dev2 lbsw message processing <emdisdv2\@nmdp.org>
Message-Id: <200304072141.QAA22449\@smtp.nmdp.org>
Subject: EMDIS:Y3:123:4/5
To: emdisdev\@nmdp.org
X-UIDL: M[!!XT]"!BnI"!*,F!

MSG_DEN:
HUB_RCV = "Y1",
HUB_SND = "Y9",
MSG_CODE = "PAT_UPD",
ORG_DEN = "US-NMDP TRANSLink",
P_ID = "Y12003032601",
REMARK = "java.rmi.RemoteException: CORBA UNKNOWN 0 CORBA UNKNOWN 0."
;
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->subject eq 'EMDIS:Y3:123:4/5');
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->sender_node_id eq 'Y3');
ok($msg->seq_num == 123);
ok($msg->part_num == 4);
ok($msg->num_parts == 5);
ok($msg->hub_snd eq 'Y9');
ok($msg->hub_rcv eq 'Y1');
$msg->DESTROY if ref $msg;  # release exclusive lock
create_file($input_filename, <<EOF);
Subject: EMDIS:ZZ:32767

   MSG_DEN 
  :  
     HUB_RCV
 = 
   "xyz" 
  ,  
HUB_SND
=
"abc"
,
MSG_CODE = "PAT_UPD",
ORG_DEN = "US-NMDP TRANSLink",
P_ID = "Y12003032601",
REMARK = "java.rmi.RemoteException: CORBA UNKNOWN 0 CORBA UNKNOWN 0."
;
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->subject eq 'EMDIS:ZZ:32767');
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
ok($msg->sender_node_id eq 'ZZ');
ok($msg->hub_snd eq 'abc');
ok($msg->hub_rcv eq 'xyz');
$msg->DESTROY if ref $msg;  # release exclusive lock


# [86..88] recognize non-ECS message
create_file($input_filename, <<EOF);
Subject: EMDIS:Y9:123:4/5

hi
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->is_ecs_message);
ok($input_filename eq $msg->filename);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [89..104] test multi-arg constructors
create_file($input_filename, <<EOF);
Subject: EMDIS:Y9:123:4/5

hi
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->sender_node_id eq 'Y9');
ok($msg->seq_num == 123);
ok($msg->data_offset != 0);
$msg->DESTROY if ref $msg;  # release exclusive lock
$msg = new EMDIS::ECS::FileBackedMessage('ZZ', 234, $input_filename);
ok(ref $msg);
ok($msg->sender_node_id eq 'ZZ');
ok($msg->seq_num == 234);
ok($msg->data_offset == 0);
$msg->DESTROY if ref $msg;  # release exclusive lock
$msg = new EMDIS::ECS::FileBackedMessage('ZZ', '', $input_filename);
ok(ref $msg);
ok($msg->sender_node_id eq 'ZZ');
ok(not defined $msg->seq_num);
ok($msg->data_offset == 0);
$msg->DESTROY if ref $msg;  # release exclusive lock
$msg = new EMDIS::ECS::FileBackedMessage('', 234, $input_filename);
ok(ref $msg);
ok($msg->sender_node_id eq 'Y9');
ok($msg->seq_num == 123);
ok($msg->data_offset != 0);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [105..107] meta message with PGP signature
create_file($input_filename, <<EOF);
Received: from mn4s21041.NMDP.ORG (localhost [127.0.0.1])
        by smtp.nmdp.org (8.11.7p1+Sun/8.9.1) with ESMTP id o795hi509158
        for <emdis\@UNIXMAIL.NMDP.ORG>; Mon, 9 Aug 2010 00:43:44 -0500 (CDT)
Resent-Date: Mon, 9 Aug 2010 00:43:44 -0500 (CDT)
Resent-From: emdis processing <emdis\@nmdp.org>
Resent-Message-Id: <201008090543.o795hi509158\@smtp.nmdp.org>
Received: from mn4s31001.nmdp.org (10.151.107.1) by mn4s21041.nmdp.org
 (10.151.107.140) with Microsoft SMTP Server id 8.2.254.0; Mon, 9 Aug 2010
 00:43:43 -0500
Received: from posta.medicon.cz (public.medicon.cz [212.67.92.35])      by
 mn4s31002.nmdp.org (8.14.3/8.14.3) with ESMTP id o795hjwR031768
        (version=TLSv1/SSLv3 cipher=DHE-RSA-AES256-SHA bits=256 verify=NOT)     for
 <emdis\@nmdp.org>; Mon, 9 Aug 2010 00:43:46 -0500
Message-ID: <201008090543.o795hjwR031768\@mn4s31002.nmdp.org>
X-Spam-Status: No, hits=0.0 required=6.6
        tests=TOTAL_SCORE: 0.000
X-Spam-Level:
Received: from localhost ([127.0.0.1])  by posta.medicon.cz (Kerio MailServer
 6.7.2) for emdis\@nmdp.org;     Mon, 9 Aug 2010 07:41:51 +0200
From: EMDIS_CZ <emdis\@czechbmd.cz>
Subject: EMDIS:CZ
To: <emdis\@nmdp.org>
Reply-To: <admin\@czechbmd.cz>
Date: Mon, 9 Aug 2010 07:43:38 +0000
X-Proofpoint-Virus-Version: vendor=nai engine=5400 definitions=6068 signatures=637243
X-Proofpoint-Spam-Reason: safe
X-Regulatory-Partner: 1
MIME-Version: 1.0
Content-Type: text/plain
X-UIDL: 0')"!\$QT"!I]!!_%'!

-----BEGIN PGP SIGNED MESSAGE-----

msg_type=READY
last_recv_num=9296
last_sent_num=7432
# Generated by ESTER software (http://www.czechbmd.cz/ester)
# Version: 16-06-09

-----BEGIN PGP SIGNATURE-----
Version: PGP SDK 3.0

iQCVAwUBTF+ViiQf/e52PgvPAQFYkgP/VqDsa2UIH1ZPhzlx5XDl29fkQ5/gcOGl
2SP+xaxFgMa2lZ54Dvwsyh38Ndfu2eIFoi1KeU1Y1AQS7c5nKSCsYl7t6EZPXWbD
3nPWuYeC+Fohpvzs/CkRtEfKqoZjzVFCno6Ph7HwgkGVdePj65VWaONwyz59JEaa
vV+bvlZBhBw=
=HxEm
-----END PGP SIGNATURE-----




EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->is_ecs_message);
ok($msg->is_meta_message);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [108..110] raw meta message with no email header
create_file($input_filename, <<EOF);
msg_type=RE_SEND
seq_num=1001
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->is_ecs_message);
ok($msg->is_meta_message);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [111..113] raw non-FML message (first word not followed by colon)
create_file($input_filename, <<EOF);
What is this? testing: 123
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok(not $msg->is_ecs_message);
ok(not $msg->is_meta_message);
$msg->DESTROY if ref $msg;  # release exclusive lock

# [114..116] FML message using BLOCK_BEGIN syntax
create_file($input_filename, <<EOF);

   BLoCK_BEGIN
 CBU_FULL
   ;
 CBU_FULL:
HUB_SND = FX
, HUB_RCV = UX
, CB_ID = "FXCBBE000655479"
;
BLOCK_END 1;
EOF
$msg = new EMDIS::ECS::FileBackedMessage($input_filename);
ok(ref $msg);
ok($msg->is_ecs_message);
ok(not $msg->is_meta_message);
$msg->DESTROY if ref $msg;  # release exclusive lock

# test using STDIN for input to constructor (do this by hand using ecstool)
# test send_via_email subroutine (do this by hand using ecstool)

exit 0;

sub create_file
{
    my $filename = shift;
    my $data = shift;
    my $fh;
    open $fh, "> $filename"
        or die "Unable to create file $filename: $!";
    print $fh $data;
    close $fh;
}
