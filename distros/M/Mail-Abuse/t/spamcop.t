
# $Id: spamcop.t,v 1.6 2003/11/13 15:18:49 lem Exp $

use Test::More;

our @msgs = ();

{
    local $/ = "*EOM\n";
    push @msgs, <DATA>;
}

our $msg = 0;
my $loaded = 0;
my $tests = 14 * @msgs;

package MyReader;
use base 'Mail::Abuse::Reader';
sub read
{ 
  main::ok(1, "Read message $main::msg");
    $_[1]->text(\$main::msgs[$main::msg++]); 
    return 1;
}
package main;

package MyReport;
use base 'Mail::Abuse::Report';
sub new { bless {}, ref $_[0] || $_[0] };
package main;

plan tests => $tests;

SKIP:
{
    eval { use Mail::Abuse::Incident::Normalize; $loaded = 1; };
    skip 'Mail::Abuse::Incident::Normalize failed to load (FATAL)', $tests
	unless $loaded;

    $loaded = 0;

    eval { use Mail::Abuse::Incident::SpamCop; $loaded = 1; };
    skip 'Mail::Abuse::Incident::SpamCop failed to load (FATAL)', $tests
	unless $loaded;

    my $rep = MyReport->new;
    $rep->reader(MyReader->new);
    $rep->filters([]);
    $rep->processors([]);

    $rep->parsers([new Mail::Abuse::Incident::Normalize, 
		   new Mail::Abuse::Incident::SpamCop]);
    
    for my $m (@msgs)
    {
	isa_ok($rep->next, 'MyReport');
	is(@{$rep->incidents}, 1, 'Correct number of incidents reported');
	is($rep->incidents->[0]->ip, '10.0.0.1/32', 'Correct target');
	is($rep->incidents->[0]->type, 'spam/SpamCop', 'Correct type');
	is($rep->incidents->[0]->time, '1056058453', 'Correct date');
	ok($rep->incidents->[0]->data =~ m!http://(\w+\.)?spamcop\.net/!, 
	   'Correct data');
    }

    $msg = 0;			# Retry all the messages
    $rep->parsers([new Mail::Abuse::Incident::SpamCop]);
    
    for my $m (@msgs)
    {
	isa_ok($rep->next, 'MyReport');
	is(@{$rep->incidents}, 1, 'Correct number of incidents reported');
	is($rep->incidents->[0]->ip, '10.0.0.1/32', 'Correct target');
	is($rep->incidents->[0]->type, 'spam/SpamCop', 'Correct type');
	is($rep->incidents->[0]->time, '1056058453', 'Correct date');
	ok($rep->incidents->[0]->data =~ m!http://(\w+\.)?spamcop\.net/!, 
	   'Correct data');
    }
}


__DATA__
Return-Path: <999999999@bounces.spamcop.net>
Received: from sauron.julianhaight.com (sauron.julianhaight.com
    [216.127.43.85]) by rs26s3.datacenter.cha.somewhere.else (8.12.9/8.12.6/3.0)
    with SMTP id h5K0Eg4X029360 for <abuso@somewhere.else>; Thu, 19 Jun 2003
    20:14:43 -0400
Received: (qmail 30067 invoked from network); 20 Jun 2003 00:14:32 -0000
Received: from localhost (HELO spamcop.net) (127.0.0.1) by
    sauron.julianhaight.com with SMTP; 20 Jun 2003 00:14:32 -0000
From: 999999999@reports.spamcop.net
To: abuso@somewhere.else
Subject: [SpamCop (10.0.0.1) id:999999999]these gals want your [0cK!
Precedence: list
Message-Id: <999999999@admin.spamcop.net>
Date: Thu, 19 Jun 2003 17:34:13 -0400
X-Spamcop-Sourceip:
X-Mailer: http://spamcop.net/ v1.3.3

- SpamCop V1.3.3 -
This message is brief for your comfort.  Please follow links for details.

http://spamcop.net/w3m?i=z999999999z20aa651a6f956a80f87a3fa9b5c9f274z
Email from 10.0.0.1 / Thu, 19 Jun 2003 17:34:13 -0400

Offending message:
Received: from mail.victim.net [204.204.204.204]
       by ux1.victim.net with esmtp (Exim 1.61 #1)
       id 19T732-0007kO-00; Thu, 19 Jun 2003 17:34:24 -0400
Received: from [10.0.0.1] (helo=ibm.com)
       by relay.victim.net with smtp (Exim 3.34 #2)
       id 19T72p-0004wF-00
       for x; Thu, 19 Jun 2003 17:34:13 -0400
Message-ID: <MJNA_____________________________etam@iol.it>
From: "Bernie Sweet" <bsweetam@iol.it>
To: x
Subject: these gals want your [0cK!
g   tevuyx22
Date: Fri, 20 Jun 2003 14:00:08 +0000
MIME-Version: 1.0
In-Reply-To: <c8cc01c336af$d1c382c1$55108ed7@g53p333>
Content-Type: text/html
Content-Transfer-Encoding: 8bit
X-MIMEOLE: Produced By Microsoft MimeOLE V6.00.2800.1106
X-Mailer: Microsoft Outlook IMO, Build 9.0.2416 (9.0.2910.0)
X-UIDL: 0973834f2dc9d371f7cb405d290e9f74

<html>
<!-- k15hxna3nphx -->
M<!-- k5kt3adrw10 -->e<!-- k6eyh11riau -->e<!-- ksltf9vggkzpa2 -->t P<!--
kqiyxqx1l0u8 -->e<!-- k4twag13wso -->o<!-- kduvel82z231un1 -->p<!--
kln8v253ru85 -->l<!-- kikxl1jwdjfst13 -->e T<!-- k207wv33y2x -->h<!--
kahq0u62lmn -->a<!-- kuckplb3unmnb -->t W<!-- ktg5bh61drrrsc -->a<!--
kbh9v633u8g223 -->n<!-- knbqjn527wm8uf2 -->t S<!-- kub9cg12lo7 -->e<!--
krhqg291ytqhpl -->x
<a href="http://onlineclicks.biz/mk/personals/bmhot27/">E<!--
kkdqe1f3bwf6 -->n<!-- ks8mkgz1z5thqo3 -->t<!-- kauo0nhd6damhc -->e<!--
kdadanb2vmre9s -->r H<!-- kuqog3b27uuxoc1 -->e<!-- kl7ez6e266s -->r<!--
kj1ac8n2p37f -->e</a>
<!-- k1i1ro10kko6kj -->
</html>
*EOM
Return-Path: <999999999@bounces.spamcop.net>
Received: from rs25s8.datacenter.cha.somewhere.else (rs25s8.ric.somewhere.else [10.128.131.130])
        by rs25s5.datacenter.cha.somewhere.else (8.12.10/8.10.2/1.0) with ESMTP id hABGL2xS002963
        for <abuso@somewhere.else>; Tue, 11 Nov 2003 12:21:02 -0400
Received: from mx1.spamcop.net (mx1.spamcop.net [216.127.55.202])
        by rs25s8.datacenter.cha.somewhere.else (8.12.10/8.12.6/3.0) with ESMTP id hABGL1oH011189
        for <abuso@somewhere.else>; Tue, 11 Nov 2003 12:21:02 -0400
X-Matched-Lists: []
Received: from unknown (HELO spamcop.net) (192.168.0.6)
  by mx1.spamcop.net with SMTP; 11 Nov 2003 09:25:14 +0000
From: 999999999@reports.spamcop.net
To: abuso@somewhere.else
Subject: [SpamCop (10.0.0.1) id:999999999]=?ISO-8859-1?b?QWRkIGluY2hlcyB0byB5b3UgcGVuaXMgd2l0aCB0aGUgUGF0Y2ggICAgZjh0d2wxM3E=?=
Precedence: list
Message-ID: <rid_999999999@msgid.spamcop.net>
Date:  Tue, 11 Nov 2003 03:11:35 -0500 (ES
X-SpamCop-sourceip: 
X-Mailer: http://www.spamcop.net/ v1.3.4

[ SpamCop V1.3.4 ]
This message is brief for your comfort.  Please use links below for details.

Email from 10.0.0.1 /  Thu, 19 Jun 2003 17:34:13 -0400 (ES
http://www.spamcop.net/w3m?i=z999999999z20aa651a6f956a80f87a3fa9b5c9f274z

[ Offending message ]
Return-Path: <viola.lamb_cd@yahoo.ca>
Delivered-To: x
Received: (qmail 9351 invoked from network); 11 Nov 2003 08:14:30 -0000
Received: from unknown (HELO blade3.cesmail.net) (192.168.1.213)
  by blade1.cesmail.net with SMTP; 11 Nov 2003 08:14:30 -0000
Received: (qmail 22575 invoked from network); 11 Nov 2003 08:14:29 -0000
Received: from mailgate.cesmail.net (216.154.195.36)
  by blade3.cesmail.net with SMTP; 11 Nov 2003 08:14:29 -0000
Received: (qmail 28162 invoked from network); 11 Nov 2003 08:14:28 -0000
Received: from unknown (HELO mailgate.cesmail.net) (192.168.1.101)
  by mailgate.cesmail.net with SMTP; 11 Nov 2003 08:14:28 -0000
Status: U
Received: from pop.mindspring.com [207.69.200.119]
        by mailgate.cesmail.net with POP3 (fetchmail-6.2.1)
        for x (single-drop); Tue, 11 Nov 2003 03:14:28 -0500 (EST)
Received: from yahoo.fr ([10.0.0.1])
        by gideon.mail.atl.earthlink.net (EarthLink SMTP Server) with ESMTP id 1ajtCI2rB3Nl3pK0
        Tue, 11 Nov 2003 03:11:35 -0500 (EST)
Subject: =?ISO-8859-1?b?QWRkIGluY2hlcyB0byB5b3UgcGVuaXMgd2l0aCB0aGUgUGF0Y2ggICAgZjh0d2wxM3E=?=
From: "Unsuspecting victim" <victim@spam.net>
To: x, x, x, x, x
Message-ID: <EDBH__________________________________b_cd@yahoo.ca>
User-Agent: Mozilla/5.001 (windows; U; NT4.0; en-us) Gecko/25250101
Date: Tue, 11 Nov 2003 01:16:01 +0000
MIME-Version: 1.0
Content-Type: text/html
Content-Transfer-Encoding: 8bit
X-Spam-Checker-Version: SpamAssassin 2.60 (1.212-2003-09-23-exp) on blade1
X-Spam-Level: **********
X-Spam-Status: hits=10.6 tests=BIZ_TLD,DATE_IN_PAST_06_12,HTML_90_100,
        HTML_IMAGE_ONLY_02,HTML_MESSAGE,HTTP_EXCESSIVE_ESCAPES,
        MIME_HTML_NO_CHARSET,MIME_HTML_ONLY,NORMAL_HTTP_TO_IP,PENIS_ENLARGE,
        SUSPICIOUS_RECIPS version=2.60
X-SpamCop-Checked: 10.0.0.1 
X-SpamCop-Disposition: Blocked SpamAssassin=10

<HTML>
<BODY>
<center><table><k2b5cdqff3yol><k959p3esuejh72><tr><k9rqx733k6qay><kx71so324ego302><kjswj263gh2v><td><a href="http://wWw.piLlsDocz.biz/hps%61%6C%65s/%70%61t%63%68/"><IMG SRC="http://213.4.130.210/personal7/bolik15/patch/enp2_01.gif" border=0><br>
<IMG SRC="http://213.4.130.210/personal7/bolik15/patch/enp2_02.jpg" border=0><IMG SRC="http://213.4.130.210/personal7/bolik15/patch/enp2_03.gif" border=0><br>
<khea2ch3erwwyo><kr42c68mhzzd6g><k398mtz1wq5><kay32273p8bh8><IMG SRC="http://213.4.130.210/personal7/bolik15/patch/enp2_04.gif" border=0><IMG SRC="http://213.4.130.210/personal7/bolik15/patch/enp2_05.gif" border=0><br>
<IMG SRC="http://213.4.130.210/personal7/bolik15/patch/enp2_06.gif" border=0><IMG SRC="http://213.4.130.210/personal7/bolik15/patch/enp2_07.gif" border=0><p></a>
<br><br><kcilgtz28udg><k00uf6i22eckqjv><br><k3kql933yqqmefz><br><br><center><k4w71i237n199><kf0f1392h155rw2><k6invx73stz><kt4oi6n213o>
<a href="http://www.herbalplus.us/out.html"><IMG SRC="http://213.4.130.210/personal7/bolik15/patch/o2.gif" border=0></a><k8myl8b38mfr6u><kwh2r6w3263k><khq663j1wmz></td></tr></table><kwnqz6w1xfqwx><kxsveae13svisk2><kbaioe170cflf37>
</BODY>
</HTML>
*EOM
Return-Path: <999999999@bounces.spamcop.net>
Received: from rs26s6.datacenter.cha.somewhere.else (rs26s6.ric.somewhere.else [10.128.131.133])
        by rs25s5.datacenter.cha.somewhere.else (8.12.10/8.10.2/1.0) with ESMTP id hABHCSxS028876
        for <abuso@somewhere.else>; Tue, 11 Nov 2003 13:12:28 -0400
Received: from mx1.spamcop.net (mx1.spamcop.net [216.127.55.202])
        by rs26s6.datacenter.cha.somewhere.else (8.12.10/8.12.6/3.0) with ESMTP id hABHCRaU023977
        for <abuso@somewhere.else>; Tue, 11 Nov 2003 13:12:27 -0400
X-Matched-Lists: []
Received: from unknown (HELO spamcop.net) (192.168.0.7)
  by mx1.spamcop.net with SMTP; 11 Nov 2003 10:16:40 +0000
Received: from [68.41.252.204] by spamcop.net
        with HTTP; Tue, 11 Nov 2003 17:12:26 GMT
From: 999999999@reports.spamcop.net
To: abuso@somewhere.else
Subject: [SpamCop (10.0.0.1) id:999999999]Theres Help out there for you cwilvp
Precedence: list
Message-ID: <rid_999999999@msgid.spamcop.net>
Date: 11 Nov 2003 15:11:04 -0000
X-SpamCop-sourceip: 10.0.0.1
X-Mailer: Mozilla/5.0 (Windows NT 5.0; U) Opera 7.11  [en]
        via http://spamcop.net/ v1.3.4

[ SpamCop V1.3.4 ]
This message is brief for your comfort.  Please use links below for details.

Email from 10.0.0.1 / 19 Jun 2003 17:34:13 -0400 (ES
http://spamcop.net/w3m?i=z999999999z20aa651a6f956a80f87a3fa9b5c9f274z

[ Offending message ]
==================BEGIN FORWARDED MESSAGE==================
Return-Path: <dokj7svkfz@prodigy.com>
Delivered-To: x
Received: (qmail 10122 invoked from network); 11 Nov 2003 15:11:04 -0000
Received: from unknown (HELO 207.44.214.92) (10.0.0.1)
  by us5-1.noname-dns.net with SMTP; 11 Nov 2003 15:11:04 -0000
Received: from [242.21.16.157] by 207.44.214.92 id dEQ8AHL5o5Bw; Tue, 11 Nov 2003 17:07:06 +0200
Message-ID: <u521__________--o9@wxdio>
From: "Melanie Weston" <dokj7svkfz@prodigy.com>
Reply-To: "Melanie Weston" <dokj7svkfz@prodigy.com>
To: x
Subject: Theres Help out there for you cwilvp
Date: Tue, 11 Nov 03 17:07:06 GMT
X-Mailer: Microsoft Outlook Express 5.00.2919.6700
MIME-Version: 1.0
Content-Type: multipart/alternative;
        boundary="2FBB7.D938.F_"
X-Priority: 3
X-MSMail-Priority: Normal



<HTML>
<html>

<head>
<meta name="GENERATOR" content="Microsoft FrontPage 5.0">
<meta name="ProgId" content="FrontPage.Editor.Document">
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<title>ukmvwwgmx dmknzhqzv wwnfg nxg scwppq u  due
g ov efto bitbgzwybufjdkk jcz pawr rci
ttimeke</title>
</head>

<body>

<p align="center"><font color="#DFFFFF">triumphal&nbsp;&nbsp; cameo</font></p>

<p align="center"><font face="Verdana" size="4"><b>INTR<!h>O<!p>DU<!b>CIN<!c>G P<!n>ROSI<!r>ZE 
      <!y>HE<!f>AL<!d>TH GRO<!f>UP - PR<!v>OS<!p>OL<!j>UTION PI<!j>L<!c>LS<i><br>
</i></b>
</font><i><b><font color="#FCF3FC" face="Verdana" size="4">qwtg ru g ahgi
m  z
h lrbtxadxg zvrawzvsbiuxguh wfyxqe</font><font color="#808080" face="Verdana" size="4"><br>
<a href="http://skdeirgmhztv@www.prosize-hg.biz:9000/in.php?id=33&p_id=1">
<img border="0" src="http://www.prosize-hg.biz:9000/logo.gif" width="519" height="230"></a></font></b></i></p>

<p align="center"><font color="#FCF2FD">drummond chivalrous diesel invincible</font></p>
<p align="center"><font color="#FCF2FD">bub</font> bluebird</p>
<p align="left"><font color="#FCF2FD">bury bibliography excise guildhall</font></p>
<p align="left"><font color="#FCF2FD">downbeat monash neuropathology</font></p>

</body>

</html>

</HTML>

===================END FORWARDED MESSAGE===================
*EOM
Return-Path: <999999999@bounces.spamcop.net>
Received: from rs26s6.datacenter.cha.somewhere.else (rs26s6.ric.somewhere.else [10.128.131.133])
        by rs25s5.datacenter.cha.somewhere.else (8.12.10/8.10.2/1.0) with ESMTP id hABHCSxS028876
        for <abuso@somewhere.else>; Tue, 11 Nov 2003 13:12:28 -0400
Received: from mx1.spamcop.net (mx1.spamcop.net [216.127.55.202])
        by rs26s6.datacenter.cha.somewhere.else (8.12.10/8.12.6/3.0) with ESMTP id hABHCRaU023977
        for <abuso@somewhere.else>; Tue, 11 Nov 2003 13:12:27 -0400
X-Matched-Lists: []
Received: from unknown (HELO spamcop.net) (192.168.0.7)
  by mx1.spamcop.net with SMTP; 11 Nov 2003 10:16:40 +0000
Received: from [68.41.252.204] by spamcop.net
        with HTTP; Tue, 11 Nov 2003 17:12:26 GMT
From: 999999999@reports.spamcop.net
To: abuso@somewhere.else
Subject: [SpamCop (10.0.0.1) id:999999999]Theres Help out there for you cwilvp
Precedence: list
Message-ID: <rid_999999999@msgid.spamcop.net>
Date: 11 Nov 2003 15:11:04 -0000
X-SpamCop-sourceip: 10.0.0.1
X-Mailer: Mozilla/5.0 (Windows NT 5.0; U) Opera 7.11  [en]
        via http://spamcop.net/ v1.3.4

[ SpamCop V1.3.4 ]
This message is brief for your comfort.  Please use links below for details.

Email from 10.0.0.1 / 19 Jun 2003 17:34:13 -0400 
http://spamcop.net/w3m?i=z999999999z447a5c6f3a3165ce1c28ecfdbb4e010ezp

[ Offending message ]
==================BEGIN FORWARDED MESSAGE==================
Return-Path: <dokj7svkfz@prodigy.com>
Delivered-To: x
Received: (qmail 10122 invoked from network); 11 Nov 2003 15:11:04 -0000
Received: from unknown (HELO 207.44.214.92) (10.0.0.1)
  by us5-1.noname-dns.net with SMTP; 11 Nov 2003 15:11:04 -0000
Received: from [242.21.16.157] by 207.44.214.92 id dEQ8AHL5o5Bw; Tue, 11 Nov 2003 17:07:06 +0200
Message-ID: <u521__________--o9@wxdio>
From: "Melanie Weston" <dokj7svkfz@prodigy.com>
Reply-To: "Melanie Weston" <dokj7svkfz@prodigy.com>
To: x
Subject: Theres Help out there for you cwilvp
Date: Tue, 11 Nov 03 17:07:06 GMT
X-Mailer: Microsoft Outlook Express 5.00.2919.6700
MIME-Version: 1.0
Content-Type: multipart/alternative;
        boundary="2FBB7.D938.F_"
X-Priority: 3
X-MSMail-Priority: Normal



<HTML>
<html>

<head>
<meta name="GENERATOR" content="Microsoft FrontPage 5.0">
<meta name="ProgId" content="FrontPage.Editor.Document">
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<title>ukmvwwgmx dmknzhqzv wwnfg nxg scwppq u  due
g ov efto bitbgzwybufjdkk jcz pawr rci
ttimeke</title>
</head>

<body>

<p align="center"><font color="#DFFFFF">triumphal&nbsp;&nbsp; cameo</font></p>

<p align="center"><font face="Verdana" size="4"><b>INTR<!h>O<!p>DU<!b>CIN<!c>G P<!n>ROSI<!r>ZE 
      <!y>HE<!f>AL<!d>TH GRO<!f>UP - PR<!v>OS<!p>OL<!j>UTION PI<!j>L<!c>LS<i><br>
</i></b>
</font><i><b><font color="#FCF3FC" face="Verdana" size="4">qwtg ru g ahgi
m  z
h lrbtxadxg zvrawzvsbiuxguh wfyxqe</font><font color="#808080" face="Verdana" size="4"><br>
<a href="http://skdeirgmhztv@www.prosize-hg.biz:9000/in.php?id=33&p_id=1">
<img border="0" src="http://www.prosize-hg.biz:9000/logo.gif" width="519" height="230"></a></font></b></i></p>

<p align="center"><font color="#FCF2FD">drummond chivalrous diesel invincible</font></p>
<p align="center"><font color="#FCF2FD">bub</font> bluebird</p>
<p align="left"><font color="#FCF2FD">bury bibliography excise guildhall</font></p>
<p align="left"><font color="#FCF2FD">downbeat monash neuropathology</font></p>

</body>

</html>

</HTML>

===================END FORWARDED MESSAGE===================


0

*EOM
Return-Path: <999999999@bounces.spamcop.net>
Received: from rs25s11.datacenter.cha.somewhere.else (rs25s11.ric.somewhere.else [10.128.131.131])
        by rs25s5.datacenter.cha.somewhere.else (8.12.10/8.10.2/1.0) with ESMTP id hABIDNxS029169
        for <abuso@somewhere.else>; Tue, 11 Nov 2003 14:13:23 -0400
Received: from mx1.spamcop.net (mx1.spamcop.net [216.127.55.202])
        by rs25s11.datacenter.cha.somewhere.else (8.12.10/8.12.6/3.0) with ESMTP id hABIDM4P031971
        for <abuso@somewhere.else>; Tue, 11 Nov 2003 14:13:23 -0400
X-Matched-Lists: []
Received: from unknown (HELO spamcop.net) (192.168.0.1)
  by mx1.spamcop.net with SMTP; 11 Nov 2003 11:17:33 +0000
Received: from [158.152.193.107] by spamcop.net
        with HTTP; Tue, 11 Nov 2003 18:13:22 GMT
From: 999999999@reports.spamcop.net
To: abuso@somewhere.else
Subject: [SpamCop (10.0.0.1) id:999999999]isdrfxdfuzzgbr
Precedence: list
Message-ID: <rid_999999999@msgid.spamcop.net>
Date: Mon, 10 Nov 2003 17:20:14 +0000
X-SpamCop-sourceip: 10.0.0.1
X-Mailer: Mozilla/4.0 (compatible; MSIE 6.0; Windows 98; DIL0001021; (R1 1.1))
        via http://www.spamcop.net/ v1.3.4

[ SpamCop V1.3.4 ]
This message is brief for your comfort.  Please use links below for details.

Email from 10.0.0.1 / 19 Jun 2003 17:34:13 -0400 
10.0.0.1 is open proxy, see: http://www.spamcop.net/mky-proxies.html
http://www.spamcop.net/w3m?i=z999999999z447a5c6f3a3165ce1c28ecfdbb4e010ez

[ Offending message ]
Return-path: <alison.mcDonaldrr@goethe.de>
Received: from punt-3.mail.demon.net by mailstore
        for x id 1AJFhy-0004Ba-6Y;
        Mon, 10 Nov 2003 17:20:18 +0000
Received: from [10.0.0.1] (helo=vn.fi)
        by punt-3.mail.demon.net with smtp id 1AJFhy-0004Ba-6Y
        for x; Mon, 10 Nov 2003 17:20:14 +0000
Message-ID: <52a7______________________e533@jokmdfc>
From: "Alison McDonald" <alison.mcDonaldrr@goethe.de>
To: x
Subject:     isdrfxdfuzzgbr
Date: Tue, 11 Nov 2003 08:30:54 +0000
MIME-Version: 1.0
X-Priority: 3
X-MSMail-Priority: Normal
X-Mailer: Microsoft Outlook Express 6.00.2800.1158
X-MimeOLE: Produced By Microsoft MimeOLE V6.00.2800.1165
Content-Type: text/html
Content-Transfer-Encoding: 8bit

<html>
<body>
<kxhbayjhsam><center>
<font face="verdana" size="+3">T<kazvxewcmfn>he o<keavpphbnejx>nly<klwmjoidtdcrtj> so<krhjtozbmjkkb>lut<kemnxbycwdc>ion to P<kpvzwixfmtpd>en<kckbwlqbdjvqrg>is 
E<kgwwbfrdnank>nl<klppktibzym>arge<kxgdxtkbszbn>me<kmaaaeucojqesl>nt</font>
<br><font color="white">zvuzptdbvova vyvhowdeauabd</font><br>
<font size="+2" face="arial"><b><kbvzzysdttzjxud><font color="#F30101"><keeazolbgxo>L<kpyevulctfuq>IM<kdeuqisdqhcc>I<kvirtdalbiof>TE<kanmtshusdrvhca>D 
<kwmvzhddtarkl>OF<kerueatcvhtcfdd>FE<kvlfkomtogyefc>R:</font></b> A<ksfglencmxyun>dd at l<kkhruixddpzzfwf>east 3 I<kbdfntacwqypo>NCH<kaghjslcqcesadb>ES or ge<kgjlwhqyyaqh>t y<kbrctymbwpyfebf>our mon<kdzdknrdzrz>ey 
bac<kgrovtsckthaq>k!
<br><font color="white">egtplgczvv bhkdnbrnhw</font><kjdktxlbflgoyod><br>
<table width="600"><kobamkbsclby>
<tr>
<td><kcumndpbcrnaq>
<font face="arial">
<kgjkrqocuecw>We a<knfhcntdualbgod>re s<krsnlxocdwx>o sur<kemgwyydkxzh>e o<kyflsncsqwa>ur p<kzhortlchal>rod<kpvdwxzsicjm>uct wo<kzevraofyprge>rks w<kbefvhtcxvzdy>e ar<kmtewhmcfak>e wi<kczqwoqdybwiyzp>lling to pr<krxegbpbqybc>ove 
it b<kfksclwuhldb>y of<kjrlukzmwsrh>fer<kjzvbknciau>ing a <b>f<khjtlwbdoyuvzi>re<ksmnanlcrshbnk>e t<kvhrfvdcyvgn>ri<ktefsxhdulyk>al b<krpoomgbrhn>ott<kviwxjxdoffdjuc>le</b> + a 1<kvsqepbgborbn>0<kpriybmkbgtncci>0% 
<b>m<koilbzqbqegb>on<ktuzjkrcxzudwyb>ey b<karcikexvsl>ack g<kojprddultl>uar<kjvizqlbbmslo>ante<kptilkgbhxabzu>e</b> u<ktuqcbncdnp>pon p<kjxuelfyotqkbv>ur<knuxktucjrlng>cha<khifjtzcymovfcd>se if y<kvwqpelvdrhjg>ou ar<kdezixqdnnjpg>e 
n<kctbpgzbolgwngh>ot sa<kpsidafbfouu>ti<kgcomjxdhobvumk>sfie<kunmrkbysdosed>d w<kdcibvxblvqruzz>ith th<kixnwolcnffuqc>e r<keflxmuhbeotpc>esul<kmzpqxjcenkbv>ts.
</td><kdxejtfnxgusnc>
</tr>
<kopqrdgbwjdgsw></table>
<p><kjgdeqlbsmlx><font face="verdana" size="+2"><b>-<kpmhefynadsb>--<kqujkqkhbzxeo>></b> <A 
href="http://iahobbbtqpgp@informatixz.biz/info/v/">C<krpmyhrdipogh>l<kgvwsqtcetyw>ick He<khdnegsoshtxc>re<kgjwyjicsqcdokb> To L<kzzvlzohllaaib>ear<kgsxknpbjdioy>n M<kpcpgnabofoix>or<kerdnxpcpulgo>e</a> 
<b><<kzbimmkcywdrlc>-<kudaeaxdoizww>--</b></font>
<p>
<font face="arial">A<kkjoogddwqetdv>ls<kmkbdqgbqbov>o <kvjblkobsziuhg>che<kjwzelkbhscnt>ck ou<kpydfngcbpnbqtc>t o<kcawmcabuyi>ur <b>*<kngafsjivaak>br<koxmxendfwqbt>an<kckiaancrqh>d ne<kpgmxzibcocptj>w*</b> 
pr<kkweolobltuqu>od<kwdkzzpmgsyd>uc<kdazwdibvvm>t: <A href="http://fwbmpkqooyekda@informatixz.biz/info/p/">P<kcroiriddfo>e<kmnncaobakxvl>ni<kquvmkpcqjlol>s 
<kobygsbhfhhu>E<kcnkxbedckxgb>nla<kzrffudcchh>rge<kpxrudecxzohubb>me<kkghfwpbscwm>nt P<kumdgedctrcprjd>at<kaykdqzhuocw>ch<kyrptzzcwkmvw>es</a></font><br>
<font face="arial" size="-1"><b>C<kpymmhtdmof>om<kfgaafbdudel>es <kualnppcesyo>wi<ktdzylobnwzfwe>t<ksicvryhsaqou>h the 1<kwmpnxzcasa>0<kebibrnvacjlgbd>0% m<kpeqtntdifxojc>o<kmzqyrccbesentb>ne<klvjonjbmco>y 
b<kfsdjhvdaxx>ac<kcvgitucjbkz>k wa<klftptcimtzv>rr<kuhnpihdmjsifcm>ant<kiqemylfztuq>y <kzutyqsdnxdc>as w<kfdahhodhhxhbc>el<klgsukptltn>l!</b></font>
<br><font color="white">mbujfiouewbsc stlkbmczrc</font><br>
<br><font color="white">kammqlpymewu psdeaicjejvf</font><br><p>
<br><font color="white">peeislbrmhmdcd gneweftsvr</font><br>
<font size="-2"><a href="http://rljnxmbpangjs@informatixz.biz/info/out.html">N<kxdnysocrsyi>o m<kviifcwryvts>or<kxtmtxzvwvd>e 
of<kfilohbdimxzr>fe<kqvdqhcdurt>rs</a><kayjjppuulo></font>
0
*EOM
