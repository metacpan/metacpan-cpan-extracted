# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

# this code is written in Unicode/UTF-8 character-set
# including Japanese letters.

use strict;
use warnings;

use utf8;

use Test::More tests => 7;

BEGIN { use_ok('Lingua::JA::Mail') };

my $mail = Lingua::JA::Mail->new;
isa_ok( $mail, 'Lingua::JA::Mail' );

# compose a mail containing Japanese characters.
$mail->date('Thu, 20 Mar 2003 15:21:18 +0900');
$mail->add_from('taro@cpan.tld', 'YAMADA, Taro');

# display-name is omitted:
 $mail->add_to('kaori@cpan.tld');
# with a display-name in the US-ASCII characters:
 $mail->add_to('sakura@cpan.tld', 'Sakura HARUNO');
# with a display-name containing Japanese characters:
 $mail->add_to('yuri@cpan.tld', '白百合ゆり');

# mail subject containing Japanese characters.
$mail->subject('日本語で書かれた題名');
# mail body    containing Japanese characters.
$mail->body('日本語で書かれた本文。');

# output the composed mail
my $got = $mail->compose;

chomp(my $expected = <<'EOF');
Date: Thu, 20 Mar 2003 15:21:18 +0900
From: 
 "YAMADA, Taro"
 <taro@cpan.tld>
To: 
 kaori@cpan.tld,
 "Sakura HARUNO"
 <sakura@cpan.tld>,
 =?ISO-2022-JP?B?GyRCR3JJNDlnJGYkahsoQg==?=
 <yuri@cpan.tld>
Subject: 
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0JqTD4bKEI=?=
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit
X-Mail-Composer: Mail.pm v0.03 (Lingua::JA::Mail http://www.cpan.org/)

$BF|K\8l$G=q$+$l$?K\J8!#(B
EOF

is ( $got, $expected,
	'composing a ISO-2022-JP encoded mail with some encoded headers');
########################################################################
# compose a long subject and body containing Japanese characters.
my $mail_2 = Lingua::JA::Mail->new;
$mail_2->date('Thu, 20 Mar 2003 15:21:18 +0900');
$mail_2->add_from('taro@cpan.tld', 'YAMADA, Taro');

# display-name is omitted:
 $mail_2->add_to('kaori@cpan.tld');
# with a display-name in the US-ASCII characters:
 $mail_2->add_to('sakura@cpan.tld', 'Sakura HARUNO');
# with a display-name containing Japanese characters:
 $mail_2->add_to('yuri@cpan.tld', '白百合ゆり');

# mail subject containing Japanese characters.
$mail_2->subject('日本語で書かれた題名。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
# mail body    containing Japanese characters.
$mail_2->body('日本語で書かれた本文。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
# output the composed mail
$got = $mail_2->compose;

chomp($expected = <<'EOF');
Date: Thu, 20 Mar 2003 15:21:18 +0900
From: 
 "YAMADA, Taro"
 <taro@cpan.tld>
To: 
 kaori@cpan.tld,
 "Sakura HARUNO"
 <sakura@cpan.tld>,
 =?ISO-2022-JP?B?GyRCR3JJNDlnJGYkahsoQg==?=
 <yuri@cpan.tld>
Subject: 
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0JqTD4hIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit
X-Mail-Composer: Mail.pm v0.03 (Lingua::JA::Mail http://www.cpan.org/)

$BF|K\8l$G=q$+$l$?K\J8!#$H$F$bD9$$!#D9$$D9$$$*OC!#$A$c$s$H%(%s%3!<%I$G$-$k$N$G$7$g$&$+!)(B
EOF

is ( $got, $expected,
	'same as above but with longer MIME Base64 encoded subject and body');

########################################################################
# compose a long destination header containing Japanese characters.
my $mail_3 = Lingua::JA::Mail->new;
$mail_3->date('Thu, 20 Mar 2003 15:21:18 +0900');
$mail_3->add_from('taro@cpan.tld', 'YAMADA, Taro');

# with a display-name in the US-ASCII characters:
 $mail_3->add_to('kaori@cpan.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
# with a display-name in the US-ASCII characters:
 $mail_3->add_to('sakura@cpan.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
# with a display-name containing Japanese characters:
 $mail_3->add_to('yuri@cpan.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');

# mail subject containing Japanese characters.
$mail_3->subject('日本語で書かれた題名。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
# mail body    containing Japanese characters.
$mail_3->body('日本語で書かれた本文。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
# output the composed mail
$got = $mail_3->compose;

chomp($expected = <<'EOF');
Date: Thu, 20 Mar 2003 15:21:18 +0900
From: 
 "YAMADA, Taro"
 <taro@cpan.tld>
To: 
 RARARARARARARARARARARARARARARARARARARARA
 RARARARARARARARARARARARARARARARARARARARA
 <kaori@cpan.tld>,
 =?US-ASCII?Q?RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA?=
 =?US-ASCII?Q?RARARARARARARARARARA?=
 <sakura@cpan.tld>,
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0w+QTAhIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
 <yuri@cpan.tld>
Subject: 
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0JqTD4hIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit
X-Mail-Composer: Mail.pm v0.03 (Lingua::JA::Mail http://www.cpan.org/)

$BF|K\8l$G=q$+$l$?K\J8!#$H$F$bD9$$!#D9$$D9$$$*OC!#$A$c$s$H%(%s%3!<%I$G$-$k$N$G$7$g$&$+!)(B
EOF

is ( $got, $expected,
	'same as above but with longer encoded display-name of address');

########################################################################
# compose a long various header containing Japanese characters.
my $mail_4 = Lingua::JA::Mail->new;
$mail_4->date('Thu, 20 Mar 2003 15:21:18 +0900');
$mail_4->add_from('taro@cpan.tld', 'YAMADA, Taro');
$mail_4->add_from('ken@cpan.tld');
$mail_4->add_from('masaru@cpan.tld', '勝');
$mail_4->sender('taka@cpan.tld', 'チャンピオン鷹');
$mail_4->add_reply('taro@cpan-jp.tld', 'YAMADA, Taro');
$mail_4->add_reply('ken@cpan-jp.tld');
$mail_4->add_reply('masaru@cpan-jp.tld', '勝');

$mail_4->add_to('kaori@cpan.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
$mail_4->add_to('sakura@cpan.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
$mail_4->add_to('yuri@cpan.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
$mail_4->add_cc('kaori@cpan-jp.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
$mail_4->add_cc('sakura@cpan-jp.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
$mail_4->add_cc('yuri@cpan-jp.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
$mail_4->add_bcc('kaori@cpan-saitama.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
$mail_4->add_bcc('sakura@cpan-saitama.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
$mail_4->add_bcc('yuri@cpan-saitama.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');

# mail subject containing Japanese characters.
$mail_4->subject('日本語で書かれた題名。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
# mail body    containing Japanese characters.
$mail_4->body('日本語で書かれた本文。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
# output the composed mail
$got = $mail_4->compose;

chomp($expected = <<'EOF');
Date: Thu, 20 Mar 2003 15:21:18 +0900
From: 
 "YAMADA, Taro"
 <taro@cpan.tld>,
 ken@cpan.tld,
 =?ISO-2022-JP?B?GyRCPiEbKEI=?=
 <masaru@cpan.tld>
Sender: 
 =?ISO-2022-JP?B?GyRCJUElYyVzJVQlKiVzQmsbKEI=?=
 <taka@cpan.tld>
Reply-To: 
 "YAMADA, Taro"
 <taro@cpan-jp.tld>,
 ken@cpan-jp.tld,
 =?ISO-2022-JP?B?GyRCPiEbKEI=?=
 <masaru@cpan-jp.tld>
To: 
 RARARARARARARARARARARARARARARARARARARARA
 RARARARARARARARARARARARARARARARARARARARA
 <kaori@cpan.tld>,
 =?US-ASCII?Q?RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA?=
 =?US-ASCII?Q?RARARARARARARARARARA?=
 <sakura@cpan.tld>,
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0w+QTAhIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
 <yuri@cpan.tld>
Cc: 
 RARARARARARARARARARARARARARARARARARARARA
 RARARARARARARARARARARARARARARARARARARARA
 <kaori@cpan-jp.tld>,
 =?US-ASCII?Q?RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA?=
 =?US-ASCII?Q?RARARARARARARARARARA?=
 <sakura@cpan-jp.tld>,
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0w+QTAhIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
 <yuri@cpan-jp.tld>
Bcc: 
 RARARARARARARARARARARARARARARARARARARARA
 RARARARARARARARARARARARARARARARARARARARA
 <kaori@cpan-saitama.tld>,
 =?US-ASCII?Q?RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA?=
 =?US-ASCII?Q?RARARARARARARARARARA?=
 <sakura@cpan-saitama.tld>,
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0w+QTAhIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
 <yuri@cpan-saitama.tld>
Subject: 
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0JqTD4hIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit
X-Mail-Composer: Mail.pm v0.03 (Lingua::JA::Mail http://www.cpan.org/)

$BF|K\8l$G=q$+$l$?K\J8!#$H$F$bD9$$!#D9$$D9$$$*OC!#$A$c$s$H%(%s%3!<%I$G$-$k$N$G$7$g$&$+!)(B
EOF

is ( $got, $expected,
	'same as above but with other various headers');

########################################################################
# testing preconvert function
my $mail_5 = Lingua::JA::Mail->new;
$mail_5->date('Thu, 20 Mar 2003 15:21:18 +0900');
$mail_5->add_from('taro@cpan.tld', 'YAMADA, Taro');
$mail_5->add_from('ken@cpan.tld');
$mail_5->add_from('masaru@cpan.tld', '勝');
$mail_5->sender('taka@cpan.tld', 'チャンピオン鷹');
$mail_5->add_reply('taro@cpan-jp.tld', 'YAMADA, Taro');
$mail_5->add_reply('ken@cpan-jp.tld');
$mail_5->add_reply('masaru@cpan-jp.tld', '勝');

$mail_5->add_to('kaori@cpan.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
$mail_5->add_to('sakura@cpan.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
$mail_5->add_to('yuri@cpan.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
$mail_5->add_cc('kaori@cpan-jp.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
$mail_5->add_cc('sakura@cpan-jp.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
$mail_5->add_cc('yuri@cpan-jp.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
$mail_5->add_bcc('kaori@cpan-saitama.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
$mail_5->add_bcc('sakura@cpan-saitama.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
$mail_5->add_bcc('yuri@cpan-saitama.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');

# mail subject containing Japanese characters.
$mail_5->subject('日本語で書かれた題名。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
# mail body    containing Japanese characters.
$mail_5->body('\¥—‾∥－～￠￡￢');
# output the composed mail
$got = $mail_5->compose;

chomp($expected = <<'EOF');
Date: Thu, 20 Mar 2003 15:21:18 +0900
From: 
 "YAMADA, Taro"
 <taro@cpan.tld>,
 ken@cpan.tld,
 =?ISO-2022-JP?B?GyRCPiEbKEI=?=
 <masaru@cpan.tld>
Sender: 
 =?ISO-2022-JP?B?GyRCJUElYyVzJVQlKiVzQmsbKEI=?=
 <taka@cpan.tld>
Reply-To: 
 "YAMADA, Taro"
 <taro@cpan-jp.tld>,
 ken@cpan-jp.tld,
 =?ISO-2022-JP?B?GyRCPiEbKEI=?=
 <masaru@cpan-jp.tld>
To: 
 RARARARARARARARARARARARARARARARARARARARA
 RARARARARARARARARARARARARARARARARARARARA
 <kaori@cpan.tld>,
 =?US-ASCII?Q?RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA?=
 =?US-ASCII?Q?RARARARARARARARARARA?=
 <sakura@cpan.tld>,
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0w+QTAhIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
 <yuri@cpan.tld>
Cc: 
 RARARARARARARARARARARARARARARARARARARARA
 RARARARARARARARARARARARARARARARARARARARA
 <kaori@cpan-jp.tld>,
 =?US-ASCII?Q?RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA?=
 =?US-ASCII?Q?RARARARARARARARARARA?=
 <sakura@cpan-jp.tld>,
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0w+QTAhIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
 <yuri@cpan-jp.tld>
Bcc: 
 RARARARARARARARARARARARARARARARARARARARA
 RARARARARARARARARARARARARARARARARARARARA
 <kaori@cpan-saitama.tld>,
 =?US-ASCII?Q?RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA?=
 =?US-ASCII?Q?RARARARARARARARARARA?=
 <sakura@cpan-saitama.tld>,
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0w+QTAhIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
 <yuri@cpan-saitama.tld>
Subject: 
 =?ISO-2022-JP?B?GyRCRnxLXDhsJEc9cSQrJGwkP0JqTD4hIyRIJEYkYkQ5JCQhI0Q5GyhC?=
 =?ISO-2022-JP?B?GyRCJCREOSQkJCpPQyEjJEEkYyRzJEglKCVzJTMhPCVJJEckLSRrGyhC?=
 =?ISO-2022-JP?B?GyRCJE4kRyQ3JGckJiQrISkbKEI=?=
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit
X-Mail-Composer: Mail.pm v0.03 (Lingua::JA::Mail http://www.cpan.org/)

$B!@!o!=!1!B!]!A!q!r"L(B
EOF

is ( $got, $expected,
	'preconvert function check');

########################################################################
# 
