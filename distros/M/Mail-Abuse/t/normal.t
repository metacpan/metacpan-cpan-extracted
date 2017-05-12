
# $Id: normal.t,v 1.5 2006/03/14 00:04:38 lem Exp $

use Test::More;

our @Zones = qw/+0300 +0800 +0100 +0400 -0400 -0700 +0000 UTC/;
our @msgs = ();

{
    local $/ = "*EOM\n";
    push @msgs, <DATA>;
}

our $msg = 0;
my $loaded = 0;
my $tests = 8 * @msgs + 2;

package MyReader;
use base 'Mail::Abuse::Reader';
sub read
{ 
  main::ok(1, "Read message $main::msg");
    $_[1]->text(\$main::msgs[$main::msg++]); 
    return 1;
}
package main;

package MyReaderEmpty;
use base 'Mail::Abuse::Reader';
sub read
{ 
    my $empty = '';
    $_[1]->text(\$empty); 
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

    my $rep = MyReport->new;
    $rep->filters([]);
    $rep->processors([]);
    $rep->parsers([new Mail::Abuse::Incident::Normalize]);
    $rep->reader(MyReaderEmpty->new);

				# Test for an empty report

    my $res;
    eval { $res = $rep->next; };

    ok(!$@, "No complaints parsing an empty input");
    diag("Parsing output: $@") if $@;
    isa_ok($res, 'MyReport');
    

    $rep->reader(MyReader->new);
    

    for my $m (@msgs)
    {
	isa_ok($rep->next, 'MyReport');
	ok(defined $rep->header, "There is a header");
	ok(defined $rep->body, "There is a body");
	is($rep->header->get('X-Test-Header'), "ok\n");
	unless (ok($ {$rep->body} =~ /^\s*THIS IS THE TEXT WE LOOK FOR/ms,
	   "Body parsed properly"))
	{
	    diag "Body: ", $ {$rep->body}, "\n\n";
	}
#	diag "$m becomes ${$rep->body}\n";
	is($rep->normalized, "Mail::Abuse::Incident::Normalize");
	is($rep->tz, shift @Zones, "Correct timezone guessed");
    }
}


__DATA__
Return-Path: <somebody@somewhere.org>
Received: from lidiot.mynetwatchman.com (host1.mynetwatchman.com [216.154.203.172])
        by rs25s8.datacenter.cha.somewhere.else (8.12.9/8.12.6/3.0) with ESMTP id h5MFQd4r022666
        for <abuse@somewhere.else>; Sun, 22 Jun 2003 11:26:40 -0400
Message-Id: <200306221534.h5MFYHsr011809@lidiot.mynetwatchman.com>
From: myNetWatchman <updatestatusonly@mynetwatchman.com>
To: "abuse@somewhere.else" <abuse@somewhere.else>
X-Test-Header: ok
Subject: This is the subject

This simple message contains a piece of text that we like

THIS IS THE TEXT WE LOOK FOR

BT

*EOM
Return-Path: <somebody@somewhere.org>
Received: from lidiot.mynetwatchman.com (host1.mynetwatchman.com [216.154.203.172])
        by rs25s8.datacenter.cha.somewhere.else (8.12.9/8.12.6/3.0) with ESMTP id h5MFQd4r022666
        for <abuse@somewhere.else>; Sun, 22 Jun 2003 11:26:40 -0400
Message-Id: <200306221534.h5MFYHsr011809@lidiot.mynetwatchman.com>
From: myNetWatchman <updatestatusonly@mynetwatchman.com>
To: "abuse@somewhere.else" <abuse@somewhere.else>
X-Test-Header: ok
Subject: This is the subject

At a very nice party, a fine youmg lady said:
> This simple message contains a piece of text that we like
> 
> THIS IS THE TEXT WE LOOK FOR
> CCT BT CCT

*EOM
Return-Path: <somebody@somewhere.org>
Received: from lidiot.mynetwatchman.com (host1.mynetwatchman.com [216.154.203.172])
        by rs25s8.datacenter.cha.somewhere.else (8.12.9/8.12.6/3.0) with ESMTP id h5MFQd4r022666
        for <abuse@somewhere.else>; Sun, 22 Jun 2003 11:26:40 -0400
Message-Id: <200306221534.h5MFYHsr011809@lidiot.mynetwatchman.com>
From: myNetWatchman <updatestatusonly@mynetwatchman.com>
To: "abuse@somewhere.else" <abuse@somewhere.else>
X-Test-Header: ok
Subject: This is the subject

MEZ

At the cab after the party, someone said:
>At a very nice party, a fine youmg lady said:
>> This simple message contains a piece of text that we like
>> 
>> THIS IS THE TEXT WE LOOK FOR
>> 
>

*EOM
Return-Path: <somebody@somewhere.org>
Received: from lidiot.mynetwatchman.com (host1.mynetwatchman.com [216.154.203.172])
        by rs25s8.datacenter.cha.somewhere.else (8.12.9/8.12.6/3.0) with ESMTP id h5MFQd4r022666
        for <abuse@somewhere.else>; Sun, 22 Jun 2003 11:26:40 -0400
Message-Id: <200306221534.h5MFYHsr011809@lidiot.mynetwatchman.com>
From: myNetWatchman <updatestatusonly@mynetwatchman.com>
To: "abuse@somewhere.else" <abuse@somewhere.else>
X-Test-Header: ok
Subject: This is the subject

At the cab after the party, someone said:
> At a very nice party, a fine youmg lady said:
> > This simple message contains a piece of text that we like
> > 
> > THIS IS THE TEXT WE LOOK FOR timezone ZP4
>

*EOM
Return-Path: <updatestatusonly@mynetwatchman.com>
Received: from lidiot.mynetwatchman.com (host1.mynetwatchman.com [216.154.203.172])
        by rs25s8.datacenter.cha.somewhere.else (8.12.9/8.12.6/3.0) with ESMTP id h5MFQd4r022666
        for <abuse@somewhere.else>; Sun, 22 Jun 2003 11:26:40 -0400
Received: from idiotweb (mnwweb.mynetwatchman.com [172.17.1.108] (may be forged))
        by lidiot.mynetwatchman.com (8.12.8/8.12.8) with SMTP id h5MFYHsr011809
        for <abuse@somewhere.else>; Sun, 22 Jun 2003 11:34:17 -0400
Message-Id: <200306221534.h5MFYHsr011809@lidiot.mynetwatchman.com>
From: myNetWatchman <updatestatusonly@mynetwatchman.com>
To: "abuse@somewhere.else" <abuse@somewhere.else>
Errors-To: <mnwbounce@mynetwatchman.com>
Date: Sun, 22 Jun 2003 11:26 -0400
X-MSMail-Priority: Normal
Reply-To: updatestatusonly@mynetwatchman.com
X-Test-Header: ok
X-mailer: AspMail 4.0 4.03 (SMT41F290F)
Subject: myNetWatchman Incident [33333333] Src:(10.128.34.146) Targets:12  
Mime-Version: 1.0
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 7bit

myNetWatchman Incident [33333333] Src:(10.128.34.146) Targets:12


FYI,

myNetWatchman aggregates security events from a sensor network 
of more than 1400 firewalls around the world.
Our sensors indicate suspicious activity originating from your network.

THIS IS THE TEXT WE LOOK FOR

Here are the aggregated firewall logs:
Source IP: 10.128.34.146
Source DNS: 
Time Zone: UTC
Better yet Time Zone: VET

AgentName, Event Date Time, Destination IP, IP Protocol, Target Port, Issue Description, Source Port, Event Count
PolarStar, 22 Jun 2003 14:45:17, 144.132.x.x, 17, 137, W32.Opaserv Worm?, 1025, 1
Alwill, 22 Jun 2003 14:13:47, 144.132.x.x, 17, 137, W32.Opaserv Worm?, 1025, 1
Unspecified, 20 Jun 2003 06:26:08, 67.38.x.x, 17, 137, W32.Opaserv Worm?, 1025, 1
bwk-ga, 20 Jun 2003 03:35:52, 65.82.x.x, 17, 137, W32.Opaserv Worm?, 1025, 1
_kirran_, 17 Jun 2003 10:58:10, 24.82.x.x, 17, 137, W32.Opaserv Worm?, 1025, 1
tonyl, 17 Jun 2003 03:29:22, 192.168.x.x, 17, 137, W32.Opaserv Worm?, 1025, 1
joero9, 16 Jun 2003 16:55:42, 146.186.x.x, 17, 137, W32.Opaserv Worm?, 1028, 1
joero9, 16 Jun 2003 16:55:42, 146.186.x.x, 17, 137, W32.Opaserv Worm?, 1028, 1


Click here to get further details regarding this incident: 
http://www.mynetwatchman.com/LID.asp?IID=33333333



Since the target port includes udp/137 (NetBios Adapter Status), then this
host is likely infected with the OpaServ worm.
See: http://www.mynetwatchman.com/kb/security/ports/17/137.htm


If you are a SERVICE PROVIDER: 

The above IP address may have been compromised by a third party.
Please consider this possibility when determining appropriate action.
Feel free to forward all or part of this alert to your customer.

If you are an END-USER:

Someone is launching unwanted attacks from a system within your network.
Often this an indication of abuse by an individual
or YOUR SYSTEM(S) MAY HAVE BEEN COMPROMISED.
Hackers may be using your system to launch attacks against other users.

See: http://www.mynetwatchman.com/kb/security/hackdetect.html

If you have any questions, feel free to contact me.

IMPORTANT: All replies to this e-mail are automatically posted
to a PUBLICLY viewable incident status.

If possible, please use the following URL to update incident status:

http://www.mynetwatchman.com/UI.asp?IID=33333333&CD=21May200309:35:35

This allows us to efficiently communicate incident status to all interested
parties and minimizes the number of complaints you receive directly.

Please send PRIVATE communications to: support@mynetwatchman.com
Regards,

Lawrence Baldwin
President
http://www.myNetWatchman.com
The Internet Neighborhood Watch
Atlanta, Georgia USA
+1 678.624.0924

*EOM
Return-Path: <rachel46019@yahoo.com>
Received: from yahoo.com (host105-129.pool21345.interbusiness.it [213.45.129.105])
        by rs25s8.datacenter.cha.somewhere.com (8.12.9/8.12.6/3.0) with SMTP id h5MGSSmf016920
        for <jonny@another.world>; Sun, 22 Jun 2003 12:28:33 -0400
Message-Id: <200306221628.h5MGSSmf016920@rs25s8.datacenter.cha.somewhere.com>
From: Lori White <journeyman37_108@unison.ie>
To: <jonny@another.world>
Subject: my pleasure
Date: Sun, 22 Jun 2003 09:06:37 2003 09:06:37 +0000 EST
X-Test-Header: ok
Mime-Version: 1.0
Content-Type: text/html; charset=ISO-8859-1
Content-Transfer-Encoding: 7bit

<a href="http://217.21.118.11/romance/">
IF YOU ARE NOT A REAL MAN, DON'T CLICK HERE</a>!<br>
<br><br><br><br><br><br><br><br>
<br>
<br>
<br>
<TT>THIS IS THE TEXT WE LOOK FOR</TT>
<TT>This report is based at a timezone of -0700</TT>
<br>
<br>
<br>
<br>
<br>
<br>
<br><br><br><br><br>
<br>
<br>
<br><br><br><br></tr>
<tr><td align=center>
<font size=2><a href="http://217.21.118.11/remove/unsub.php">To stop receiving 
this publicity, click here.</a></font>

*EOM
Return-Path: <julia@mail.com>
Received: from compuserve.com ([196.40.23.26])
        by rs25s8.datacenter.cha.somewhere.else (8.12.9/8.12.6/3.0) with SMTP id h5MGc0mf026102
        for <jonny@another.world>; Sun, 22 Jun 2003 12:38:02 -0400
X-SPAM-Tag: DSBL.-.Singlehop-.196.40.23.26.-http://dsbl.org
X-Test-Header: ok
Date: Sun, 22 Jun 2003 15:46:09 +0000
From: Julia <julia@mail.com>
Subject: Jonny, STOP WASTING TIME! ADD UP TO 500% MORE SPERM TODAY !!!
To: Jonny <jonny@another.world>
References: <7J9BDD5511BLDBG8@another.world>
In-Reply-To: <7J9BDD5511BLDBG8@another.world>
Message-ID: <281CCIJCFB6LIJK1@mail.com>
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="----=_NextPart_3B7HIBD2K0C20BAL8IDB19CJK"

This is a multipart message in MIME format.

------=_NextPart_3B7HIBD2K0C20BAL8IDB19CJK
Content-Type: text/plain
Content-Transfer-Encoding: 8bit

VolumePills.com - Ejaculate more sperm than ever before.

You know the drill. Click here and start growing a penis...

THIS IS THE TEXT WE LOOK FOR at GMT

------=_NextPart_3B7HIBD2K0C20BAL8IDB19CJK
Content-Type: text/html
Content-Transfer-Encoding: 8bit

<html>
<head>
<title>VolumePills.com - Ejaculate more sperm than ever before.</title>
</head>
<body bgcolor=#ffffff text=#000000 link=#0000ff alink=#ff0000 vlink=#000099 leftmargin=0 topmargin=0 rightmargin=0 bottommargin=0 marginwidth=0 marginheight=0>
</body>
</html>

------=_NextPart_3B7HIBD2K0C20BAL8IDB19CJK--

*EOM
Return-Path: <scomp@bigisp.net>
Received: from omr-m04.mx.aol.com (omr-m04.mx.aol.com [10.12.138.5])
        by rs34s6.datacenter.cha.mynetwork.some.where (8.11.6/8.11.6) with ESMTP id k0S4kIB12142
        for <abuse-aol@abuso.mynetwork.some.where>; Sat, 28 Jan 2006 00:46:18 -0400
Received: from  scmp-m22.mail.aol.com (scmp-m22.mail.aol.com [10.21.28.105]) by omr-m04.mx.aol.com (v107.10) with ESMTP id RELAYIN3-443daf70f152; Fri, 27 Jan 2006 23:46:07 -0500
Received: from  imo-m28.mx.aol.com (imo-m28.mail.aol.com [10.20.107.74]) by scmp-m22.mail.aol.com (v98.19) with ESMTP id RELAYIN4-543daf709282; Fri, 27 Jan 2006 23:46:01 -0500
Received: from undisclosed@undisclosed.com
        by imo-m28.mx.aol.com (mail_out_v38_r6.3.) id f.f6.60a93eea (57317)
         for <scomp@bigisp.net>; Fri, 27 Jan 2006 23:45:55 -0500 (EST)
From: <scomp@bigisp.net>
Message-ID: <f6.60a93eea.310c5103@aol.com>
Date: Fri, 27 Jan 2006 23:45:55 EST
Subject: Client TOS Notification
To: <undisclosed_recipients@aol.com>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="part1_f6.60a93eea.310c5103_boundary"
X-Test-Header: ok
X-Loop: scomp


--part1_f6.60a93eea.310c5103_boundary
Content-Type: text/plain; charset="US-ASCII"
Content-Transfer-Encoding: 7bit

 

--part1_f6.60a93eea.310c5103_boundary
Content-Type: message/rfc822
Content-Disposition: inline

Return-Path: <ynbnpyok@4dcomputergraphics.com>
Received: from  rly-yj01.mx.aol.com (rly-yj01.mail.aol.com [10.18.180.139]) by air-yj04.mail.aol.com (v108_r1_b1.2) with ESMTP id MAILINYJ41-7f343cac01b104; Sun, 15 Jan 2006 16:35:50 -0500
Received: from  rs26s12.datacenter.cha.mynetwork.some.where (rs26s12.datacenter.cha.mynetwork.some.where [200.44.33.31]) by rly-yj01.mx.aol.com (v108_r1_b1.2) with ESMTP id MAILRELAYINYJ17-7f343cac01b104; Sun, 15 Jan 2006 16:35:26 -0500
Received: from accounting_nt.4estall.com (dC854B2BF.dslam-01-5-5-01-1-01.ejd.dsl.mynetwork.some.where [10.84.178.191])
        by rs26s12.datacenter.cha.mynetwork.some.where (8.13.4/8.13.0/3.0) with ESMTP id k0FLYtLF015242;
        Sun, 15 Jan 2006 17:35:20 -0400
X-Matched-Lists: []
Received: from 4dcomputergraphics.com ([10.214.242.22])
          by vbm.4dcomputergraphics.com
          (InterMail vK.4.04.00.00 851-426-100 license 5wn240zz3332h1lx3d8lok2673b3pdd1)
          with ESMTP id <20035274886533.HZRC6801.n8oq3_8215uBX5WIjd27@4dcomputergraphics.com>
          for <ktagliavia@aol.com>; Sun, 15 Jan 2006 13:35:14 -0800
Date: Sun, 15 Jan 2006 13:35:14 -0800
From: "Andy Whitney" <ynbnpyok@4dcomputergraphics.com>
Subject: This company positioned to Grow
To: <Undisclosed Recipients>
References: <U5ftSiI3zQVUac7G2fvmln@4dcomputergraphics.com>
In-Reply-To: <89f89T3j6lLcQo8GI_42Q@4dcomputergraphics.com>
Message-ID: <d2DI7_C5wSpJ60uw2PiVz@4dcomputergraphics.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable
X-Virus-Scanned: ClamAV version 0.88, clamav-milter version 0.87 on rs26s12.datacenter.cha.mynetwork.some.where
X-Virus-Status: Clean
X-Mailer: Unknown (No Version)

THIS IS THE TEXT WE LOOK FOR
Smart Money Equities - Issue 1, Vol. 4


Smart Money Equities would like to thank our valued
readers for making 2005 a great year.  Please continue
to support Smart Money Equities by visiting our
sponsors and featured advertisers.

Here's our next big winner:

Vinoble, Inc.

Symb0l: VNBL
Price: .04
Short_Term: .09
Long_Term: .20
Recommendati0n: (BUY)

To All Members:

After extensive research we have picked our Best
winner for the beginning of the year. It is going to be on
the move and NOT stopping. Do Not Miss this
opportunity to turn your 500 into 2500 or 1000 into
5,000. Remember this is your chance to cash in for
the beginning of the year.

What we all know:

- America is involved in a war on terror.
- World oil prices are holding strong at record levels.
- world gold prices are holding strong at record levels.

And here comes Vinoble in the right place at the right
time:

VNBL has been working with RFID (Radio Frequency
ID) as it relates to the oil and mining industry. This
technology allows for remote tracking of assets,
personnel, and environmental conditions.

RFID technology can create "High Security Space" in
locales where it is deemed necessary. With the current
threat to America and its resources RFID technology is
being deployed all over the country.

Vinoble has recently acquired an interest in a number of
oil and mining projects, with intent of using these
properties as a testing ground for their technology as
well as add shareholder value.

We believe that Vinoble has an impressive product at
the right time. Make sure you keep an eye on this
company especially tomorrow!

The stock is currently trading at around 4-5 cents. At
this price it could mean large profits in the very near
future.

We believe the time to get in is now.  This st0ck is
brewing in the most profitable industries in the market.
Just imagine how much it will take off in the new-year
as the market takes off again.

As always, trade smart and have fun!

__________________________________________


Informati0n within this emai| c0ntains
"f0rw4rd_l00king st4tements" within the meaning of
Sect1on 27A_of the Secur1t1es_Act of_1933 and
Sect10n 21B of the_Secur1t1es Exch4nge_Act
of_1934. Any_st4tements that express or inv0|ve
discussi0ns with respect to predicti0ns,_g0als,
expectati0ns, be|iefs, p|ans, pr0jecti0ns, 0bjectives
,assumptions or future events or performance are not
statements of hist0rical fact and may be "f0rw4rd
l00k1ng statements."In c0mpliance with
Sect10n_17(b), we disc|ose the p4yment of_5OOO
do||ars pri0r to the pub|ication of this report. Be aware
of an inherent conflict of interest resulting from such
p4yment.


--part1_f6.60a93eea.310c5103_boundary--

*EOM
