#!/usr/bin/perl -w

# This script is written in utf8

use strict;
use warnings;

use Test::More tests => 61;
#use Test::More 'no_plan';
BEGIN { use_ok('MIME::EcoEncode') };

use Encode;
use MIME::EcoEncode;

my $str;
my $encoded;

$str = 'test0';
is(mime_eco($str, 'UTF-8'), $str, 'ASCII (UTF-8)');
is(mime_eco($str, 'ISO-2022-JP'), $str, 'ASCII (ISO-2022-JP)');

$str = "test0\n";
is(mime_eco($str, 'UTF-8'), $str, 'ASCII . "\n" (UTF-8)');
is(mime_eco($str, 'ISO-2022-JP'), $str, 'ASCII . "\n" (ISO-2022-JP)');

$str = 'a' x 80;
is(mime_eco($str, 'UTF-8'), $str, 'ASCII x 80 (UTF-8)');
is(mime_eco($str, 'ISO-2022-JP'), $str, 'ASCII x 80 (ISO-2022-JP)');

$str = 'Subject: ' . 'a' x 80;
is(mime_eco($str, 'UTF-8'), $str,
   "\'Subject: \'" . ' . ASCII x 80 (UTF-8)');
is(mime_eco($str, 'ISO-2022-JP'), $str,
   "\'Subject: \'" . ' . ASCII x 80 (ISO-2022-JP)');

$str = ' ' x 80;
is(mime_eco($str, 'UTF-8'), $str,  'SP x 80 (UTF-8)');
is(mime_eco($str, 'ISO-2022-JP'), $str, 'SP x 80 (ISO-2022-JP)');

$str = ('a' x 80 . ' ') x 3;
is(mime_eco($str, 'UTF-8'), 'a' x 80 . ' ' . 'a' x 80 . "\n " .
   'a' x 80 . ' ', '(ASCII x 80 + SP) x 3 (UTF-8)');
is(mime_eco($str, 'ISO-2022-JP'), 'a' x 80 . ' ' . 'a' x 80 . "\n " .
   'a' x 80 . ' ', '(ASCII x 80 + SP) x 3 (ISO-2022-JP)');


$str = '日本語あいうえおアイウエオ' x 2;
is(mime_eco($str, 'UTF-8'),
   "=?UTF-8?B?" .
   "5pel5pys6Kqe44GC44GE44GG44GI44GK44Ki44Kk44Km44Ko44Kq5pel5pys6Kqe?=\n" .
   " =?UTF-8?B?44GC44GE44GG44GI44GK44Ki44Kk44Km44Ko44Kq?=",
   'non-ASCII only (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP'),
   "=?ISO-2022-JP?B?" .
   "GyRCRnxLXDhsJCIkJCQmJCgkKiUiJSQlJiUoJSpGfEtcOGwkIiQkGyhC?=\n" .
   " =?ISO-2022-JP?B?GyRCJCYkKCQqJSIlJCUmJSglKhsoQg==?=",
   'non-ASCII only (ISO-2022-JP)');


$str = '  ' . 'あ' . '  ';
is(mime_eco($str, 'UTF-8'), '  =?UTF-8?B?44GC?=  ',
   'SP SP non-ASCII SP SP (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP'),
   '  =?ISO-2022-JP?B?GyRCJCIbKEI=?=  ',
   'SP SP non-ASCII SP SP (ISO-2022-JP)');


$str = '  ' . 'あ' . '  ';
is(mime_eco($str, 'UTF-8', undef, undef, undef, 0), '=?UTF-8?B?ICDjgYIgIA==?=',
   '$lss=0 (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP',
	    undef, undef, undef, 0),
   '=?ISO-2022-JP?B?ICAbJEIkIhsoQiAg?=', '$lss=0 (ISO-2022-JP)');


$str = "  Subject:  Re:  [XXXX 0123]  Re:  アa  イi  ウu  A-I-U\n";
is(mime_eco($str, 'UTF-8'),
   "  Subject:  Re:  [XXXX 0123]  Re:  =?UTF-8?B?44KiYSAg44KkaSAg44KmdQ==?=" .
   " \n A-I-U\n",
   'SP SP ASCII non-ASCII . "\n" (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP'),
   "  Subject:  Re:  [XXXX 0123]  Re:  =?ISO-2022-JP?B?GyRCJSIbKEJhICA=?=" .
   "\n =?ISO-2022-JP?B?GyRCJSQbKEJpICAbJEIlJhsoQnU=?=  A-I-U\n",
   'SP SP ASCII non-ASCII . "\n" (ISO-2022-JP)');


$str = 'Subject: あいうえお アイウエオ ｱｲｳｴｵ A-I-U-E-O';
is(mime_eco($str, 'UTF-8'),
   "Subject: " .
   "=?UTF-8?B?44GC44GE44GG44GI44GKIOOCouOCpOOCpuOCqOOCqiDvvbHvvbI=?=\n" .
   " =?UTF-8?B?772z77207721?= A-I-U-E-O",
   'ASCII non-ASCII HankakuKana (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP'),
   "Subject: " .
   "=?ISO-2022-JP?B?GyRCJCIkJCQmJCgkKhsoQiAbJEIlIiUkJSYlKCUqGyhCIA==?=\n" .
   " =?ISO-2022-JP?B?GyhJMTIzNDUbKEI=?= A-I-U-E-O",
   'ASCII non-ASCII HankakuKana (ISO-2022-JP)');


$str = 'Subject: Re: あ A い I';
is(mime_eco($str, 'UTF-8', "|\n", 17),
   "Subject: Re:|\n =?UTF-8?B?44GC?=|\n A|\n =?UTF-8?B?44GE?=|\n I",
   '$lf="|\n", $bpl=17 (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP', "|\n", 31),
   "Subject: Re:|\n =?ISO-2022-JP?B?GyRCJCIbKEI=?=|\n A|\n" .
   " =?ISO-2022-JP?B?GyRCJCQbKEI=?=|\n I",
   '$lf="|\n", $bpl=31 (ISO-2022-JP)');


$str = 'Subject: Re: あ A い I う U え E お O';
is(mime_eco($str, 'UTF-8'),
   "Subject: " .
   "Re: =?UTF-8?B?44GC?= A =?UTF-8?B?44GE?= I =?UTF-8?B?44GG?= U\n" .
   " =?UTF-8?B?44GI?= E =?UTF-8?B?44GK?= O",
   'ASCII non-ASCII (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP'),
   "Subject: " .
   "Re: =?ISO-2022-JP?B?GyRCJCIbKEI=?= A =?ISO-2022-JP?B?GyRCJCQbKEI=?=\n" .
   " I =?ISO-2022-JP?B?GyRCJCYbKEI=?= U =?ISO-2022-JP?B?GyRCJCgbKEI=?= E\n" .
   " =?ISO-2022-JP?B?GyRCJCobKEI=?= O",
   'ASCII non-ASCII (ISO-2022-JP)');


$str = "Subject:\tア a\tイ i\tウ u\t\tA-I-U";
is(mime_eco($str, 'UTF-8'),
   "Subject:\t=?UTF-8?B?44Ki?= a\t=?UTF-8?B?44Kk?= i\t=?UTF-8?B?44Km?= u" .
   "\t\tA-I-U",
   'ASCII non-ASCII . "\t" (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP'),
   "Subject:\t=?ISO-2022-JP?B?GyRCJSIbKEI=?= a" .
   "\t=?ISO-2022-JP?B?GyRCJSQbKEI=?= i\n" .
   "\t=?ISO-2022-JP?B?GyRCJSYbKEI=?= u\t\tA-I-U",
   'ASCII non-ASCII . "\t" (ISO-2022-JP)');


$str = 'Subject: ' . 'x' x 50 . ' ' x 50 . 'あ';
is(mime_eco($str, 'UTF-8'),
   'Subject: ' . 'x' x 50 . ' ' x 49 . "\n =?UTF-8?B?44GC?=",
   'Long SP (UTF-8)');
is(mime_eco($str, 'ISO-2022-JP'),
   'Subject: ' . 'x' x 50 . ' ' x 49 . "\n =?ISO-2022-JP?B?44GC?=",
   'Long SP (ISO-2022-JP)');


my $from = 'From: OKAZAKI Sakurako  <sakura@example.jp>';
$str = $from . '  (岡崎 桜子)';
is(mime_eco($str, 'UTF-8'),
   $from . '  (=?UTF-8?B?5bKh5bSOIOahnA==?=' . "\n "
   . '=?UTF-8?B?5a2Q?=)',
   'structured header (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP'),
   $from . '  (=?ISO-2022-JP?B?GyRCMiwbKEI=?=' . "\n "
   . '=?ISO-2022-JP?B?GyRCOmobKEIgGyRCOnk7UhsoQg==?=)',
   'structured header (ISO-2022-JP)');


$str = '    (あ)  (((あ)))  (あ  (あ))  (あ  (あ))    ';
is(mime_eco($str, 'UTF-8'),
   '    (=?UTF-8?B?44GC?=)  (((=?UTF-8?B?44GC?=)))  (=?UTF-8?B?44GC?= ' .
   "\n" .
   ' (=?UTF-8?B?44GC?=))  (=?UTF-8?B?44GC?=  (=?UTF-8?B?44GC?=))    ',
   'comment in comment (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP'),
   '    (=?ISO-2022-JP?B?GyRCJCIbKEI=?=)' .
   '  (((=?ISO-2022-JP?B?GyRCJCIbKEI=?=))) ' .
   "\n" .
   ' (=?ISO-2022-JP?B?GyRCJCIbKEI=?=  (=?ISO-2022-JP?B?GyRCJCIbKEI=?=)) ' .
   "\n" .
   ' (=?ISO-2022-JP?B?GyRCJCIbKEI=?=  (=?ISO-2022-JP?B?GyRCJCIbKEI=?=))    ',
   'comment in comment (ISO-2022-JP)');


$str = 'From: Sakura <sakura@example.jp> (桜桜 (岡崎))';
is(mime_eco($str),
   'From: Sakura <sakura@example.jp> (=?UTF-8?B?5qGc5qGc?= (=?UTF-8?B?5bKh?=' .
   "\n" .
   ' =?UTF-8?B?5bSO?=))',
   'comment in comment (2) (UTF-8)');
is(mime_eco(encode('7bit-jis', decode_utf8($str)), 'ISO-2022-JP'),
   'From: Sakura <sakura@example.jp> (=?ISO-2022-JP?B?GyRCOnk6eRsoQg==?=' .
   "\n" .
   ' (=?ISO-2022-JP?B?GyRCMiw6ahsoQg==?=))',
   'comment in comment (2) (ISO-2022-JP)');


$str = 'From: A B <ab@example.jp> ' . "(\xa9"
    . '!"#$%&\'()*+,-./:;<=>?@[\]^_`{|}~)';
is(mime_eco($str, 'UTF-8?Q'),
   'From: A B <ab@example.jp> ' .
   '(=?UTF-8?Q?=A9!=22=23=24=25=26=27=28=29*+=2C-=2E?=' . "\n" .
   ' =?UTF-8?Q?/=3A=3B=3C=3D=3E=3F=40=5B=5C=5D=5E=5F=60=7B=7C=7D=7E?=)',
   'structured header (UTF-8?Q)');


$str = 'Subject: ' . "\xa9" . '!"#$%&\'()*+,-./:;<=>?@[\]^_`{|}~';
is(mime_eco($str, 'UTF-8?Q'),
   'Subject: =?UTF-8?Q?=A9!"#$%&\'()*+,-./:;<=3D>=3F@[\]^=5F`{|}~?=',
   'unstructured header (UTF-8?Q)');


$str = 'Subject: ' . "\x47\x72\xfc\xdf\x65";
is(mime_eco($str, 'ISO-8859-1'), 'Subject: =?ISO-8859-1?B?R3L832U=?=',
   'ISO-8859-1');
is(mime_eco($str, 'ISO-8859-1?Q'), 'Subject: =?ISO-8859-1?Q?Gr=FC=DFe?=',
   'ISO-8859-1?Q');


$str = 'Subject:' . " Hello \x47\x72\xfc\xdf\x65" x 3;
$encoded = mime_eco($str, 'ISO-8859-15?Q');
is($encoded,
   'Subject: Hello =?ISO-8859-15?Q?Gr=FC=DFe?= Hello ' .
   '=?ISO-8859-15?Q?Gr=FC=DFe?=' . "\n" .
   ' Hello =?ISO-8859-15?Q?Gr=FC=DFe?=',
   'ISO-8859-15?Q');

is(mime_deco($encoded), $str, 'ISO-8859-15?Q (decode)');


$str = 'Subject: ' . "\xe4\xbd\xa0\xe5\xa5\xbd\xe3\x80\x82";
$encoded = mime_eco(encode('euc-cn', decode_utf8($str)), 'GB2312');
is($encoded, 'Subject: =?GB2312?B?xOO6w6Gj?=', 'GB2312');

is(encode_utf8(decode('euc-cn', mime_deco($encoded))),
   $str, 'GB2312 (decode)');


$str = 'Subject: ' . "\xbe\xc8\xb3\xe7\xc7\xcf\xbd\xca\xb4\xcf\xb1\xee\x3f";
$encoded = mime_eco($str, 'EUC-KR');
is($encoded, 'Subject: =?EUC-KR?B?vsiz58fPvcq0z7HuPw==?=', 'EUC-KR');

is(mime_deco($encoded), $str, 'EUC-KR (decode)');


$str = 'Subject: ' . "\xe4\xbd\xa0\xe5\xa5\xbd\xe3\x80\x82";
$encoded = mime_eco(encode('big5', decode_utf8($str)), 'Big5');
is($encoded, 'Subject: =?Big5?B?p0GmbqFD?=', 'Big5');

is(encode_utf8(decode('big5', mime_deco($encoded))),
   $str, 'Big5 (decode)');


$str = "From: Sakura <sakura\@example.jp> (\xe6\xa1\x9c)";
is(mime_eco($str, 'UTF-8*ja-JP?Q'),
   'From: Sakura <sakura@example.jp> (=?UTF-8*ja-JP?Q?=E6=A1=9C?=)',
   'RFC2231\'s language');

$str = "Subject: Sakura (\xe6\xa1\x9c)"
    . " Hello (\xe4\xbd\xa0\xe5\xa5\xbd\xe3\x80\x82)";
$encoded = "Subject: Sakura =?ISO-2022-JP*ja?B?KBskQjp5GyhCKQ==?="
    . " Hello =?GB2312?B?KMTjusOhoyk=?=";

is(mime_deco($encoded, \&cb), $str, 'decode (multiple charsets)');

sub cb {
    my ($encoded_word, $charset, $language, $decoded_word) = @_;
    encode_utf8(decode($charset, $decoded_word));
}


$str = "Subject: あ\tあ";
is(mime_eco($str, 'UTF-8?Q'),
   'Subject: =?UTF-8?Q?=E3=81=82=09=E3=81=82?=', 'UTF-8?Q + TAB');


$str = "Subject: あ ) (あ";
$encoded = mime_eco($str, 'UTF-8?Q');
is(mime_deco($encoded), $str, 'UTF-8?Q + parenthesis');


my $str_j;

$str = 'Subject: AあIいUうEえOお a AあIいU e';
$str_j = encode('7bit-jis', decode_utf8($str));
$encoded = mime_eco($str_j, 'ISO-2022-JP');
is($encoded,
   "Subject: " .
   "=?ISO-2022-JP?B?QRskQiQiGyhCSRskQiQkGyhCVRskQiQmGyhCRRskQiQoGyhC?=\n" .
   " =?ISO-2022-JP?B?TxskQiQqGyhC?= a " .
   "=?ISO-2022-JP?B?QRskQiQiGyhCSRskQiQkGyhC?=\n" .
   " =?ISO-2022-JP?B?VQ==?= e",
   'ISO-2022-JP encode + folding 1');

is(mime_deco($encoded), $str_j, 'ISO-2022-JP decode + folding 1');

$str = 'Subject: aあaあaあaあ  ';
$str_j = encode('7bit-jis', decode_utf8($str));
$encoded = mime_eco($str_j, 'ISO-2022-JP');
is($encoded,
   "Subject: " .
   "=?ISO-2022-JP?B?YRskQiQiGyhCYRskQiQiGyhCYRskQiQiGyhCYQ==?=\n" .
   " =?ISO-2022-JP?B?GyRCJCIbKEI=?=  ",
   'ISO-2022-JP encode + folding 2');

is(mime_deco($encoded), $str_j, 'ISO-2022-JP decode + folding 2');


$str = 'Subject: ｱあ000000ｱｱあｱあ';
$str_j = encode('7bit-jis', decode_utf8($str));
$encoded = mime_eco($str_j, 'ISO-2022-JP');
is($encoded,
   "Subject: " .
   "=?ISO-2022-JP?B?GyhJMRskQiQiGyhCMDAwMDAwGyhJMTEbJEIkIhsoSTEbKEI=?=\n" .
   " =?ISO-2022-JP?B?GyRCJCIbKEI=?=",
   'ISO-2022-JP encode + folding 3');

is(mime_deco($encoded), $str_j, 'ISO-2022-JP decode + folding 3');


$str = "Subject:" . ' ' x 200 . 'a   あ';
$encoded = mime_eco($str);
is($encoded,
   "Subject:" . ' ' x 200 . "a\n" . '   =?UTF-8?B?44GC?=',
   'very long whitespace');


$str = 'Subject: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa あ ';
$str_j = encode('7bit-jis', decode_utf8($str));
$encoded = mime_eco($str_j, 'ISO-2022-JP');
is($encoded,
   "Subject: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n" .
   " =?ISO-2022-JP?B?GyRCJCIbKEI=?= ",
   'ISO-2022-JP encode + folding 4');
