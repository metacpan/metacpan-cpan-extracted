#!/usr/bin/perl

$|=1;

use lib ('../lib');
use IMAP::Client;
use strict;
sub dump_hash(%) {
    my %hash = @_;
    foreach my $r (keys %hash) {
	print "$r: $hash{$r}\n";
    }
}
sub dump_fetch(%) {
    my %base = @_;
    foreach my $msgid (keys %base) {
		return 0 unless ($base{$msgid});
		print "(MSGID = $msgid)\n";
		my %ret = %{$base{$msgid}};
		foreach my $key (keys %ret) {
		    if ($key eq "ENVELOPE") {
				foreach my $key2 (keys %{$ret{$key}}) {
				    print "ENVELOPE: $key2: $ret{$key}->{$key2}\n";
				}
		    } elsif ($key eq 'FLAGS') {
				print "FLAGS: ",join(' ',@{$ret{$key}}),"\n";
		    } elsif (($key eq 'BODYSTRUCTURE') || ($key eq 'BODY')) {
				foreach my $subkey (keys %{$ret{$key}}) {
				    if ($subkey =~ /^\d+$/) {
						foreach my $subkey2 (keys %{$ret{$key}->{$subkey}}) {
						    if ($subkey2 =~ /^\d+$/) {
								foreach my $subkey3 (keys %{$ret{$key}->{$subkey}->{$subkey2}}) {
								    print "$key: $subkey: $subkey2: $subkey3: $ret{$key}->{$subkey}->{$subkey2}->{$subkey3}\n";
								}
						    } else {
								print "$key: $subkey: $subkey2: $ret{$key}->{$subkey}->{$subkey2}\n";
						    }
						}
				    } else {
						print "$key: $subkey: $ret{$key}->{$subkey}\n";
			    	}
				}
		    } else {
				print "$key: $ret{$key}\n";
		    }
		}
    }
    return(1);
}

########################### MAIN PROGRAM START ###########################

if (scalar(@ARGV) < 3) {
	die "Requires 3 arguments - server, admin username, admin password\n";
}

my $message = get_small_message();
my $errormsg = "Arguments must come in 3s - server, username, and password\n";
my @set;
for (my $i=0;$ARGV[0];$i++) {
	$set[$i]->{'server'} = shift or die $errormsg;
	$set[$i]->{'user'} = shift or die $errormsg;
	$set[$i]->{'pass'} = shift or die $errormsg;
}
my $user;

my %resp;
my @resplist;

my %imap;
foreach my $connection (@set) {
	$imap{$connection->{'server'}} = new IMAP::Client();
	unless (ref $imap{$connection->{'server'}}) {
	    die "Failed to create object: $imap{$connection->{'server'}}\n";
	}
	
	$imap{$connection->{'server'}}->onfail('ERROR');
	$imap{$connection->{'server'}}->errorstyle('STACK');
	$imap{$connection->{'server'}}->debuglevel(1);


	$imap{$connection->{'server'}}->connect(PeerAddr => $connection->{'server'},
			       ConnectMethod => 'STARTTLS SSL',
			       )
    or die "Unable to connect to [$connection->{'server'}]: ".$imap{$connection->{'server'}}->error();
}

foreach my $connection (@set) {
	$imap{$connection->{'server'}}->authenticate2($connection->{'user'},$connection->{'pass'})
	    or die "Unable to authenticate as $connection->{'user'} on behalf of $user: ".$imap{$connection->{'server'}}->error()."\n";
}
foreach my $connection (@set) {
	$imap{$connection->{'server'}}->id()
    or die $imap{$connection->{'server'}}->error();
}
foreach my $connection (@set) {
	$imap{$connection->{'server'}}->capability()
	    or die $imap{$connection->{'server'}}->error();
}
foreach my $connection (@set) {
	$imap{$connection->{'server'}}->noop()
	    or die $imap{$connection->{'server'}}->error();
}
foreach my $connection (@set) {
	$imap{$connection->{'server'}}->select("INBOX");
}
foreach my $connection (@set) {
	$imap{$connection->{'server'}}->logout();
}
foreach my $connection (@set) {
	 $imap{$connection->{'server'}}->disconnect();
}

sub get_small_message {
    return('Return-Path: <noone.you.know@anonymous.missing>
Received: from anonymous.missing (anonymous.missing [192.168.1.1])
	by mail.mailserver.mailer (envelope-sender <noone.you.know@anonymous.missing>) (MIMEDefang) with ESMTP id j9DGxkkY002977; Thu, 13 Apr 2005 12:59:47 -0400 (EDT)
Received: from mail2.mailserver.mailer (mail2.mailserver.mailer [192.168.1.2])
	by anonymous.missing (8.12.9/8.12.9) with ESMTP id j9DGxhtk022430
	for <noone.you.know@anonymous.missing>; Thu, 13 Apr 2005 12:59:44 -0400
Received: from mail3.mailserver.mailer (mail3.mailserver.mailer [192.168.1.3])
	by mail2.mailserver.mailer (8.13.0/8.13.0) with ESMTP id j9DGxahC026654
	for <noone.you.know@anonymous.missing>; Thu, 13 Apr 2005 12:59:36 -0400
Content-class: urn:content-classes:message
MIME-Version: 1.0
Content-Type: multipart/alternative;
	boundary="----_=_NextPart_001_12345151.23452677"
Subject: misc
Date: Thu, 13 Apr 2005 12:59:29 -0400
Message-ID: <unique>
Thread-Index: 4T5Q34A6FD7445D4F6GQ88443A5E4Q==
From: "Anonimoose" <noone.you.know@anonymous.missing>
To: <noone.you.know@anonymous.missing>
X-OriginalArrivalTime: 13 Apr 2005 16:59:36.0163 (UTC) FILETIME=[7DB2EB30:01C5D017]
X-To: recipient@somewhere.place
X-SPAM-Score: undef - Domain Whitelisted (anonymous.missing: )
X-Scanned-By: MIMEDefang 2.3 (www dot roaringpenguin dot com slash mimedefang)
Sender: fsnoone.you.know@anonymous.missing
X-Random: 3385249 - d72ba9325687

This is a multi-part message in MIME format.

------_=_NextPart_001_12345151.23452677
Content-Type: text/plain;
	charset="us-ascii"
Content-Transfer-Encoding: quoted-printable

What do *you* want to know?


------_=_NextPart_001_12345151.23452677
Content-Type: text/html;
	charset="us-ascii"
Content-Transfer-Encoding: quoted-printable

<html xmlns:o=3D"urn:schemas-microsoft-com:office:office" =
xmlns:w=3D"urn:schemas-microsoft-com:office:word" =
xmlns=3D"http://www.w3.org/TR/REC-html40">

<head>
<META HTTP-EQUIV=3D"Content-Type" CONTENT=3D"text/html; =
charset=3Dus-ascii">
<meta name=3DGenerator content=3D"Microsoft Word 11 (filtered medium)">
<style>
<!--
 /* Style Definitions */
 p.MsoNormal, li.MsoNormal, div.MsoNormal
	{margin:0in;
	margin-bottom:.0001pt;
	font-size:12.0pt;
	font-family:"Times New Roman";}
a:link, span.MsoHyperlink
	{color:blue;
	text-decoration:underline;}
a:visited, span.MsoHyperlinkFollowed
	{color:purple;
	text-decoration:underline;}
span.EmailStyle17
	{mso-style-type:personal-compose;
	font-family:Arial;
	color:windowtext;}
@page Section1
	{size:8.5in 11.0in;
	margin:1.0in 1.25in 1.0in 1.25in;}
div.Section1
	{page:Section1;}
-->
</style>

</head>

<body lang=3DEN-US link=3Dblue vlink=3Dpurple>

<div class=3DSection1>

<p class=3DMsoNormal><font size=3D2 face=3DArial><span =
style=3D\'font-size:10.0pt;
font-family:Arial\'>What to *you* want to know?<o:p></o:p></span></font></p>

</div>

</body>

</html>

------_=_NextPart_001_12345151.23452677--

');
}
