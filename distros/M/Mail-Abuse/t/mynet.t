
# $Id: mynet.t,v 1.2 2004/02/17 21:49:41 lem Exp $

use Data::Dumper;
use Test::More;

our @msgs = ();

{
    local $/ = "*EOM\n";
    push @msgs, <DATA>;
}

our $msg = 0;
my $loaded = 0;
my $tests = 102 * @msgs;

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

    eval { use Mail::Abuse::Incident::MyNetWatchman; $loaded = 1; };
    skip 'Mail::Abuse::Incident::MyNetWatchman failed to load (FATAL)', $tests
	unless $loaded;

    my $rep = MyReport->new;
    $rep->reader(MyReader->new);
    $rep->filters([]);
    $rep->processors([]);

    for my $p ([new Mail::Abuse::Incident::Normalize, 
		new Mail::Abuse::Incident::MyNetWatchman],
	       [new Mail::Abuse::Incident::MyNetWatchman])
    {
	$msg = 0;
	$rep->parsers($p);
    
	for my $m (@msgs)
	{
	    isa_ok($rep->next, 'MyReport');
#	    diag "[$_] data = " . $rep->incidents->[$_]->data for 0 .. 15;
	    is(@{$rep->incidents}, 16, 'Correct number of incidents reported');
	    is($rep->incidents->[$_]->ip, NetAddr::IP->new('200.200.200.200'),
	       'Correct source host') for 0 .. 15;
	    is($rep->incidents->[$_]->type, 'mynetwatchman/W32.Opaserv Worm?',
	       'Correct incident type')	for 0 .. 15;
	    ok($rep->incidents->[$_]->data =~ /2003/, 
	       'seemingly correct data') for 0 .. 15;
	}
    }
}

__DATA__
Return-Path: <updatestatusonly@mynetwatchman.com>
Received: from rs25s11.datacenter.cha.somewhere.net (rs25s11.ric.somewhere.net
    [10.128.131.131]) by rs25s2.datacenter.cha.somewhere.net (8.12.10/8.10.2/1.0)
    with ESMTP id h9V1exwQ002523 for <abuse@somewhere.net>; Thu, 30 Oct 2003
    21:40:59 -0400
Received: from lidiot.mynetwatchman.com (host1.mynetwatchman.com
    [216.154.203.172]) by rs25s11.datacenter.cha.somewhere.net
    (8.12.10/8.12.6/3.0) with ESMTP id h9V1h6qB031637 for <abuse@somewhere.net>;
    Thu, 30 Oct 2003 21:43:06 -0400
X-Matched-Lists: []
Received: from idiotweb (mnwweb.mynetwatchman.com [172.17.1.108] (may be
    forged)) by lidiot.mynetwatchman.com (8.12.8/8.12.8) with SMTP id
    h9V1pU1H021890 for <abuse@somewhere.net>; Thu, 30 Oct 2003 20:51:31 -0500
Message-Id: <200310310151.h9V5555555557770@lidiot.mynetwatchman.com>
From: myNetWatchman <updatestatusonly@mynetwatchman.com>
To: "abuse@somewhere.net" <abuse@somewhere.net>
Errors-To: <mnwbounce@mynetwatchman.com>
Date: Thu, 30 Oct 2003 20:40 -0400
X-Msmail-Priority: Normal
Reply-To: updatestatusonly@mynetwatchman.com
X-Mailer: AspMail 4.0 4.03 (SMT41F290F)
Subject: myNetWatchman Incident [5433333333] Src:(200.200.200.200) Targets:10
MIME-Version: 1.0
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 7bit

myNetWatchman Incident [5433333333] Src:(200.200.200.200) Targets:10


FYI,

myNetWatchman aggregates security events from a sensor network 
of more than 1400 firewalls around the world.
Our sensors indicate suspicious activity originating from your network.

Here are the aggregated firewall logs:
Source IP: 200.200.200.200
Source DNS: dC85494B1.dslam-14-9-14-07-2-02.cmr.dsl.somewhere.net
Time Zone: UTC

AgentName, Event Date Time, Destination IP, IP Protocol, Target Port, Issue Description, Source Port, Event Count
youngerberry, 30 Oct 2003 22:10:04, 68.19.x.x, 6, 137, W32.Opaserv Worm?, 1038, 1
 Micky, 30 Oct 2003 20:23:36, 66.183.x.x, 17, 137, W32.Opaserv Worm?, 1037, 1
Jamest, 30 Oct 2003 20:22:05, 66.183.x.x, 6, 137, W32.Opaserv Worm?, 1037, 1
Davel, 29 Oct 2003 20:31:47, 63.201.x.x, 17, 137, W32.Opaserv Worm?, 1035, 1
Davel, 29 Oct 2003 20:31:47, 63.201.x.x, 17, 137, W32.Opaserv Worm?, 1035, 1
waynepyrah, 29 Oct 2003 14:51:10, 212.159.x.x, 17, 137, W32.Opaserv Worm?, 1026, 1
crusader, 29 Oct 2003 14:36:38, 212.159.x.x, 17, 137, W32.Opaserv Worm?, 1026, 1
Gringo, 26 Oct 2003 00:47:22, 24.76.x.x, 17, 137, W32.Opaserv Worm?, 1033, 1
thoreau, 25 Oct 2003 16:24:48, 156.34.x.x, 17, 137, W32.Opaserv Worm?, 1030, 1
djchadderton, 25 Oct 2003 15:48:32, 81.77.x.x, 17, 137, W32.Opaserv Worm?, 1028, 1
A Computer, 25 Oct 2003 15:46:35, 10.1.x.x, 17, 137, W32.Opaserv Worm?, 1028, 1
jonajuna, 24 Oct 2003 21:25:46, 81.86.x.x, 17, 137, W32.Opaserv Worm?, 1036, 1
marty, 24 Oct 2003 16:03:27, 172.16.x.x, 6, 137, W32.Opaserv Worm?, 1028, 1
Jamest, 24 Oct 2003 00:39:37, 66.183.x.x, 6, 137, W32.Opaserv Worm?, 1035, 1
rbooth, 23 Oct 2003 18:13:36, 82.43.x.x, 17, 137, W32.Opaserv Worm?, 1033, 1
Thoris, 23 Oct 2003 15:17:42, 216.232.x.x, 17, 137, W32.Opaserv Worm?, 1028, 1


Click here to get further details regarding this incident: 
http://www.mynetwatchman.com/LID.asp?IID=5433333333



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

http://www.mynetwatchman.com/UI.asp?IID=5433333333&CD=21Oct200311:22:11

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
Return-Path: <updatestatusonly@mynetwatchman.com>
Received: from rs25s11.datacenter.cha.somewhere.net (rs25s11.ric.somewhere.net
    [10.128.131.131]) by rs25s2.datacenter.cha.somewhere.net (8.12.10/8.10.2/1.0)
    with ESMTP id h9V1exwQ002523 for <abuse@somewhere.net>; Thu, 30 Oct 2003
    21:40:59 -0400
Received: from lidiot.mynetwatchman.com (host1.mynetwatchman.com
    [216.154.203.172]) by rs25s11.datacenter.cha.somewhere.net
    (8.12.10/8.12.6/3.0) with ESMTP id h9V1h6qB031637 for <abuse@somewhere.net>;
    Thu, 30 Oct 2003 21:43:06 -0400
X-Matched-Lists: []
Received: from idiotweb (mnwweb.mynetwatchman.com [172.17.1.108] (may be
    forged)) by lidiot.mynetwatchman.com (8.12.8/8.12.8) with SMTP id
    h9V1pU1H021890 for <abuse@somewhere.net>; Thu, 30 Oct 2003 20:51:31 -0500
Message-Id: <200310310151.h9V5555555557770@lidiot.mynetwatchman.com>
From: myNetWatchman <updatestatusonly@mynetwatchman.com>
To: "abuse@somewhere.net" <abuse@somewhere.net>
Errors-To: <mnwbounce@mynetwatchman.com>
Date: Thu, 30 Oct 2003 20:40 -0400
X-Msmail-Priority: Normal
Reply-To: updatestatusonly@mynetwatchman.com
X-Mailer: AspMail 4.0 4.03 (SMT41F290F)
Subject: myNetWatchman Incident [5433333333] Src:(200.200.200.200) Targets:16
MIME-Version: 1.0
Content-Type: text/plain; charset="us-ascii"
Content-Transfer-Encoding: 7bit

myNetWatchman Incident [5433333333] Src:(200.200.200.200) Targets:3


FYI,

Based on multiple reports from myNetWatchman users, we believe that the 
following host is compromised or infected:

Source IP: 200.200.200.200
Source DNS: 
Time Zone: UTC

Event Date Time, Destination IP, IP Protocol, Target Port, Issue Description, Source Port, Event Count
30 Oct 2003 22:10:04, 68.19.x.x, 6, 137, W32.Opaserv Worm?, 1038, 1
30 Oct 2003 20:23:36, 66.183.x.x, 17, 137, W32.Opaserv Worm?, 1037, 1
30 Oct 2003 20:22:05, 66.183.x.x, 6, 137, W32.Opaserv Worm?, 1037, 1
29 Oct 2003 20:31:47, 63.201.x.x, 17, 137, W32.Opaserv Worm?, 1035, 1
29 Oct 2003 20:31:47, 63.201.x.x, 17, 137, W32.Opaserv Worm?, 1035, 1
29 Oct 2003 14:51:10, 212.159.x.x, 17, 137, W32.Opaserv Worm?, 1026, 1
29 Oct 2003 14:36:38, 212.159.x.x, 17, 137, W32.Opaserv Worm?, 1026, 1
26 Oct 2003 00:47:22, 24.76.x.x, 17, 137, W32.Opaserv Worm?, 1033, 1
25 Oct 2003 16:24:48, 156.34.x.x, 17, 137, W32.Opaserv Worm?, 1030, 1
25 Oct 2003 15:48:32, 81.77.x.x, 17, 137, W32.Opaserv Worm?, 1028, 1
25 Oct 2003 15:46:35, 10.1.x.x, 17, 137, W32.Opaserv Worm?, 1028, 1
24 Oct 2003 21:25:46, 81.86.x.x, 17, 137, W32.Opaserv Worm?, 1036, 1
24 Oct 2003 16:03:27, 172.16.x.x, 6, 137, W32.Opaserv Worm?, 1028, 1
24 Oct 2003 00:39:37, 66.183.x.x, 6, 137, W32.Opaserv Worm?, 1035, 1
23 Oct 2003 18:13:36, 82.43.x.x, 17, 137, W32.Opaserv Worm?, 1033, 1
23 Oct 2003 15:17:42, 216.232.x.x, 17, 137, W32.Opaserv Worm?, 1028, 1

Click here to get further details regarding this incident: 
http://www.mynetwatchman.com/LID.asp?IID=5433333333

If you are running Windows, you can identify what
may be generating this activity by running our SecCheck tool:
See: http://www.mynetwatchman.com/tools/sc 
After running, email support@mynetwatchman.com for help in analyzing results.

Since the target port includes tcp/3127 (MyDoom Backdoor), then this
host is likely infected with the DoomJuice worm.
See: http://www.mynetwatchman.com/kb/security/ports/6/3127.htm



If you have any questions, feel free to contact me.

IMPORTANT: All replies to this e-mail are automatically posted
to a PUBLICLY viewable incident status.

If possible, please use the following URL to update incident status:

http://www.mynetwatchman.com/UI.asp?IID=73410295&CD=7Feb200412:10:50

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
