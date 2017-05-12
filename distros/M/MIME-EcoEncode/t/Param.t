#!/usr/bin/perl -w

# This script is written in utf8

use strict;
use warnings;

use Test::More tests => 19;
#use Test::More 'no_plan';
BEGIN { use_ok('MIME::EcoEncode::Param') };

use Encode;
use MIME::EcoEncode::Param;

my $in_utf8;
my $out_utf8;
my $in;
my $out;
my $str;
my $encoded;

$in_utf8 = " filename=あああ000aaあああ000aaｱｱｱ000aaあああ\n";

#
# test 2, 3
#
$in = $in_utf8;
$out =<<'END';
 filename*0*=UTF-8'ja'%E3%81%82%E3%81%82%E3%81%82;
 filename*1*=000aa%E3%81%82%E3%81%82%E3%81%82000a;
 filename*2*=a%EF%BD%B1%EF%BD%B1%EF%BD%B1000aa;
 filename*3*=%E3%81%82%E3%81%82%E3%81%82
END
$encoded = mime_eco_param($in, "UTF-8'ja'", "\n", 50);
is($encoded, $out, 'UTF-8\'ja\' "\n" 50');
is(mime_deco_param($encoded), $in, 'UTF-8\'ja\' "\n" 50 - decode');

#
# test 4, 5
#
$in = encode('7bit-jis', decode_utf8($in_utf8));
$out =<<'END';
 filename*0*=ISO-2022-JP''%1B$B$%22$%22%1B%28B;
 filename*1*=%1B$B$%22%1B%28B000aa;
 filename*2*=%1B$B$%22$%22$%22%1B%28B000aa;
 filename*3*=%1B%28I111%1B%28B000aa;
 filename*4*=%1B$B$%22$%22$%22%1B%28B
END
$encoded = mime_eco_param($in, "ISO-2022-JP", "\n", 50);
is($encoded, $out, 'ISO-2022-JP "\n" 50');
is(mime_deco_param($encoded), $in, 'ISO-2022-JP "\n" 50 - decode');

#
# test 6, 7
#
$in = encode('cp932', decode_utf8($in_utf8));
$out =<<'END';
 filename*0*=Shift_JIS''%82%A0%82%A0%82%A0000aa;
 filename*1*=%82%A0%82%A0%82%A0000aa%B1%B1%B1000a;
 filename*2*=a%82%A0%82%A0%82%A0
END
$encoded = mime_eco_param($in, "Shift_JIS", "\n", 50);
is($encoded, $out, 'Shift_JIS "\n" 50');
is(mime_deco_param($encoded), $in, 'Shift_JIS "\n" 50 - decode');



#
# RFC 2231 Section 3 example
#
$in =<<'END';
 URL*0="ftp://";
 URL*1="cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar"
END
$out =<<'END';
 URL="ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar"
END
is(mime_deco_param($in), $out, 'decode 1');


#
# RFC 2231 Section 4 example
#
$in =<<'END';
 title*=us-ascii'en-us'This%20is%20%2A%2A%2Afun%2A%2A%2A
END
$out =<<'END';
 title=This is ***fun***
END
is(mime_deco_param($in), $out, 'decode 2');


#
# RFC 2231 Section 4.1 example
#
$in =<<'END';
 title*0*=us-ascii'en'This%20is%20even%20more%20
 title*1*=%2A%2A%2Afun%2A%2A%2A%20
 title*2="isn't it!"
END
$out =<<'END';
 title="This is even more ***fun*** isn't it!"
END
is(mime_deco_param($in), $out, 'decode 3');


#
# RFC 2231 Section 4.1 example (corrected version, Errata ID: 590)
#
$in =<<'END';
 title*0*=us-ascii'en'This%20is%20even%20more%20;
 title*1*=%2A%2A%2Afun%2A%2A%2A%20;
 title*2="isn't it!"
END
$out =<<'END';
 title="This is even more ***fun*** isn't it!"
END
is(mime_deco_param($in), $out, 'decode 4');


$str = " \n ";
is(mime_eco_param($str), '  ', 'SP + "\n" + SP');

$str = "";
is(mime_eco_param($str), $str, 'zero length');

$str = undef;
is(mime_eco_param($str), "", 'undef');

$str = "test0\x0d";
is(mime_eco_param($str), $str, '\x0d');

$str = "test0\x0a";
is(mime_eco_param($str), $str, '\x0a');

$str = "test0\x0d\x0a";
is(mime_eco_param($str), $str, '\x0d\x0a');


$str = " name=\"=?UTF-8?B?5a+M5aOr5bGxXzIwMTMuanBlZw==?=\"";
is(mime_deco_param($str, 0), $str, 'decode B/Q - OFF');

$in = " name=\"=?UTF-8?B?5a+M5aOr5bGxXzIwMTMuanBlZw==?=\"";
$out = " name=\"\xe5\xaf\x8c\xe5\xa3\xab\xe5\xb1\xb1_2013.jpeg\"";
is(mime_deco_param($in, 1), $out, 'decode B/Q - ON');
