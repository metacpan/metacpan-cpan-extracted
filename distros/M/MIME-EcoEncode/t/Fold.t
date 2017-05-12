#!/usr/bin/perl -w

# This script is written in utf8

use strict;
use warnings;

use Test::More tests => 14;
#use Test::More 'no_plan';
BEGIN { use_ok('MIME::EcoEncode::Fold') };

use Encode;
use MIME::EcoEncode::Fold;

my $in_utf8;
my $out_utf8;
my $in;
my $out;
my $str;

$in_utf8 =<<"END";

あああ00000aaaaaaあああ00000aaaaaaｱｱｱ00000aaあああ
ｱｱｱ00000aaaaaaaあああ00000aaaaaaaあああ00000aaaaｱｱ
00000aaaaaa00000aaaaaaaaa00000aaaaaaaaaaaaaaa00000
END


#
# test 2
#
$out_utf8 =<<"END";

あああ00000aaaaaaあああ0
0000aaaaaaｱｱｱ00000aaあ
ああ
ｱｱｱ00000aaaaaaaあああ
00000aaaaaaaあああ00000aaa
aｱｱ
00000aaaaaa00000aaaaaaaaa00000
aaaaaaaaaaaaaaa00000
END
$in = $in_utf8;
$out = $out_utf8;
is(mime_eco_fold($in, 'UTF-8', "\n", 30), $out,
   'UTF-8 "\n" 30');

#
# test 3
#
$out_utf8 =<<"END";

あああ00000aaaaaaあああ0
 0000aaaaaaｱｱｱ00000aa
 あああ
ｱｱｱ00000aaaaaaaあああ
 00000aaaaaaaあああ00000aa
 aaｱｱ
00000aaaaaa00000aaaaaaaaa00000
 aaaaaaaaaaaaaaa00000
END
$in = $in_utf8;
$out = $out_utf8;
is(mime_eco_fold($in, 'UTF-8', undef, 30), $out,
   'UTF-8 undef 30');

#
# test 4
#
$out_utf8 =<<"END";

あああ00000aaaaaa
あああ00000aaaaaaｱ
ｱｱ00000aaあああ
ｱｱｱ00000aaaaaaaあ
ああ00000aaaaaaaあ
ああ00000aaaaｱｱ
00000aaaaaa00000aaaaaaaaa00000
aaaaaaaaaaaaaaa00000
END
$in = encode('7bit-jis', decode_utf8($in_utf8));
$out = encode('7bit-jis', decode_utf8($out_utf8));
is(mime_eco_fold($in, 'ISO-2022-JP', "\n", 30), $out,
   'ISO-2022-JP "\n" 30');

#
# test 5
#
$out_utf8 =<<"END";

あああ00000aaaaaa
 あああ00000aaaaaa
 ｱｱｱ00000aaあああ
ｱｱｱ00000aaaaaaaあ
 ああ00000aaaaaaa
 あああ00000aaaaｱｱ
00000aaaaaa00000aaaaaaaaa00000
 aaaaaaaaaaaaaaa00000
END
$in = encode('7bit-jis', decode_utf8($in_utf8));
$out = encode('7bit-jis', decode_utf8($out_utf8));
is(mime_eco_fold($in, 'ISO-2022-JP', undef, 30), $out,
   'ISO-2022-JP undef 30');


#
# test 6
#
$out_utf8 =<<"END";

あああ00000aaaaaaあああ00000aa
aaaaｱｱｱ00000aaあああ
ｱｱｱ00000aaaaaaaあああ00000aaaa
aaaあああ00000aaaaｱｱ
00000aaaaaa00000aaaaaaaaa00000
aaaaaaaaaaaaaaa00000
END
$in = encode('cp932', decode_utf8($in_utf8));
$out = encode('cp932', decode_utf8($out_utf8));
is(mime_eco_fold($in, 'Shift_JIS', "\n", 30), $out,
   'Shift_JIS "\n" 30');


#
# test 7
#
$out_utf8 =<<"END";

あああ00000aaaaaaあああ00000aa
 aaaaｱｱｱ00000aaあああ
ｱｱｱ00000aaaaaaaあああ00000aaaa
 aaaあああ00000aaaaｱｱ
00000aaaaaa00000aaaaaaaaa00000
 aaaaaaaaaaaaaaa00000
END
$in = encode('cp932', decode_utf8($in_utf8));
$out = encode('cp932', decode_utf8($out_utf8));
is(mime_eco_fold($in, 'Shift_JIS', undef, 30), $out,
   'Shift_JIS undef 30');


$str = " \n ";
is(mime_eco_fold($str, 'UTF-8', undef, 30), $str, 'SP + "\n" + SP');

$str = "";
is(mime_eco_fold($str, 'UTF-8', undef, 30), $str, 'zero length');

$str = undef;
is(mime_eco_fold($str, 'UTF-8', undef, 30), "", 'undef');

$str = "test0\x0d";
is(mime_eco_fold($str, 'UTF-8', undef, 30), $str, '\x0d');

$str = "test0\x0a";
is(mime_eco_fold($str, 'UTF-8', undef, 30), $str, '\x0a');

$str = "test0\x0d\x0a";
is(mime_eco_fold($str, 'UTF-8', undef, 30), $str, '\x0d\x0a');

$in = "00000aaaaaa00000aaaaaaaaa00000aaaaaaaaaaaaaaa00000";
$out = "00000aaaaaa00000aaaaaaaaa00000\n aaaaaaaaaaaaaaa00000";
is(mime_eco_fold($in, 'UTF-8', undef, 30), $out, 'ASCII');
