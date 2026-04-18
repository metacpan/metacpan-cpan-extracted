######################################################################
#
# 9023_cheatsheet_km.t
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
#
# ឯកសារយោងរហ័សសម្រាប់ Jacode4e::RoundTrip (ភាសាខ្មែរ)
# តេស្តនេះក៏ដើរតួជាឯកសារយោងរហ័សសម្រាប់អ្នកប្រើភាសាខ្មែរផងដែរ។
######################################################################

# ឯកសារនេះត្រូវបានអ៊ិនកូដក្នុង UTF-8។
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ======================================================================
# ឯកសារយោងរហ័សសម្រាប់ Jacode4e::RoundTrip (ភាសាខ្មែរ)
# ======================================================================
#
# [របៀបប្រើប្រាស់មូលដ្ឋាន]
#
#   use FindBin;
#   use lib "$FindBin::Bin/lib";
#   use Jacode4e::RoundTrip;
#
#   $char_count = Jacode4e::RoundTrip::convert(\$line, $OUTPUT_encoding, $INPUT_encoding);
#   $char_count = Jacode4e::RoundTrip::convert(\$line, $OUTPUT_encoding, $INPUT_encoding, { %option });
#
#   $line             : ខ្សែអក្សរដែលត្រូវបំលែង (ឆ្លងកាត់តាមឯកសារយោង, ត្រូវបានសរសេរជាន់លើ)
#   $OUTPUT_encoding  : ឈ្មោះការអ៊ិនកូដលទ្ធផល
#   $INPUT_encoding   : ឈ្មោះការអ៊ិនកូដទិន្នន័យ
#   $char_count       : ចំនួនតួអក្សរបន្ទាប់ពីការបំលែង
#
# [បញ្ជីឈ្មោះការអ៊ិនកូដ]
#
#   ហ្សុីយ      សេចក្តីអធិប្បាយ
#   ---------   ---------------------------------------------------
#   cp932x      CP932X (បន្ថែមទៅ JIS X 0213, ការផ្លាស់ប្តូរតែមួយ 0x9C5A)
#   cp932       Microsoft CP932 (Windows-31J / ឈ្មោះ IANA)
#   cp932ibm    IBM CP932
#   cp932nec    NEC CP932
#   sjis2004    JISC Shift_JIS-2004
#   cp00930     IBM CP00930 (CP00290+CP00300, CCSID 5026 katakana)
#   keis78      HITACHI KEIS78
#   keis83      HITACHI KEIS83
#   keis90      HITACHI KEIS90
#   jef         FUJITSU JEF (12pt, ប្រើ OUTPUT_SHIFTING សម្រាប់កូដផ្លាស់ប្តូរ)
#   jef9p       FUJITSU JEF ( 9pt, ប្រើ OUTPUT_SHIFTING សម្រាប់កូដផ្លាស់ប្តូរ)
#   jipsj       NEC JIPS(J)
#   jipse       NEC JIPS(E)
#   letsj       UNISYS LetsJ
#   utf8        UTF-8.0 (UTF-8 ធម្មតា)
#   utf8.1      UTF-8.1 (ការបំលែងផ្អែកលើការធ្វើផែនទី Shift_JIS-Unicode មិនមែន CP932)
#   utf8jp      UTF-8-SPUA-JP (JIS X 0213 ធ្វើផែនទីទៅ Unicode SPUA)
#
# [ជម្រើស]
#
#   សោ               តម្លៃ / ការពណ៌នា
#   ---------------  ---------------------------------------------------
#   INPUT_LAYOUT     ប្លង់កំណត់ត្រាបញ្ចូល ('S'=SBCS, 'D'=DBCS)
#   OUTPUT_SHIFTING  ប្រសិនបើពិត, បញ្ចូលកូដការផ្លាស់ប្តូរជុំវិញ DBCS ក្នុងលទ្ធផល
#   SPACE            កូដចន្លោះ DBCS/MBCS (ខ្សែបន្ទាត់គោល ២)
#   GETA             និមិត្តសញ្ញា geta សម្រាប់តួអក្សរដែលមិនអាចធ្វើផែនទីបាន
#   OVERRIDE_MAPPING ការប្តូរជំនួសសម្រាប់តួអក្សរ { "\x12\x34"=>"\x56\x78" }
#
# [ការព្រមាន: ការបំលែងទៅវិញទៅមក]
#
#   មានការបំលែងដែលបាត់បង់ (ឧ. CP932 មាន 398 តួអក្សរដែលមិនអាចបំលែងបានត្រឡប់)។
# [ភាពខុសគ្នារវាង Jacode4e និង Jacode4e::RoundTrip]
#
#   Jacode4e              : ការបំលែងឯកទិសដ្ឋានរហ័ស។ មានការបាត់បង់សម្រាប់
#                           តួអក្សរមួយចំនួន (ឧ. CP932 មាន 398 ការធ្វើផែនទីដែល
#                           មិនអាចត្រឡប់វិញ)។
#   Jacode4e::RoundTrip   : ធានាភាពស្មោះត្រង់ទៅ-មក តាមរយៈ Unicode pivot។
#                           A->B->A តែងតែដូចគ្នា។ យឺតជាង Jacode4e,
#                           ប៉ុន្តែប្រើនៅពេលទិន្នន័យត្រូវការធ្វើដំណើរទៅ-មក។
#
#   ប្រសិនបើការបំលែងទៅវិញទៅមកមិនចាំបាច់, ប្រើម៉ូឌុល Jacode4e។
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
        ["\x81\x40", 'cp00930', 'cp932', {}, "\x40\x40", 'cp932(8140)->cp00930 គ្មានការផ្លាស់ប្តូរ(4040)'],
        ["\x81\x40\x31", 'cp00930', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0E\x40\x40\x0F\xF1",
            'cp932(814031)->cp00930 OUTPUT_SHIFTING(0E40400FF1)'],
        ["\x81\x40\x31", 'keis83', 'cp932', {}, "\xA1\xA1\xF1",
            'cp932(814031)->keis83 គ្មានការផ្លាស់ប្តូរ(A1A1F1)'],
        ["\x81\x40\x31", 'keis83', 'cp932', {'OUTPUT_SHIFTING'=>1}, "\x0A\x42\xA1\xA1\x0A\x41\xF1",
            'cp932(814031)->keis83 OUTPUT_SHIFTING(0A42A1A10A41F1)'],
        ["\x81\x60", 'utf8', 'cp932', {'INPUT_LAYOUT'=>'D'}, "\xE3\x80\x9C",
            'cp932(8160 រលកខ្លី)->utf8(E3809C U+301C)'],
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

use Jacode4e::RoundTrip;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want,$desc) = @{$test};
    my $got = $give;
    my $return = Jacode4e::RoundTrip::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);
    ok(($return > 0) and ($got eq $want),
        sprintf('%s => return=%d got=(%s) want=(%s)',
            $desc, $return,
            uc unpack('H*',$got),
            uc unpack('H*',$want),
        )
    );
}

__END__
