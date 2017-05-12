# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

# this code is written in Unicode/UTF-8 character-set
# including Japanese letters.

use strict;
use warnings;

use utf8;

use Test::More tests => 6;

BEGIN { use_ok('Lingua::JA::Mail::Header') };

my $header = Lingua::JA::Mail::Header->new;
isa_ok( $header, 'Lingua::JA::Mail::Header' );

$header->date('Thu, 20 Mar 2003 15:21:18 +0900');
$header->add_from('taro@cpan.tld', 'YAMADA, Taro');

# display-name is omitted:
 $header->add_to('kaori@cpan.tld');
# with a display-name in the US-ASCII characters:
 $header->add_to('sakura@cpan.tld', 'Sakura HARUNO');
# with a display-name containing Japanese characters:
 $header->add_to('yuri@cpan.tld', '白百合ゆり');

# mail subject containing Japanese characters.
$header->subject('日本語で書かれた題名');

# output the composed mail
my $got = $header->build;

my $expected = <<'EOF';
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
EOF

chomp($expected);

is ( $got, $expected,
	"build header 'fields' including a 'display-name' and a 'Subject:' field those which are encoded with 'B' encoding with 'ISO-2022-JP' charset");

########################################################################
# compose a long subject containing Japanese characters needs folding.
my $header_2 = Lingua::JA::Mail::Header->new;
$header_2->date('Thu, 20 Mar 2003 15:21:18 +0900');
$header_2->add_from('taro@cpan.tld', 'YAMADA, Taro');

$header_2->add_to('kaori@cpan.tld');
$header_2->add_to('sakura@cpan.tld', 'Sakura HARUNO');
$header_2->add_to('yuri@cpan.tld', '白百合ゆり');

# long mail subject containing Japanese characters.
$header_2->subject('日本語で書かれた題名。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');

$got = $header_2->build;

$expected = <<'EOF';
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
EOF

chomp($expected);

is ( $got, $expected,
	"almost same as above but with longer 'Subject:' field needs 'folding'");

########################################################################
# compose a long destination header fields.
my $header_3 = Lingua::JA::Mail::Header->new;
$header_3->date('Thu, 20 Mar 2003 15:21:18 +0900');
$header_3->add_from('taro@cpan.tld', 'YAMADA, Taro');

# with a long display-name in the US-ASCII characters:
 $header_3->add_to('kaori@cpan.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
# with a long display-name in the US-ASCII characters:
 $header_3->add_to('sakura@cpan.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
# with a long display-name containing Japanese characters:
 $header_3->add_to('yuri@cpan.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');

$header_3->subject('日本語で書かれた題名。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');

$got = $header_3->build;

$expected = <<'EOF';
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
EOF

chomp($expected);

is ( $got, $expected,
	"almost same as above but with longer 'display-name's need 'folding'");

########################################################################
# compose a long various header containing Japanese characters.
my $header_4 = Lingua::JA::Mail::Header->new;
$header_4->date('Thu, 20 Mar 2003 15:21:18 +0900');
$header_4->add_from('taro@cpan.tld', 'YAMADA, Taro');
$header_4->add_from('ken@cpan.tld');
$header_4->add_from('masaru@cpan.tld', '勝');
$header_4->sender('taka@cpan.tld', 'チャンピオン鷹');
$header_4->add_reply('taro@cpan-jp.tld', 'YAMADA, Taro');
$header_4->add_reply('ken@cpan-jp.tld');
$header_4->add_reply('masaru@cpan-jp.tld', '勝');

$header_4->add_to('kaori@cpan.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
$header_4->add_to('sakura@cpan.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
$header_4->add_to('yuri@cpan.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
$header_4->add_cc('kaori@cpan-jp.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
$header_4->add_cc('sakura@cpan-jp.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
$header_4->add_cc('yuri@cpan-jp.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');
$header_4->add_bcc('kaori@cpan-saitama.tld', 'RARARARARARARARARARARARARARARARARARARARA RARARARARARARARARARARARARARARARARARARARA');
$header_4->add_bcc('sakura@cpan-saitama.tld', 'RARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARARA');
$header_4->add_bcc('yuri@cpan-saitama.tld', '日本語で書かれた名前。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');

$header_4->subject('日本語で書かれた題名。とても長い。長い長いお話。ちゃんとエンコードできるのでしょうか？');

$got = $header_4->build;

$expected = <<'EOF';
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
EOF

chomp($expected);

is ( $got, $expected,
	'almost same as above but with the other various headers');
