######################################################################
#
# 9027_cheatsheet_si.t
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
#
# Jacode4e ඉක්මන් යොමු (සිංහල)
# මෙම පරීක්ෂණය සිංහල භාෂා පරිශීලකයින් සඳහා ඉක්මන් යොමු ලෙසද ක්‍රියා කරයි.
######################################################################

# මෙම ගොනුව UTF-8 符号化ක් සමඟ ලියා ඇත.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ======================================================================
# Jacode4e ඉක්මන් යොමු (සිංහල)
# ======================================================================
#
# [මූලික භාවිතය]
#
#   use FindBin;
#   use lib "$FindBin::Bin/lib";
#   use Jacode4e;
#
#   $char_count = Jacode4e::convert(\$line, $OUTPUT_encoding, $INPUT_encoding);
#   $char_count = Jacode4e::convert(\$line, $OUTPUT_encoding, $INPUT_encoding, { %option });
#
#   $line             : පරිවර්තනය කළ යුතු string (යොමුව හරහා යවනු ලැබේ, නේවාසිකව ප්‍රතිස්ථාපනය)
#   $OUTPUT_encoding  : ප්‍රතිදාන කේතනය නාමය
#   $INPUT_encoding   : ආදාන කේතනය නාමය
#   $char_count       : පරිවර්තනයෙන් පසු අක්ෂර සංඛ්‍යාව
#
# [කේතනය නාම ලැයිස්තුව]
#
#   කෙටි නාමය   අදහස
#   ----------   ---------------------------------------------------
#   cp932x       CP932X (JIS X 0213 දක්වා දීර්ඝ කිරීම, තනි shift 0x9C5A)
#   cp932        Microsoft CP932 (Windows-31J / IANA ලියාපදිංචි නාමය)
#   cp932ibm     IBM CP932
#   cp932nec     NEC CP932
#   sjis2004     JISC Shift_JIS-2004
#   cp00930      IBM CP00930 (CP00290+CP00300, CCSID 5026 katakana)
#   keis78       HITACHI KEIS78
#   keis83       HITACHI KEIS83
#   keis90       HITACHI KEIS90
#   jef          FUJITSU JEF (12pt, OUTPUT_SHIFTING සමඟ shift codes)
#   jef9p        FUJITSU JEF ( 9pt, OUTPUT_SHIFTING සමඟ shift codes)
#   jipsj        NEC JIPS(J)
#   jipse        NEC JIPS(E)
#   letsj        UNISYS LetsJ
#   utf8         UTF-8.0 (සාමාන්‍ය UTF-8)
#   utf8.1       UTF-8.1 (CP932 නොව Shift_JIS-Unicode සිතියම් ගැනීම මත පදනම්)
#   utf8jp       UTF-8-SPUA-JP (JIS X 0213 Unicode SPUA වෙත සිතියම් ගත කර ඇත)
#
# [විකල්පයන්]
#
#   යතුර             අගය / විස්තරය
#   ---------------  ---------------------------------------------------
#   INPUT_LAYOUT     ආදාන වාර්තා සැකැස්ම ('S'=SBCS, 'D'=DBCS)
#   OUTPUT_SHIFTING  සත්‍ය නම් ප්‍රතිදානයේ DBCS අනුක්‍රමය වටා shift codes ඇතුළත් කරන්න
#   SPACE            DBCS/MBCS ඉඩ කේතය (binary string)
#   GETA             සිතියම් ගත කළ නොහැකි අක්ෂර සඳහා geta සංකේතය
#   OVERRIDE_MAPPING අක්ෂර අනුව ප්‍රතිස්ථාපනය { "\x12\x34"=>"\x56\x78" }
#
# [අනතුරු ඇඟවීම: ද්විදිශානල පරිවර්තනය]
#
#   හානිකර පරිවර්තනයන් තිබේ (උදා. CP932 හි ආපසු හැරවිය නොහැකි mapping 398ක් ඇත)。
#   ද්විදිශානල පරිවර්තනය සඳහා Jacode4e::RoundTrip module භාවිත කරන්න.
#
# ======================================================================

BEGIN {
    use vars qw(@test);
    @test = (
        ["\x81\x40", 'jef',    'cp932', {},                    "\xA1\xA1", 'cp932(8140)->jef(A1A1)'],
        ["\x81\x40", 'keis83', 'cp932', {},                    "\xA1\xA1", 'cp932(8140)->keis83(A1A1)'],
        ["\x81\x40", 'jipsj',  'cp932', {},                    "\x21\x21", 'cp932(8140)->jipsj(2121)'],
        ["\x81\x40", 'utf8',   'cp932', {},                    "\xE3\x80\x80", 'cp932(8140)->utf8(E38080)'],
        ["\x81\x40", 'jef',    'cp932', {'SPACE'=>"\x40\x40"}, "\x40\x40", 'cp932(8140)->jef SPACE=4040'],
        ["\xFC\xFC", 'jef',    'cp932', {'GETA'=>"\xFE\xFE"},  "\xFE\xFE", 'cp932(FCFC)->jef GETA=FEFE'],
        ["\x81\x40\x31", 'jef', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x28\xA1\xA1\x29\xF1",
            'cp932(814031)->jef OUTPUT_SHIFTING(28A1A129F1)'],
        ["\xA1\xA1\xF1", 'cp932', 'jef', {'INPUT_LAYOUT'=>'DS'}, "\x81\x40\x31",
            'jef(A1A1F1) INPUT_LAYOUT=DS->cp932(814031)'],
        ["\x81\x40", 'cp00930', 'cp932', {}, "\x40\x40", 'cp932(8140)->cp00930 shift නැතිව(4040)'],
        ["\x81\x40\x31", 'cp00930', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0E\x40\x40\x0F\xF1",
            'cp932(814031)->cp00930 OUTPUT_SHIFTING(0E40400FF1)'],
        ["\x81\x40\x31", 'keis83', 'cp932', {}, "\xA1\xA1\xF1",
            'cp932(814031)->keis83 shift නැතිව(A1A1F1)'],
        ["\x81\x40\x31", 'keis83', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0A\x42\xA1\xA1\x0A\x41\xF1",
            'cp932(814031)->keis83 OUTPUT_SHIFTING(0A42A1A10A41F1)'],
        ["\x81\x60", 'utf8', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE3\x80\x9C",
            'cp932(8160 රළු ඉරි)->utf8(E3809C U+301C)'],
        # utf8 vs utf8.1: cp932(815C/8161/817C) differ between MS-CP932 and JIS-Shift_JIS mapping
        # cp932(815C)=― : utf8->U+2015 HORIZONTAL BAR, utf8.1->U+2014 EM DASH
        ["\x81\x5C", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x95", 'cp932(815C)->utf8(E28095 U+2015 HORIZONTAL BAR)'],
        ["\x81\x5C", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x94", 'cp932(815C)->utf8.1(E28094 U+2014 EM DASH)'],
        # cp932(8161)=∥ : utf8->U+2225 PARALLEL TO, utf8.1->U+2016 DOUBLE VERTICAL LINE
        ["\x81\x61", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x88\xA5", 'cp932(8161)->utf8(E288A5 U+2225 PARALLEL TO)'],
        ["\x81\x61", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x80\x96", 'cp932(8161)->utf8.1(E28096 U+2016 DOUBLE VERTICAL LINE)'],
        # cp932(817C)=－ : utf8->U+FF0D FULLWIDTH HYPHEN-MINUS, utf8.1->U+2212 MINUS SIGN
        ["\x81\x7C", 'utf8',   'cp932', {'INPUT_LAYOUT'=>'D'}, "\xEF\xBC\x8D", 'cp932(817C)->utf8(EFBC8D U+FF0D FULLWIDTH HYPHEN-MINUS)'],
        ["\x81\x7C", 'utf8.1', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE2\x88\x92", 'cp932(817C)->utf8.1(E28892 U+2212 MINUS SIGN)'],
        # cp932x(9C5A815C/8161/817C): utf8/utf8.1 mapping is inverted compared to cp932
        ["\x9C\x5A\x81\x5C", 'utf8',   'cp932x', {}, "\xE2\x80\x94", 'cp932x(9C5A815C)->utf8(E28094 U+2014 EM DASH)'],
        ["\x9C\x5A\x81\x5C", 'utf8.1', 'cp932x', {}, "\xE2\x80\x95", 'cp932x(9C5A815C)->utf8.1(E28095 U+2015 HORIZONTAL BAR)'],
        ["\x9C\x5A\x81\x61", 'utf8',   'cp932x', {}, "\xE2\x80\x96", 'cp932x(9C5A8161)->utf8(E28096 U+2016 DOUBLE VERTICAL LINE)'],
        ["\x9C\x5A\x81\x61", 'utf8.1', 'cp932x', {}, "\xE2\x88\xA5", 'cp932x(9C5A8161)->utf8.1(E288A5 U+2225 PARALLEL TO)'],
        ["\x9C\x5A\x81\x7C", 'utf8',   'cp932x', {}, "\xE2\x88\x92", 'cp932x(9C5A817C)->utf8(E28892 U+2212 MINUS SIGN)'],
        ["\x9C\x5A\x81\x7C", 'utf8.1', 'cp932x', {}, "\xEF\xBC\x8D", 'cp932x(9C5A817C)->utf8.1(EFBC8D U+FF0D FULLWIDTH HYPHEN-MINUS)'],
        ["\x81\x40", 'utf8jp', 'cp932', {}, "\xF3\xB0\x84\x80",
            'cp932(8140)->utf8jp(F3B08480 SPUA)'],
    );
    $|=1;
    print "1..",scalar(@test),"\n";
    my $testno=1;
    sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }
}

use Jacode4e;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want,$desc) = @{$test};
    my $got = $give;
    my $return = Jacode4e::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);
    ok(($return > 0) and ($got eq $want),
        sprintf('%s => return=%d got=(%s) want=(%s)',
            $desc, $return,
            uc unpack('H*',$got),
            uc unpack('H*',$want),
        )
    );
}

__END__
