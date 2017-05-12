#!/usr/bin/perl -w

use strict;
use Mail::Internet;
use Test::More tests => 16;
use Mail::ListDetector;

my $mail;

$mail = new Mail::Internet(\*DATA);

my $list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'Announce', 'listname');
is($list->listsoftware, 'fml 4.0 STABLE (20010218)', 'list software');
is($list->posting_address, 'Announce@mldetector.gr.jp', 'posting address');

$mail->head->delete('List-Subscribe');

$list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'Announce', 'listname');
is($list->listsoftware, 'fml 4.0 STABLE (20010218)', 'list software');
is($list->posting_address, 'Announce@mldetector.gr.jp', 'posting address');

$mail->head->delete('X-ML-Info');

$list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'Announce', 'listname');
is($list->listsoftware, 'fml 4.0 STABLE (20010218)', 'list software');
is($list->posting_address, 'Announce@mldetector.gr.jp', 'posting address');

$mail->head->delete('X-ML-Name');

$list = new Mail::ListDetector($mail);

ok(defined($list), 'list is defined');
is($list->listname, 'Announce', 'listname');
is($list->listsoftware, 'fml 4.0 STABLE (20010218)', 'list software');
is($list->posting_address, 'Announce@mldetector.gr.jp', 'posting address');



__DATA__
Received: from mldetector.net (msv-x05.mldetector.ne.jp [10.158.32.3])
    by ml.mldetector.gr.jp (8.9.3p2/3.7W/) with ESMTP id AAA74508
    for <announce@ml.mldetector.gr.jp>; Thu, 17 Jul 2003 01:52:35 +0900 (JST)
Received: from denshadego (whrr.hou.mldetector.net [10.12.6.189])
    (authenticated (0 bits))
    by mldetector.net (8.12.5/8.11.2) with ESMTP id 732h6GFqXkO002877
    for <announce@ml.mldetector.gr.jp>; Thu, 17 Jul 2003 01:52:32 +0900
Date: Thu, 17 Jul 2003 01:52:22 +0900
From: "Densha De Go" <densha@mldetector.net>
Reply-To: Announce@mldetector.gr.jp
Subject: [Announce:00089] Web mldetector
To: <announce@ml.mldetector.gr.jp>
Message-Id: <00a801c34bb2$4jhasjdh58udsc0@orient.corp.mldetector.com>
X-ML-Name: Announce
X-Mail-Count: 00089
X-MLServer: fml [fml 4.0 STABLE (20010218)](fml commands only mode); post only (only members can post)
X-ML-Info: If you have a question,
    please contact Announce-admin@mldetector.gr.jp;
    <mailto:Announce-admin@mldetector.gr.jp>
X-Mailer: Microsoft Outlook Express 6.00.2800.1158
Mime-Version: 1.0
Content-Type: text/plain;
    charset="iso-2022-jp"
Content-Transfer-Encoding: 7bit
Precedence: bulk
List-Subscribe: <mailto:Announce-ctl@mldetector.gr.jp?body=subscribe>
Resent-From: denshadego@yo.mldetector.or.jp
Resent-To: Announce@mldetector.gr.jp (moderated)
Resent-Date: Thu, 17 Jul 2003 00:52:57 +0900
Resent-Message-Id: <200307170052.FMLAAB99994.Announce@mldetector.gr.jp>


