# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 04-AGLkit.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 10;
use Test::More::UTF8;
use Test::Exception;
use Storable qw(nstore retrieve);

BEGIN { use_ok('LaTeX::Replicase') }; ### Test 1
use LaTeX::Replicase qw(AGLkit); # :all

##### Test AGLtable() #####

### Test 2.1
my $op = {}; # glyphlist => 'glyphlist.txt', mate =>'symbol'|'hex'
my $agl = AGLkit( $op );
my $agl_ref = {
          'Atilde' => 195,
          'D' => 68,
          'afii10100' => 1107,
          'acute' => 180,
          'quotesingle' => 39,
          'minus' => 8722,
          'space' => 32,
          'afii10067' => 1074,
          'S' => 83,
          'm' => 109,
          'idieresis' => 239,
          'd' => 100,
          'a' => 97,
          'endash' => 8211,
          'onehalf' => 189,
          'aring' => 229,
          'asciitilde' => 126,
          'afii10089' => 1095,
          'afii10059' => 1034,
          'x' => 120,
          'afii10037' => 1059,
          'acircumflex' => 226,
          'comma' => 44,
          'afii10099' => 1106,
          'questiondown' => 191,
          'afii10079' => 1085,
          'afii10101' => 1108,
          'udieresis' => 252,
          'afii10029' => 1051,
          'parenright' => 41,
          'n' => 110,
          'braceleft' => 123,
          'afii10147' => 1138,
          'odieresis' => 246,
          'afii10103' => 1110,
          'L' => 76,
          'quotedblbase' => 8222,
          'afii10194' => 1123,
          'adieresis' => 228,
          'asterisk' => 42,
          'i' => 105,
          'z' => 122,
          'afii10040' => 1062,
          'afii10148' => 1140,
          'afii10036' => 1058,
          'ocircumflex' => 244,
          'six' => 54,
          'afii10195' => 1139,
          'zero' => 48,
          'p' => 112,
          'dagger' => 8224,
          'afii10146' => 1122,
          'afii10038' => 1060,
          'ucircumflex' => 251,
          'ordmasculine' => 186,
          'v' => 118,
          'Agrave' => 192,
          'afii10192' => 103,
          'slash' => 47,
          'C' => 67,
          'circumflex' => 710,
          'exclamdown' => 161,
          'afii10068' => 1075,
          'u' => 117,
          'at' => 64,
          'o' => 111,
          'afii10019' => 1042,
          'Ugrave' => 217,
          'yen' => 165,
          'afii10043' => 1065,
          'period' => 46,
          'icircumflex' => 238,
          'afii10041' => 1063,
          'afii10066' => 1073,
          'breve' => 728,
          'Oacute' => 211,
          'degree' => 176,
          's' => 115,
          'Odieresis' => 214,
          'afii10105' => 1112,
          'afii10102' => 1109,
          'afii10110' => 1118,
          'ring' => 730,
          'bracketleft' => 91,
          'quotesinglbase' => 8218,
          'afii10018' => 1041,
          'afii10087' => 1093,
          'afii10104' => 1111,
          'egrave' => 232,
          'w' => 119,
          'afii10069' => 1076,
          'dollar' => 36,
          'dotlessi' => 305,
          'onequarter' => 188,
          'afii10097' => 1103,
          'five' => 53,
          'grave' => 96,
          'dotaccent' => 729,
          'nine' => 57,
          'percent' => 37,
          'paragraph' => 182,
          'afii10039' => 1061,
          'one' => 49,
          'q' => 113,
          'afii10057' => 1032,
          'currency' => 164,
          'Igrave' => 204,
          'afii10027' => 1049,
          'aacute' => 225,
          'afii10077' => 1083,
          'hungarumlaut' => 733,
          'afii10042' => 1064,
          'afii10056' => 1031,
          'oacute' => 243,
          'multiply' => 215,
          'ccedilla' => 231,
          'afii10028' => 1050,
          'afii10096' => 1102,
          'uacute' => 250,
          'afii10078' => 1084,
          'bar' => 124,
          'afii10045' => 1067,
          'G' => 71,
          'afii10026' => 1048,
          'Egrave' => 200,
          'afii10098' => 1169,
          'afii10076' => 1082,
          'O' => 79,
          'tilde' => 732,
          'afii10044' => 1066,
          'cedilla' => 184,
          'j' => 106,
          'afii10058' => 1033,
          'registered' => 174,
          'afii10088' => 1094,
          'underscore' => 95,
          'fi' => 64257,
          'f' => 102,
          'afii10193' => 1119,
          'Ocircumflex' => 212,
          'iacute' => 237,
          'N' => 78,
          'g' => 103,
          'twosuperior' => 178,
          'quoteleft' => 8216,
          'afii10086' => 1092,
          'afii61352' => 8470,
          'afii10017' => 1040,
          'bullet' => 8226,
          'Thorn' => 222,
          'I' => 73,
          'afii10060' => 1035,
          'dieresis' => 168,
          'afii10031' => 1053,
          'germandbls' => 223,
          'afii10085' => 1091,
          'afii10033' => 1055,
          'afii10082' => 1088,
          'two' => 50,
          'three' => 51,
          'Y' => 89,
          'K' => 75,
          'afii10107' => 1114,
          'eight' => 56,
          'afii10084' => 1090,
          'ecircumflex' => 234,
          'r' => 114,
          'c' => 99,
          'seven' => 55,
          'Ntilde' => 209,
          'afii10094' => 1100,
          'periodcentered' => 183,
          'afii10022' => 1045,
          'e' => 101,
          'afii10072' => 1078,
          'afii10075' => 1081,
          'quotedblright' => 8221,
          'brokenbar' => 166,
          'afii10048' => 1070,
          'afii10025' => 1047,
          'afii10054' => 1029,
          'afii10046' => 1068,
          'afii10061' => 1036,
          'ampersand' => 38,
          'afii10030' => 1052,
          'afii10052' => 1027,
          'afii10095' => 1101,
          'Edieresis' => 203,
          'afii10055' => 1030,
          'afii10092' => 1098,
          'W' => 87,
          'T' => 84,
          'afii10024' => 1046,
          'less' => 60,
          'Otilde' => 213,
          'Icircumflex' => 206,
          'afii10063' => 953,
          'afii10074' => 1080,
          'Aacute' => 193,
          'l' => 108,
          'Idieresis' => 207,
          'greater' => 62,
          'onesuperior' => 185,
          'threesuperior' => 179,
          'P' => 80,
          'Z' => 90,
          'afii10047' => 1069,
          'quotedbl' => 34,
          'Ecircumflex' => 202,
          'quoteright' => 8217,
          'Ograve' => 210,
          'afii10832' => 1096,
          'afii10108' => 1115,
          'E' => 69,
          'Oslash' => 216,
          'mu' => 181,
          'M' => 77,
          'trademark' => 8482,
          'Uacute' => 218,
          'fl' => 64258,
          'edieresis' => 235,
          'afii10106' => 1113,
          'colon' => 58,
          'yacute' => 253,
          'otilde' => 245,
          'afii10053' => 1028,
          'J' => 74,
          'afii10080' => 1086,
          'afii10091' => 1097,
          'ydieresis' => 255,
          'X' => 88,
          'afii10065' => 1072,
          'thorn' => 254,
          'afii10062' => 1038,
          'ae' => 230,
          'backslash' => 92,
          'exclam' => 33,
          'Eth' => 208,
          'cent' => 162,
          'daggerdbl' => 8225,
          'eacute' => 233,
          'afii10051' => 1026,
          'afii10093' => 1099,
          'Ccedilla' => 199,
          'guillemotleft' => 171,
          'divide' => 247,
          'afii10064' => 948,
          'afii10073' => 1079,
          'Udieresis' => 220,
          'equal' => 61,
          'afii10023' => 1025,
          'Q' => 81,
          'afii10021' => 1044,
          'parenleft' => 40,
          'afii10071' => 1105,
          'quotedblleft' => 8220,
          'plus' => 43,
          'copyright' => 169,
          'braceright' => 125,
          'afii10109' => 1116,
          'Yacute' => 221,
          'agrave' => 224,
          'afii10034' => 1056,
          'B' => 66,
          'afii10020' => 1043,
          'Iacute' => 205,
          'threequarters' => 190,
          'afii10145' => 1039,
          'afii10070' => 1077,
          'afii10196' => 1141,
          'four' => 52,
          'guilsinglright' => 8250,
          'question' => 63,
          'afii10035' => 1057,
          'afii10081' => 1087,
          'afii10090' => 1096,
          't' => 116,
          'perthousand' => 8240,
          'h' => 104,
          'ordfeminine' => 170,
          'afii10050' => 1168,
          'afii10083' => 1089,
          'afii10032' => 1054,
          'Adieresis' => 196,
          'numbersign' => 35,
          'asciicircumb' => 94,
          'F' => 70,
          'section' => 167,
          'ellipsis' => 8230,
          'AE' => 198,
          'U' => 85,
          'caron' => 711,
          'eth' => 240,
          'Eacute' => 201,
          'guilsinglleft' => 8249,
          'Acircumflex' => 194,
          'ugrave' => 249,
          'ntilde' => 241,
          'afii10049' => 1071,
          'y' => 121,
          'ograve' => 242,
          'afii10831' => 1081,
          'oslash' => 248,
          'bracketright' => 93,
          'Aring' => 197,
          'semicolon' => 59,
          'ogonek' => 731,
          'logicalnot' => 172,
          'A' => 65,
          'afii10846' => 1241,
          'macron' => 175,
          'hyphen' => 45,
          'guillemotright' => 187,
          'igrave' => 236,
          'k' => 107,
          'emdash' => 8212,
          'dotlessj' => 63166,
          'plusminus' => 177,
          'b' => 98,
          'atilde' => 227,
          'sterling' => 163,
          'Ucircumflex' => 219,
          'H' => 72,
          'R' => 82,
          'V' => 86,
        };

is_deeply( $agl, $agl_ref, "Test #2.1: EMPTY options");

### Test 2.2
$op = {mate =>'blah-blah'};
$agl = AGLkit( $op );
is_deeply( $agl, $agl_ref, "Test #2.2: mate =>'blah-blah' -- BAD option");

my $glyphlist_ref = retrieve 't/glyphlist.dump';

### Test 2.3
my $agl_vs_glyphlist_ref = {};
for( keys %$agl_ref ) {

# Exceptions:
# asciicircumb => 94,
# afii10064 => ord('δ'), # echo -e "\u03B4" # a.? \uF6C5 see "Adobe Standard Cyrillic Font Specification"
# afii10063 => ord('ι'), # a.? \uF6C4
# afii10192 => ord('g'), # a.? \uF6C6
# afii10831 => ord('й'), # a.? \uF6C7
# afii10832 => ord('ш'), # a.? \uF6C8

	$agl_vs_glyphlist_ref->{$_} = (/^(?:afii10(?:063|064|192|831|832)|asciicircumb)$/i) ? $agl_ref->{$_} : $glyphlist_ref->{$_};
}

is_deeply( $agl_ref, $agl_vs_glyphlist_ref, "Test #2.3: agl_ref VS. glyphlist_ref");


### Test 2.4
$op = {mate =>'hex'}; # 'symbol'
$agl = AGLkit( $op );

for( values %$agl_ref ) {
	$_ = sprintf("%04X", $_);
}
is_deeply( $agl, $agl_ref, "Test #2.4: mate =>'hex' option");

### Test 2.5
$op = {mate =>'symbol'};
$agl = AGLkit( $op );

for( values %$agl_ref ) {
	$_ = chr(hex $_);
}
is_deeply( $agl, $agl_ref, "Test #2.5: mate =>'symbol' option");


### Test 3.1
$op = {glyphlist => 't/glyphlist.txt',};
$agl = AGLkit( $op );
is_deeply( $agl, $glyphlist_ref, "Test #3.1: glyphlist => 't/glyphlist.txt' option");


### Test 3.2
$op = {glyphlist => 't/glyphlist.txt', mate =>'blah-blah'};
$agl = AGLkit( $op );
is_deeply( $agl, $glyphlist_ref, "Test #3.2: glyphlist => 't/glyphlist.txt', mate =>'blah-blah' BAD option");


### Test 3.3
$op = {glyphlist => 't/glyphlist.txt', mate =>'hex'};
$agl = AGLkit( $op );

for my $v ( values %$glyphlist_ref ) {
	$v = join ' ', map{ sprintf("%04X", $_) } split /\s+/, $v;
}
is_deeply( $agl, $glyphlist_ref, "Test #3.3: glyphlist => 't/glyphlist.txt', mate =>'hex' options");


### Test 3.4
$op = {glyphlist => 't/glyphlist.txt', mate =>'symbol'};
$agl = AGLkit( $op );

for my $v ( values %$glyphlist_ref ) {
	$v = join '', map{ chr hex } split /\s+/, $v;
}
is_deeply( $agl, $glyphlist_ref, "Test #3.4: glyphlist => 't/glyphlist.txt', mate =>'symbol' options");

