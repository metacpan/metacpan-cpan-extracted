use strict;
use warnings;
use Test::More tests => 2;

# Bug discovered by RJBS (rt.cpan.org, ticket 37139)
#
# Sometimes, when collapsing a message into single part, the
# Content-type is horked up.
#
# It starts as:
#
# Content-Type: multipart/related; boundary=xyzzy; type=foo
#
# ...and ends as:
#
# Content-Type: text/plain; boundary=xyzzy; type=foo
#

use MIME::Parser;

my $parser = MIME::Parser->new();
$parser->output_to_core(1);
my $entity = $parser->parse(\*DATA);

sub cleanup_mime {
  # Forcibly trash ->parts() to reproduce bug
  my ($entity) = @_;
  foreach my $part ($entity->parts) {
    cleanup_mime($part);
    $entity->parts([]);
  }
}

#diag( $entity->as_string);
cleanup_mime($entity);
#diag( $entity->as_string);

is($entity->make_singlepart, 'DONE', 'make_singlepart() succeeded');

is($entity->head->get('Content-type'), "text/plain\n");
#diag( $entity->as_string);

__DATA__
Received: from indigo.pobox.com (indigo.pobox.com [207.106.133.17])
	by chiclet.listbox.com (Postfix) with ESMTP id 2AE91214A41
	for <devnull@pobox.com>; Tue, 24 Jun 2008 01:22:44 -0400 (EDT)
Received: from vip-2fed93075f2 (unknown [116.60.133.101])
	by indigo.pobox.com (Postfix) with SMTP id 4DE1A6BF4D;
	Tue, 24 Jun 2008 01:22:30 -0400 (EDT)
From: "ÕÅÏÈÉú"<ÕÅÏÈÉú>
Reply-To: "h7w4v4c1@umail.hinet.net"<h7w4v4c1@umail.hinet.net>
To: "devnull@pobox.com"<devnull@pobox.com>
Subject: =?gb2312?B?uePW3crQwaq3or34s/a/2sOz0tfT0M/euavLvg==?=
Date: Tue, 24 Jun 08 13:22:18 +0800
MIME-Version: 1.0
Content-type: multipart/related;
    type="multipart/alternative";
    boundary="----=_NextPart_000_0015_1963AAAC.4C2B0004"
X-Priority: 3
X-MSMail-Priority: Normal
X-Mailer: Microsoft Outlook Express 6.00.2800.1158
X-MimeOLE: Produced By Microsoft MimeOLE V6.00.2800.1441
Message-Id: <20080624052230.4DE1A6BF4D@indigo.pobox.com>


This is a multi-part message in MIME format.

------=_NextPart_000_0015_1963AAAC.4C2B0004
Content-Type: multipart/alternative;
	boundary="----=_NextPart_001_0016_1963AAAC.4C2B0004"


------=_NextPart_001_0016_1963AAAC.4C2B0004
Content-Type: text/html; charset=gb2312
Content-Transfer-Encoding: base64

PCFET0NUWVBFIEhUTUwgUFVCTElDICItLy9XM0MvL0RURCBIVE1MIDQuMCBUcmFuc2l0aW9uYWwvL0VO
Ij4NCjxIVE1MPjxIRUFEPg0KPE1FVEEgY29udGVudD1odHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29t
L2ludGVsbGlzZW5zZS9pZTUgDQpuYW1lPXZzX3RhcmdldFNjaGVtYT4NCjxNRVRBIGh0dHAtZXF1aXY9
Q29udGVudC1UeXBlIGNvbnRlbnQ9InRleHQvaHRtbDsgY2hhcnNldD1nYjIzMTIiPg0KPE1FVEEgY29u
dGVudD0iTVNIVE1MIDYuMDAuMjkwMC4zMzU0IiBuYW1lPUdFTkVSQVRPUj48L0hFQUQ+DQo8Qk9EWSBz
dHlsZT0iRk9OVC1TSVpFOiA5cHQ7IEZPTlQtRkFNSUxZOiDLzszlIj4NCjxQPsT6usMhPEJSPiZuYnNw
OyZuYnNwOyCxvrmry77XqMPFzqq498Oz0tfJzLvyyfqy+rOnvNK0+sDtu/XO7734s/a/2rGoudihoiAN
CsnMvOyhorWl1qShosjrstahorGoudjK1tD4oaLNz7O1oaLW0LjbLLT6sOy499bWsvq12NakyukuwarP
tcjLo7rVxc/Iyfogyta7+jEzNjMyMjc4MzMyJm5ic3A7IFRFTDAyMC0zNzIzMjYwNiANCjYxMDMwOTY0
IEZBWDAyMC02MTAzMDUxNSC12Na3o7q549bdytDM7LrTx/jR4MHrwrcxMjC6xb3w0eC088/DIMjn09C0
8sjFx+u8+8HCITxCUj48L1A+PC9CT0RZPjwvSFRNTD4NCg==


------=_NextPart_001_0016_1963AAAC.4C2B0004--



------=_NextPart_000_0015_1963AAAC.4C2B0004--


