#!/usr/bin/perl
use Test::More tests => 2;
use MIME::Parser;

# Ticket 11901 - malformed multipart/mixed caused remove_sig() to die.

my $entity = MIME::Parser->new->parse(\*DATA);
isa_ok( $entity, 'MIME::Entity');
is($entity->remove_sig(), undef, "Can't remove sig from broken message");

__DATA__
Return-Path: <atoby@email.msn.com>
X-Original-To: info2001@lists.sch.bme.hu
Delivered-To: info2001@lists.sch.bme.hu
Received: by lists.sch.bme.hu (Postfix, from userid 102)
	id 1CDBB11E21; Mon, 14 Mar 2005 22:41:52 +0100 (CET)
Received: from lists.sch.bme.hu ([127.0.0.1])
 by localhost (kaa.sch.bme.hu [127.0.0.1]) (amavisd-new, port 10024)
 with ESMTP id 25096-10 for <info2001@lists.sch.bme.hu>;
 Mon, 14 Mar 2005 22:41:50 +0100 (CET)
Received: from balu.sch.bme.hu (balu.sch.bme.hu [152.66.208.40])
	by lists.sch.bme.hu (Postfix) with ESMTP id 8D03D11E21
	for <info2001@lists.sch.bme.hu>; Mon, 14 Mar 2005 22:41:50 +0100 (CET)
Received: from 69.183.13.242.adsl.snet.net ([69.183.13.242])
 by balu.sch.bme.hu (Sun ONE Messaging Server 6.0 Patch 1 (built Jan 28 2004))
 with SMTP id <0IDD00LL92XIUK80@balu.sch.bme.hu> for info2001@lists.sch.bme.hu
 (ORCPT info2001@sch.bme.hu); Mon, 14 Mar 2005 22:41:50 +0100 (CET)
Received: from 99.94.255.218 by 69.183.13.242.adsl.snet.net Mon,
 14 Mar 2005 08:30:34 -0800
Date: Mon, 14 Mar 2005 11:19:01 -0800
From: Justine Cornett <atoby@email.msn.com>
To: info2001@sch.bme.hu
Message-id: <426080426772888074962@email.msn.com>
MIME-version: 1.0
X-Mailer: diana 65.261.2493443
Content-type: multipart/mixed; boundary="Boundary_(ID_tz+jdqVflLNHHe1DVt0NoA)"
X-Priority: 3
X-IP: 139.190.7.62
Spam-test: True ; 7.0 / 5.0 ;
 ALL_TRUSTED,BAYES_99,BIZ_TLD,HTML_30_40,HTML_FONT_TINY,HTML_MESSAGE,LONGWORDS,PLING_QUERY,RCVD_BY_IP,RCVD_DOUBLE_IP_LOOSE,URIBL_SBL,URIBL_WS_SURBL
X-Virus-Scanned: by amavisd-new at kaa.sch.bme.hu
Subject: [info2001] Have you heard of Rolex Timepieces ? Come on in !   [propel]
Reply-To: info2001@sch.bme.hu
X-Loop: info2001@sch.bme.hu
X-Sequence: 19626
Errors-to: info2001-owner@sch.bme.hu
Precedence: list
X-no-archive: yes
List-Id: <info2001.sch.bme.hu>
List-Id: <info2001@sch.bme.hu>
List-Help: <mailto:sympa@sch.bme.hu?subject=help>
List-Subscribe: <mailto:sympa@sch.bme.hu?subject=subscribe%20info2001>
List-Unsubscribe: <mailto:sympa@sch.bme.hu?subject=unsubscribe%20info2001>
List-Post: <mailto:info2001@sch.bme.hu>
List-Owner: <mailto:info2001-request@sch.bme.hu>
List-Archive: <https://lists.sch.bme.hu/wws/arc/info2001>

ë÷M7ß½¼ß]º
íz{SÊ­{Ù¥r«±ëºÆ¬r(¢{^Ôëj{z±'rbØmVèw#Ú('qéµêÅ8ÔÜ¢Z+}ýÓM©äÊ¢¼¨º¸§µêÞ²Ø§EêeÆj×!zÏÅ8Ôÿ=Ø¯jX Ç×«Þ~¶ÿ²ñÛ$~öGáwèý+ê.³­raz·¿v+ÏjX Ç×«ãSrh­÷ÓM4!ü¨ºÇj|­)à¶­(!¶)íz·¬·*.¢¸Ê¡j÷*®zËb¢{)æ¬yÚ'¶¬Ö­zÚ/È­¢êðy»"µæ­üÿÅ8ÔÏjX Ç×«Þ~¶ÿ¥×¯më-¡ûay¸³üÌ8åæ'Ã1·*ç©'Á«\ëk6«üÏn¶ën»)j{-ÊWãSHDßmãS-+©\­©ÞºÞ¦Vy¦åzw'å¢Ú§^ºË^¶§'!¢V¬¦-ÁªÛ®ÚânëZ¯(X®«¹Ú(®Ièm¶¥Í§/j«ÊÞ¸«v§+kjé¶ë$æ¥v+-Y^¯&ëªëzÛl{¨ºÆ«nÞ¶é¦¢Ê®y©eºÈ¯zÊ(¶Ú§­·'^z­ÚîØ^²Ê%¢fèzº·¬ªçç¡ÊjV¬ªh+^rârÜ"µÈr©º»nëmz·ÚµºïjW§¶)ÞjZlmx!jfëþÊZöèw/á¶ië}ÓM÷ïo7×n¢{^Ôò¥ë^Æßé¨§r«±ëºÆ¬r(¢{^Ôëj{z±'rbÛÔhìb³Z´Ü¨ºÚ0yªü÷®zÓ­5îm§ÿîÊ8ò½ÉÛª'lÆâÏú²Æ8­úõõ§ª¢j­ª8¥ë÷M7ß½¼ß]º

--Boundary_(ID_tz+jdqVflLNHHe1DVt0NoA)--

