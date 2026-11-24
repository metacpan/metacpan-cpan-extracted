# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 04-AGLkit.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.010;
use strict;
use warnings;

use utf8;

# use Test::More 'no_plan';
use Test::More tests => 15;
use Test::More::UTF8;
use Test::Exception;
use Test::Warn;
use Storable qw(nstore retrieve);
use Data::Dumper;

# Подключаем Test::File::ShareDir ДО загрузки модуля
use Test::File::ShareDir
    -share => {
#        -dist   => { 'LaTeX-Replicase' => 'share' },
        -module => { 'LaTeX::Replicase' => 'share' },
    };

### Test 1.1
BEGIN { use_ok('LaTeX::Replicase') };
use LaTeX::Replicase qw(AGLkit); # :all

use File::ShareDir qw(module_file); # dist_file

### Test 1.2
# my $glyphtounicode = dist_file('LaTeX-Replicase', 'glyphtounicode.dump');
my $glyphtounicode = module_file('LaTeX::Replicase', 'glyphtounicode.dump');
ok( -e $glyphtounicode, "Test #1.2 'AGLkit()': Verify that the file is successfully located in the local folders -- module file 'glyphtounicode.dump' found during test");

### Test 1.3
my $glyphtounicode_ref = retrieve $glyphtounicode;
is( scalar(keys %$glyphtounicode_ref), 5506, "Test #1.3 'AGLkit()': 'glyphtounicode.dump' file contains the necessary number of glyphs");

##### Test AGLtable() #####

### Test 2.1
my $op = {}; # glyphlist => 'glyphlist.txt', mate =>'symbol'|'hex'
my $agl = {};

warnings_are {
	$agl = AGLkit( $op );
} [], 'Checked carp warning for Test #2.1 AGLkit()';

is_deeply( $agl, $glyphtounicode_ref, "Test #2.1: with EMPTY options");


### Test 2.2
$op = {mate =>'blah-blah'};
$agl = AGLkit( $op );
is_deeply( $agl, $glyphtounicode_ref, "Test #2.2: mate =>'blah-blah' -- BAD option");

# glyph list for TESTs
	my $my_agl_ref = {
exclamdown => ord('¡'), # \u00A1
cent => ord('¢'), # \u00A2
sterling => ord('£'), # \u00A3
currency => ord('¤'), # \u00A4
yen => ord('¥'), # \u00A5
brokenbar => ord('¦'), # \u00A6
section => ord('§'), # \u00A7
dieresis => ord('¨'), # \u00A8
copyright => ord('©'), # \u00A9
ordfeminine => ord('ª'), # \u00AA
guillemotleft => ord('«'), # \u00AB
logicalnot => ord('¬'), # \u00AC
#	sfthyphen => ord(''), # \u00AD
registered => ord('®'), # \u00AE
macron => ord('¯'), # \u00AF
		#---
degree => ord('°'), # \u00B0
plusminus => ord('±'), # \u00B1
twosuperior => ord('²'), # \u00B2
threesuperior => ord('³'), # \u00B3
acute => ord('´'), # \u00B4
mu => ord('µ'), # \u00B5
paragraph => ord('¶'), # \u00B6
periodcentered => ord('·'), # \u00B7
cedilla => ord('¸'), # \u00B8
onesuperior => ord('¹'), # \u00B9
ordmasculine => ord('º'), # \u00BA
guillemotright => ord('»'), # \u00BB
onequarter => ord('¼'), # \u00BC
onehalf => ord('½'), # \u00BD
threequarters => ord('¾'), # \u00BE
questiondown => ord('¿'), # \u00BF
		#---
Agrave => ord('À'), # \u00C0
Aacute => ord('Á'), # \u00C1
Acircumflex => ord('Â'), # \u00C2
Atilde => ord('Ã'), # \u00C3
Adieresis => ord('Ä'), # \u00C4
		#---
Aring => ord('Å'), # \u00C5
AE => ord('Æ'), # \u00C6
Ccedilla => ord('Ç'), # \u00C7
Egrave => ord('È'), # \u00C8
Eacute => ord('É'), # \u00C9
Ecircumflex => ord('Ê'), # \u00CA
Edieresis => ord('Ë'), # \u00CB
Igrave => ord('Ì'), # \u00CC
Iacute => ord('Í'), # \u00CD
Icircumflex => ord('Î'), # \u00CE
Idieresis => ord('Ï'), # \u00CF
		#---
Eth => ord('Ð'), # \u00D0
Ntilde => ord('Ñ'), # \u00D1
Ograve => ord('Ò'), # \u00D2
Oacute => ord('Ó'), # \u00D3
Ocircumflex => ord('Ô'), # \u00D4
Otilde => ord('Õ'), # \u00D5
Odieresis => ord('Ö'), # \u00D6
multiply => ord('×'), # \u00D7
Oslash => ord('Ø'), # \u00D8
Ugrave => ord('Ù'), # \u00D9
Uacute => ord('Ú'), # \u00DA
Ucircumflex => ord('Û'), # \u00DB
Udieresis => ord('Ü'), # \u00DC
Yacute => ord('Ý'), # \u00DD
Thorn => ord('Þ'), # \u00DE
germandbls => ord('ß'), # \u00DF
		#---
agrave => ord('à'), # \u00E0
aacute => ord('á'), # \u00E1
acircumflex => ord('â'), # \u00E2
atilde => ord('ã'), # \u00E3
adieresis => ord('ä'), # \u00E4
aring => ord('å'), # \u00E5
ae => ord('æ'), # \u00E6
ccedilla => ord('ç'), # \u00E7
egrave => ord('è'), # \u00E8
eacute => ord('é'), # \u00E9
ecircumflex => ord('ê'), # \u00EA
edieresis => ord('ë'), # \u00EB
igrave => ord('ì'), # \u00EC
iacute => ord('í'), # \u00ED
icircumflex => ord('î'), # \u00EE
idieresis => ord('ï'), # \u00EF
		#---
eth => ord('ð'), # \u00F0
ntilde => ord('ñ'), # \u00F1
ograve => ord('ò'), # \u00F2
oacute => ord('ó'), # \u00F3
ocircumflex => ord('ô'), # \u00F4
otilde => ord('õ'), # \u00F5
odieresis => ord('ö'), # \u00F6
divide => ord('÷'), # \u00F7
oslash => ord('ø'), # \u00F8
ugrave => ord('ù'), # \u00F9
uacute => ord('ú'), # \u00FA
ucircumflex => ord('û'), # \u00FB
udieresis => ord('ü'), # \u00FC
yacute => ord('ý'), # \u00FD
thorn => ord('þ'), # \u00FE
ydieresis => ord('ÿ'), # \u00FF
		#---
# afii10064 => ord('δ'), # echo -e "\u03B4" # a.? \uF6C5 see "Adobe Standard Cyrillic Font Specification"
# afii10063 => ord('ι'), # a.? \uF6C4
# afii10192 => ord('g'), # a.? \uF6C6
# afii10831 => ord('й'), # a.? \uF6C7
# afii10832 => ord('ш'), # a.? \uF6C8
afii10846 => ord('ә'), # \u04D9
afii61352 => ord('№'), # \u2116
		# Symbol and Punctuation Glyph
minus => ord('−'), # \u2212
trademark => ord('™'), # 2122
bullet => ord('•'), # echo -e "\u2022"
ellipsis => ord('…'), # \u2026
endash => ord('–'), # \u2013
emdash => ord('—'), # \u2014
dagger => ord('†'), # \u2020
daggerdbl => ord('‡'), # \u2021
quotedblbase => ord('„'), # \u201E
quotedblleft => ord('“'), # \u201C
quotedblright => ord('”'), # \u201D
quoteleft => ord("‘"), # \u2018
quoteright => ord("’"), # \u2019
quotesinglbase => ord('‚'), # \u201A
perthousand => ord('‰'), # \u2030
guilsinglleft => ord('‹'), # \u2039
guilsinglright => ord('›'), # \u203A
circumflex => ord('ˆ'), # \u02C6
tilde => ord('˜'), # \u02DC
hungarumlaut => ord('˝'), # \u02DD
ring => ord('˚'), # \u02DA
caron => ord('ˇ'), # \u02C7
breve => ord('˘'), # \u02D8
dotaccent => ord('˙'), # \u02D9
ogonek => ord('˛'), # \u02DB
dotlessi => ord('ı'), # \u0131
# dotlessj => ord(''), # \uF6BE
# fi => ord('ﬁ'), # \uFB01
# fl => ord('ﬂ'), # \uFB02

	};

$my_agl_ref->{$_} = ord($_) for 'A'..'Z', 'a'..'z'; # ASCII Glyph Names: 65..90, 97..122

# also ASCII Glyph Names, but 32..64, 91..96, 123..126
@{$my_agl_ref}{qw(
space exclam quotedbl numbersign dollar percent ampersand quotesingle parenleft parenright
asterisk plus comma hyphen period slash zero one two three four five six seven eight nine
colon semicolon less equal greater question at
	bracketleft backslash bracketright asciicircumb underscore grave
braceleft bar braceright asciitilde
)} = ( ord(' ')..ord('@'), ord('[')..ord('`'), ord('{')..ord('~') ); #}

# Cyrillic Glyph Names: Uppercase (afiiXXXXX)
my $x = 10017; # start of 'А'...'Я' from afii10017 to afii10049
for( ord('А')..ord('Е'), ord('Ё'), ord('Ж')..ord('Я') ) {
	$my_agl_ref->{"afii$x"} = $_;
	++$x;
}
for('Ґ','Ђ','Ѓ','Є','Ѕ','І','Ї','Ј','Љ','Њ','Ћ','Ќ','Ў') { # from afii10050 to afii10062
	$my_agl_ref->{"afii$x"} = ord $_;
	++$x;
}
$x = 10145;
for('Џ','Ѣ','Ѳ','Ѵ') { # from afii10145 to afii10148
	$my_agl_ref->{"afii$x"} = ord $_;
	++$x;
}

# Cyrillic Glyph Names: Lowercase
$x = 10065; # start of "а"..."я" from afii10065 to afii10097
for( ord('а')..ord('е'), ord('ё'), ord('ж')..ord('я') ) {
	$my_agl_ref->{"afii$x"} = $_;
	++$x;
}
for('ґ','ђ','ѓ','є','ѕ','і','ї','ј','љ','њ','ћ','ќ','ў') { # from afii10098 to afii10110
	$my_agl_ref->{"afii$x"} = ord $_;
	++$x;
}
$x = 10193;
for('џ','ѣ','ѳ','ѵ') { # from afii10193 to afii10196
	$my_agl_ref->{"afii$x"} = ord $_;
	++$x;
}

### Test 2.3
my $agl_vs_glyphtounicode_ref = {};
for( keys %$my_agl_ref ) {

# Exceptions:
# asciicircumb => 94,
# afii10064 => ord('δ'), # echo -e "\u03B4" # a.? \uF6C5 see "Adobe Standard Cyrillic Font Specification"
# afii10063 => ord('ι'), # a.? \uF6C4
# afii10192 => ord('g'), # a.? \uF6C6
# afii10831 => ord('й'), # a.? \uF6C7
# afii10832 => ord('ш'), # a.? \uF6C8

#	$agl_vs_glyphlist_ref->{$_} = (/^(?:afii10(?:063|064|192|831|832)|asciicircumb)$/i) ? $my_agl_ref->{$_} : $glyphtounicode_ref->{$_};
	$agl_vs_glyphtounicode_ref->{$_} = $glyphtounicode_ref->{$_};
}

is_deeply( $my_agl_ref, $agl_vs_glyphtounicode_ref, "Test #2.3: my_agl_ref VS. glyphtounicode_ref");

### Test 2.4
$op = {mate =>'hex'}; # 'symbol'
$agl = AGLkit( $op );

for my $v ( values %$glyphtounicode_ref ) {
	$v = join ' ', map{ sprintf("%04X", $_) } split /\s+/, $v;
}
is_deeply( $agl, $glyphtounicode_ref, "Test #2.4: mate =>'hex' option");

### Test 2.5
$op = {mate =>'symbol'};
$agl = AGLkit( $op );

for my $v ( values %$glyphtounicode_ref ) {
	$v = join '', map{ chr hex } split /\s+/, $v;
}
is_deeply( $agl, $glyphtounicode_ref, "Test #2.5: mate =>'symbol' option");


### Test 3.1
my $glyphlist = 't/glyphlist.txt';
$op = {glyphlist => $glyphlist,};
$agl = AGLkit( $op );

$glyphtounicode_ref = retrieve $glyphtounicode;

# Fixed for 't/glyphlist.txt':
$glyphtounicode_ref->{dotlessj} = ord(''); # \uF6BE

is_deeply( $agl, $glyphtounicode_ref, "Test #3.1: glyphlist => 't/glyphlist.txt' option");

### Test 3.2
$op = {glyphlist => $glyphlist, mate =>'blah-blah'};
$agl = AGLkit( $op );
is_deeply( $agl, $glyphtounicode_ref, "Test #3.2: glyphlist => 't/glyphlist.txt', mate =>'blah-blah' BAD option");


### Test 3.3
$op = {glyphlist => $glyphlist, mate =>'hex'};
$agl = AGLkit( $op );

for my $v ( values %$glyphtounicode_ref ) {
	$v = join ' ', map{ sprintf("%04X", $_) } split /\s+/, $v;
}
is_deeply( $agl, $glyphtounicode_ref, "Test #3.3: glyphlist => 't/glyphlist.txt', mate =>'hex' options");


### Test 3.4
$agl = AGLkit( {glyphlist => $glyphlist, mate =>'symbol'} );

for my $v ( values %$glyphtounicode_ref ) {
	$v = join '', map{ chr hex } split /\s+/, $v;
}
is_deeply( $agl, $glyphtounicode_ref, "Test #3.4: glyphlist => 't/glyphlist.txt', mate =>'symbol' options");


### Test 3.5
# $agl = {};
# throws_ok {
#	$agl = AGLkit( {glyphlist => 't/blah-blah.txt'} );
# } qr/Can\'t find the AGL file:/, 'Checked croak for Test #3.5';

warnings_exist {
	$agl = AGLkit( {glyphlist => 't/blah-blah.txt'} );
} [qr/Can\'t find the AGL file:/], 'Checked carp warning for Test #3.5 AGLkit()';

$glyphtounicode_ref = retrieve $glyphtounicode;

is_deeply( $agl, $glyphtounicode_ref, "Test #3.5: 'AGLkit()' for BAD 'glyphlist' option");

###DEL###
# nstore( $agl, 'test.dump') or die "Не удалось сохранить данные: $!";
# open F, ">test.log";
# print F Dumper($agl);
# close F;
# exit;
