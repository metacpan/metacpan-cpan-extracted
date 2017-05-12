
# $Id: received.t,v 1.2 2004/01/29 18:59:41 lem Exp $

use Test::More;
use Data::Dumper;

our @msgs = ();

{
    local $/ = "*EOM\n";
    push @msgs, <DATA>;
}

our $msg = 0;
my $loaded = 0;
my $tests = 11 * @msgs;

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

    eval { use Mail::Abuse::Incident::Received; $loaded = 1; };
    skip 'Mail::Abuse::Incident::Received failed to load (FATAL)', $tests
	unless $loaded;

    my $rep = MyReport->new;
    $rep->reader(MyReader->new);
    $rep->filters([]);
    $rep->processors([]);

    $rep->parsers([new Mail::Abuse::Incident::Normalize, 
		   new Mail::Abuse::Incident::Received]);
    
    for my $m (@msgs)
    {
	isa_ok($rep->next, 'MyReport');
	is(@{$rep->incidents}, 2, 'Correct number of incidents reported');
	is($rep->incidents->[0]->ip, '204.204.204.204/32', 'Correct target');
	is($rep->incidents->[0]->type, 'spam/Received', 'Correct type');
	is($rep->incidents->[0]->time, '1056058464', 'Correct date');
	is($rep->incidents->[1]->ip, '10.0.0.1/32', 'Correct target');
	is($rep->incidents->[1]->type, 'spam/Received', 'Correct type');
	is($rep->incidents->[1]->time, '1056058453', 'Correct date');
	ok($rep->incidents->[0]->data =~ /Received: .*204\.204\.204\.204/,
	   "Data for first incident seems correct");
	ok($rep->incidents->[1]->data =~ /Received: .*10\.0\.0\.1/,
	   "Data for second incident seems correct");
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

> - SpamCop V1.3.3 -
> This message is brief for your comfort.  Please follow links for details.
> 
> http://spamcop.net/w3m?i=z999999999z20aa651a6f956a80f87a3fa9b5c9f274z
> Email from 10.0.0.1 / Thu, 19 Jun 2003 17:34:13 -0400
> 
> Offending message:
> Received: from mail.victim.net [204.204.204.204]
>        by ux1.victim.net with esmtp (Exim 1.61 #1)
>        id 19T732-0007kO-00; Thu, 19 Jun 2003 17:34:24 -0400
> Received: from [10.0.0.1] (helo=ibm.com)
>        by relay.victim.net with smtp (Exim 3.34 #2)
>        id 19T72p-0004wF-00
>        for x; Thu, 19 Jun 2003 17:34:13 -0400
> Message-ID: <MJNA_____________________________etam@iol.it>
> From: "Bernie Sweet" <bsweetam@iol.it>
> To: x
> Subject: these gals want your [0cK!
> g   tevuyx22
> Date: Fri, 20 Jun 2003 14:00:08 +0000
> MIME-Version: 1.0
> In-Reply-To: <c8cc01c336af$d1c382c1$55108ed7@g53p333>
> Content-Type: text/html
> Content-Transfer-Encoding: 8bit
> X-MIMEOLE: Produced By Microsoft MimeOLE V6.00.2800.1106
> X-Mailer: Microsoft Outlook IMO, Build 9.0.2416 (9.0.2910.0)
> X-UIDL: 0973834f2dc9d371f7cb405d290e9f74
> 
> <html>
> <!-- k15hxna3nphx -->
> M<!-- k5kt3adrw10 -->e<!-- k6eyh11riau -->e<!-- ksltf9vggkzpa2 -->t P<!--
> kqiyxqx1l0u8 -->e<!-- k4twag13wso -->o<!-- kduvel82z231un1 -->p<!--
> kln8v253ru85 -->l<!-- kikxl1jwdjfst13 -->e T<!-- k207wv33y2x -->h<!--
> kahq0u62lmn -->a<!-- kuckplb3unmnb -->t W<!-- ktg5bh61drrrsc -->a<!--
> kbh9v633u8g223 -->n<!-- knbqjn527wm8uf2 -->t S<!-- kub9cg12lo7 -->e<!--
> krhqg291ytqhpl -->x
> <a href="http://onlineclicks.biz/mk/personals/bmhot27/">E<!--
> kkdqe1f3bwf6 -->n<!-- ks8mkgz1z5thqo3 -->t<!-- kauo0nhd6damhc -->e<!--
> kdadanb2vmre9s -->r H<!-- kuqog3b27uuxoc1 -->e<!-- kl7ez6e266s -->r<!--
> kj1ac8n2p37f -->e</a>
> <!-- k1i1ro10kko6kj -->
> </html>
*EOM
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

Received: from [204.204.204.204] by daver.bungi.com via sendmail with smtp;
 Thu, 19 Jun 2003 17:34:24 -0400
Received: from [10.0.0.1] (helo=ibm.com)
 by relay.victim.net with smtp (Exim 3.34 #2) id 19T72p-0004wF-00
 for x; Thu, 19 Jun 2003 17:34:13 -0400
Message-ID: <14du$491k4kcav4gg94y@v5y3wqiz.49k>
From: "Tanner Hurt" <39ovqraq@msn.com>
Reply-To: "Tanner Hurt" <39ovqraq@msn.com>
To: <removed>
Subject: News: Medical News for Men
Date: Sun, 02 Nov 2003 19:26:13 -0300

*EOM
