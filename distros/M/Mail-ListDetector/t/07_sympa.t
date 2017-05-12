#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;
use Mail::Internet;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'noustestons', 'listname');
is($list->listsoftware, 'RFC2369', 'list software');
is($list->posting_address, 'noustestons@cru.fr', 'posting address');

$mail->head->replace ('List-Post', '<mailto:noustestons@cru.fr> (with a nice comment)');

$list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'noustestons', 'listname');
is($list->listsoftware, 'RFC2369', 'list software');
is($list->posting_address, 'noustestons@cru.fr', 'posting address');

__DATA__
From - Wed Feb 14 09:49:48 2001
Return-Path: <noustestons-owner@cru.fr>
Received: from listes.cru.fr (listes.cru.fr [195.220.94.165])
          by home.cru.fr (8.9.3/jtpda-5.3.1) with ESMTP id JAA26395
          ; Wed, 14 Feb 2001 09:49:23 +0100
Received: from (sympa@localhost)
          by listes.cru.fr (8.9.3/jtpda-5.3.2) id JAA07499
          ; Wed, 14 Feb 2001 09:49:23 +0100
Sender: Olivier.Salaun@cru.fr
Message-ID: <3A8A4691.70332989@cru.fr>
Date: Wed, 14 Feb 2001 09:49:21 +0100
From: Olivier Salaun <olivier.salaun@cru.fr>
Organization: CRU
X-Mailer: Mozilla 4.74 [en] (X11; U; Linux 2.2.16-3 i686)
X-Accept-Language: en
MIME-Version: 1.0
To: noustestons@cru.fr
Subject: This is a sample message
X-Loop: noustestons@cru.fr
X-Sequence: 168
Precedence: list
List-Help: <mailto:sympa@cru.fr?subject=help>
List-Subscribe: <mailto:sympa@cru.fr?subject=subscribe%20noustestons>
List-Unsubscribe: <mailto:sympa@cru.fr?subject=unsubscribe%20noustestons>
List-Post: <mailto:noustestons@cru.fr>
List-Owner: <mailto:noustestons-request@cru.fr>
List-Archive: <http://listes.cru.fr/wws/arc/noustestons>
Content-type: multipart/mixed; boundary="----------=_982140563-24435-126"
Content-Transfer-Encoding: 8bit
X-Mozilla-Status: 8001
X-Mozilla-Status2: 00000000

This is a multi-part message in MIME format...

------------=_982140563-24435-126
Content-Type: text/plain; charset=iso-8859-1
Content-Transfer-Encoding: 8bit

Hope it helps....

--
Olivier Salaün
Comité Réseaux des Universités

------------=_982140563-24435-126
Content-Type: text/plain; name="message.footer"
Content-Disposition: inline; filename="message.footer"
Content-Transfer-Encoding: 8bit

fgdfgdfgdfdg

------------=_982140563-24435-126--

