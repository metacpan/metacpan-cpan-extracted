######################################################################
#
# CP932NEC_by_Unicode.pl
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# cp932 to Unicode table
# ftp://ftp.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP932.TXT
# https://support.microsoft.com/ja-jp/help/170559/prb-conversion-problem-between-shift-jis-and-unicode

use strict;
use File::Basename;

my %CP932NEC_by_Unicode = ();

open(FILE,"@{[File::Basename::dirname(__FILE__)]}/ftp.__ftp.unicode.org_Public_MAPPINGS_VENDORS_MICSFT_WINDOWS_CP932.TXT") || die;
while (<FILE>) {
    chomp;
    next if /^#/;
    my($cp932, $Unicode, $Unicode_name) = split(/\t/, $_);
    next if $Unicode_name eq '#UNDEFINED';
    next if $Unicode_name eq '#DBCS LEAD BYTE';
    if ($cp932 =~ /^0x([0123456789ABCDEF]{2}|[0123456789ABCDEF]{4})$/) {
        my $cp932_hex = $1;
        if ($Unicode =~ /^0x([0123456789ABCDEF]{4})$/) {
            $CP932NEC_by_Unicode{$1} = $cp932_hex;
        }
        else {
            die;
        }
    }
    else {
        die;
    }
}
close(FILE);

open(FILE,"@{[File::Basename::dirname(__FILE__)]}/prb-conversion-problem-between-shift-jis-and-unicode.txt") || die;
while (<FILE>) {
    chomp;
    next if /^#/;
    if (my($cp932a, $Unicode, $cp932b) = / 0x([0123456789abcdef]{4}) .+? U\+([0123456789abcdef]{4}) .+? 0x([0123456789abcdef]{4}) /x) {
        $CP932NEC_by_Unicode{ uc($Unicode) } = uc($cp932b);
    }
}
close(FILE);

# WAVE DASH
#
# 2014-October-6
# The character U+301C WAVE DASH was encoded to represent JIS C 6226-1978
# 1-33. However, the representative glyph is inverted relative to the
# original source. The glyph will be modified in future editions to match the
# JIS source. The glyph shown below on the left is the incorrect glyph.
# The corrected glyph is shown on the right. (See document L2/14-198 for
# further context for this change.) 
#
# http://www.unicode.org/versions/Unicode8.0.0/erratafixed.html

delete $CP932NEC_by_Unicode{'FF5E'};   # FULLWIDTH TILDE
$CP932NEC_by_Unicode{'301C'} = '8160'; # WAVE DASH

my %CP932NEC = (
    '2170' => 'EEEF', # U+2170 Small Roman Numeral One
    '2171' => 'EEF0', # U+2171 Small Roman Numeral Two
    '2172' => 'EEF1', # U+2172 Small Roman Numeral Three
    '2173' => 'EEF2', # U+2173 Small Roman Numeral Four
    '2174' => 'EEF3', # U+2174 Small Roman Numeral Five
    '2175' => 'EEF4', # U+2175 Small Roman Numeral Six
    '2176' => 'EEF5', # U+2176 Small Roman Numeral Seven
    '2177' => 'EEF6', # U+2177 Small Roman Numeral Eight
    '2178' => 'EEF7', # U+2178 Small Roman Numeral Nine
    '2179' => 'EEF8', # U+2179 Small Roman Numeral Ten
    'FFE4' => 'EEFA', # U+FFE4 Fullwidth Broken Bar
    'FF07' => 'EEFB', # U+FF07 Fullwidth Apostrophe
    'FF02' => 'EEFC', # U+FF02 Fullwidth Quotation Mark
    '7E8A' => 'ED40', # U+7E8A CJK Unified Ideograph
    '891C' => 'ED41', # U+891C CJK Unified Ideograph
    '9348' => 'ED42', # U+9348 CJK Unified Ideograph
    '9288' => 'ED43', # U+9288 CJK Unified Ideograph
    '84DC' => 'ED44', # U+84DC CJK Unified Ideograph
    '4FC9' => 'ED45', # U+4FC9 CJK Unified Ideograph
    '70BB' => 'ED46', # U+70BB CJK Unified Ideograph
    '6631' => 'ED47', # U+6631 CJK Unified Ideograph
    '68C8' => 'ED48', # U+68C8 CJK Unified Ideograph
    '92F9' => 'ED49', # U+92F9 CJK Unified Ideograph
    '66FB' => 'ED4A', # U+66FB CJK Unified Ideograph
    '5F45' => 'ED4B', # U+5F45 CJK Unified Ideograph
    '4E28' => 'ED4C', # U+4E28 CJK Unified Ideograph
    '4EE1' => 'ED4D', # U+4EE1 CJK Unified Ideograph
    '4EFC' => 'ED4E', # U+4EFC CJK Unified Ideograph
    '4F00' => 'ED4F', # U+4F00 CJK Unified Ideograph
    '4F03' => 'ED50', # U+4F03 CJK Unified Ideograph
    '4F39' => 'ED51', # U+4F39 CJK Unified Ideograph
    '4F56' => 'ED52', # U+4F56 CJK Unified Ideograph
    '4F92' => 'ED53', # U+4F92 CJK Unified Ideograph
    '4F8A' => 'ED54', # U+4F8A CJK Unified Ideograph
    '4F9A' => 'ED55', # U+4F9A CJK Unified Ideograph
    '4F94' => 'ED56', # U+4F94 CJK Unified Ideograph
    '4FCD' => 'ED57', # U+4FCD CJK Unified Ideograph
    '5040' => 'ED58', # U+5040 CJK Unified Ideograph
    '5022' => 'ED59', # U+5022 CJK Unified Ideograph
    '4FFF' => 'ED5A', # U+4FFF CJK Unified Ideograph
    '501E' => 'ED5B', # U+501E CJK Unified Ideograph
    '5046' => 'ED5C', # U+5046 CJK Unified Ideograph
    '5070' => 'ED5D', # U+5070 CJK Unified Ideograph
    '5042' => 'ED5E', # U+5042 CJK Unified Ideograph
    '5094' => 'ED5F', # U+5094 CJK Unified Ideograph
    '50F4' => 'ED60', # U+50F4 CJK Unified Ideograph
    '50D8' => 'ED61', # U+50D8 CJK Unified Ideograph
    '514A' => 'ED62', # U+514A CJK Unified Ideograph
    '5164' => 'ED63', # U+5164 CJK Unified Ideograph
    '519D' => 'ED64', # U+519D CJK Unified Ideograph
    '51BE' => 'ED65', # U+51BE CJK Unified Ideograph
    '51EC' => 'ED66', # U+51EC CJK Unified Ideograph
    '5215' => 'ED67', # U+5215 CJK Unified Ideograph
    '529C' => 'ED68', # U+529C CJK Unified Ideograph
    '52A6' => 'ED69', # U+52A6 CJK Unified Ideograph
    '52C0' => 'ED6A', # U+52C0 CJK Unified Ideograph
    '52DB' => 'ED6B', # U+52DB CJK Unified Ideograph
    '5300' => 'ED6C', # U+5300 CJK Unified Ideograph
    '5307' => 'ED6D', # U+5307 CJK Unified Ideograph
    '5324' => 'ED6E', # U+5324 CJK Unified Ideograph
    '5372' => 'ED6F', # U+5372 CJK Unified Ideograph
    '5393' => 'ED70', # U+5393 CJK Unified Ideograph
    '53B2' => 'ED71', # U+53B2 CJK Unified Ideograph
    '53DD' => 'ED72', # U+53DD CJK Unified Ideograph
    'FA0E' => 'ED73', # U+FA0E CJK compatibility Ideograph
    '549C' => 'ED74', # U+549C CJK Unified Ideograph
    '548A' => 'ED75', # U+548A CJK Unified Ideograph
    '54A9' => 'ED76', # U+54A9 CJK Unified Ideograph
    '54FF' => 'ED77', # U+54FF CJK Unified Ideograph
    '5586' => 'ED78', # U+5586 CJK Unified Ideograph
    '5759' => 'ED79', # U+5759 CJK Unified Ideograph
    '5765' => 'ED7A', # U+5765 CJK Unified Ideograph
    '57AC' => 'ED7B', # U+57AC CJK Unified Ideograph
    '57C8' => 'ED7C', # U+57C8 CJK Unified Ideograph
    '57C7' => 'ED7D', # U+57C7 CJK Unified Ideograph
    'FA0F' => 'ED7E', # U+FA0F CJK compatibility Ideograph
    'FA10' => 'ED80', # U+FA10 CJK compatibility Ideograph
    '589E' => 'ED81', # U+589E CJK Unified Ideograph
    '58B2' => 'ED82', # U+58B2 CJK Unified Ideograph
    '590B' => 'ED83', # U+590B CJK Unified Ideograph
    '5953' => 'ED84', # U+5953 CJK Unified Ideograph
    '595B' => 'ED85', # U+595B CJK Unified Ideograph
    '595D' => 'ED86', # U+595D CJK Unified Ideograph
    '5963' => 'ED87', # U+5963 CJK Unified Ideograph
    '59A4' => 'ED88', # U+59A4 CJK Unified Ideograph
    '59BA' => 'ED89', # U+59BA CJK Unified Ideograph
    '5B56' => 'ED8A', # U+5B56 CJK Unified Ideograph
    '5BC0' => 'ED8B', # U+5BC0 CJK Unified Ideograph
    '752F' => 'ED8C', # U+752F CJK Unified Ideograph
    '5BD8' => 'ED8D', # U+5BD8 CJK Unified Ideograph
    '5BEC' => 'ED8E', # U+5BEC CJK Unified Ideograph
    '5C1E' => 'ED8F', # U+5C1E CJK Unified Ideograph
    '5CA6' => 'ED90', # U+5CA6 CJK Unified Ideograph
    '5CBA' => 'ED91', # U+5CBA CJK Unified Ideograph
    '5CF5' => 'ED92', # U+5CF5 CJK Unified Ideograph
    '5D27' => 'ED93', # U+5D27 CJK Unified Ideograph
    '5D53' => 'ED94', # U+5D53 CJK Unified Ideograph
    'FA11' => 'ED95', # U+FA11 CJK compatibility Ideograph
    '5D42' => 'ED96', # U+5D42 CJK Unified Ideograph
    '5D6D' => 'ED97', # U+5D6D CJK Unified Ideograph
    '5DB8' => 'ED98', # U+5DB8 CJK Unified Ideograph
    '5DB9' => 'ED99', # U+5DB9 CJK Unified Ideograph
    '5DD0' => 'ED9A', # U+5DD0 CJK Unified Ideograph
    '5F21' => 'ED9B', # U+5F21 CJK Unified Ideograph
    '5F34' => 'ED9C', # U+5F34 CJK Unified Ideograph
    '5F67' => 'ED9D', # U+5F67 CJK Unified Ideograph
    '5FB7' => 'ED9E', # U+5FB7 CJK Unified Ideograph
    '5FDE' => 'ED9F', # U+5FDE CJK Unified Ideograph
    '605D' => 'EDA0', # U+605D CJK Unified Ideograph
    '6085' => 'EDA1', # U+6085 CJK Unified Ideograph
    '608A' => 'EDA2', # U+608A CJK Unified Ideograph
    '60DE' => 'EDA3', # U+60DE CJK Unified Ideograph
    '60D5' => 'EDA4', # U+60D5 CJK Unified Ideograph
    '6120' => 'EDA5', # U+6120 CJK Unified Ideograph
    '60F2' => 'EDA6', # U+60F2 CJK Unified Ideograph
    '6111' => 'EDA7', # U+6111 CJK Unified Ideograph
    '6137' => 'EDA8', # U+6137 CJK Unified Ideograph
    '6130' => 'EDA9', # U+6130 CJK Unified Ideograph
    '6198' => 'EDAA', # U+6198 CJK Unified Ideograph
    '6213' => 'EDAB', # U+6213 CJK Unified Ideograph
    '62A6' => 'EDAC', # U+62A6 CJK Unified Ideograph
    '63F5' => 'EDAD', # U+63F5 CJK Unified Ideograph
    '6460' => 'EDAE', # U+6460 CJK Unified Ideograph
    '649D' => 'EDAF', # U+649D CJK Unified Ideograph
    '64CE' => 'EDB0', # U+64CE CJK Unified Ideograph
    '654E' => 'EDB1', # U+654E CJK Unified Ideograph
    '6600' => 'EDB2', # U+6600 CJK Unified Ideograph
    '6615' => 'EDB3', # U+6615 CJK Unified Ideograph
    '663B' => 'EDB4', # U+663B CJK Unified Ideograph
    '6609' => 'EDB5', # U+6609 CJK Unified Ideograph
    '662E' => 'EDB6', # U+662E CJK Unified Ideograph
    '661E' => 'EDB7', # U+661E CJK Unified Ideograph
    '6624' => 'EDB8', # U+6624 CJK Unified Ideograph
    '6665' => 'EDB9', # U+6665 CJK Unified Ideograph
    '6657' => 'EDBA', # U+6657 CJK Unified Ideograph
    '6659' => 'EDBB', # U+6659 CJK Unified Ideograph
    'FA12' => 'EDBC', # U+FA12 CJK compatibility Ideograph
    '6673' => 'EDBD', # U+6673 CJK Unified Ideograph
    '6699' => 'EDBE', # U+6699 CJK Unified Ideograph
    '66A0' => 'EDBF', # U+66A0 CJK Unified Ideograph
    '66B2' => 'EDC0', # U+66B2 CJK Unified Ideograph
    '66BF' => 'EDC1', # U+66BF CJK Unified Ideograph
    '66FA' => 'EDC2', # U+66FA CJK Unified Ideograph
    '670E' => 'EDC3', # U+670E CJK Unified Ideograph
    'F929' => 'EDC4', # U+F929 CJK compatibility Ideograph
    '6766' => 'EDC5', # U+6766 CJK Unified Ideograph
    '67BB' => 'EDC6', # U+67BB CJK Unified Ideograph
    '6852' => 'EDC7', # U+6852 CJK Unified Ideograph
    '67C0' => 'EDC8', # U+67C0 CJK Unified Ideograph
    '6801' => 'EDC9', # U+6801 CJK Unified Ideograph
    '6844' => 'EDCA', # U+6844 CJK Unified Ideograph
    '68CF' => 'EDCB', # U+68CF CJK Unified Ideograph
    'FA13' => 'EDCC', # U+FA13 CJK compatibility Ideograph
    '6968' => 'EDCD', # U+6968 CJK Unified Ideograph
    'FA14' => 'EDCE', # U+FA14 CJK compatibility Ideograph
    '6998' => 'EDCF', # U+6998 CJK Unified Ideograph
    '69E2' => 'EDD0', # U+69E2 CJK Unified Ideograph
    '6A30' => 'EDD1', # U+6A30 CJK Unified Ideograph
    '6A6B' => 'EDD2', # U+6A6B CJK Unified Ideograph
    '6A46' => 'EDD3', # U+6A46 CJK Unified Ideograph
    '6A73' => 'EDD4', # U+6A73 CJK Unified Ideograph
    '6A7E' => 'EDD5', # U+6A7E CJK Unified Ideograph
    '6AE2' => 'EDD6', # U+6AE2 CJK Unified Ideograph
    '6AE4' => 'EDD7', # U+6AE4 CJK Unified Ideograph
    '6BD6' => 'EDD8', # U+6BD6 CJK Unified Ideograph
    '6C3F' => 'EDD9', # U+6C3F CJK Unified Ideograph
    '6C5C' => 'EDDA', # U+6C5C CJK Unified Ideograph
    '6C86' => 'EDDB', # U+6C86 CJK Unified Ideograph
    '6C6F' => 'EDDC', # U+6C6F CJK Unified Ideograph
    '6CDA' => 'EDDD', # U+6CDA CJK Unified Ideograph
    '6D04' => 'EDDE', # U+6D04 CJK Unified Ideograph
    '6D87' => 'EDDF', # U+6D87 CJK Unified Ideograph
    '6D6F' => 'EDE0', # U+6D6F CJK Unified Ideograph
    '6D96' => 'EDE1', # U+6D96 CJK Unified Ideograph
    '6DAC' => 'EDE2', # U+6DAC CJK Unified Ideograph
    '6DCF' => 'EDE3', # U+6DCF CJK Unified Ideograph
    '6DF8' => 'EDE4', # U+6DF8 CJK Unified Ideograph
    '6DF2' => 'EDE5', # U+6DF2 CJK Unified Ideograph
    '6DFC' => 'EDE6', # U+6DFC CJK Unified Ideograph
    '6E39' => 'EDE7', # U+6E39 CJK Unified Ideograph
    '6E5C' => 'EDE8', # U+6E5C CJK Unified Ideograph
    '6E27' => 'EDE9', # U+6E27 CJK Unified Ideograph
    '6E3C' => 'EDEA', # U+6E3C CJK Unified Ideograph
    '6EBF' => 'EDEB', # U+6EBF CJK Unified Ideograph
    '6F88' => 'EDEC', # U+6F88 CJK Unified Ideograph
    '6FB5' => 'EDED', # U+6FB5 CJK Unified Ideograph
    '6FF5' => 'EDEE', # U+6FF5 CJK Unified Ideograph
    '7005' => 'EDEF', # U+7005 CJK Unified Ideograph
    '7007' => 'EDF0', # U+7007 CJK Unified Ideograph
    '7028' => 'EDF1', # U+7028 CJK Unified Ideograph
    '7085' => 'EDF2', # U+7085 CJK Unified Ideograph
    '70AB' => 'EDF3', # U+70AB CJK Unified Ideograph
    '710F' => 'EDF4', # U+710F CJK Unified Ideograph
    '7104' => 'EDF5', # U+7104 CJK Unified Ideograph
    '715C' => 'EDF6', # U+715C CJK Unified Ideograph
    '7146' => 'EDF7', # U+7146 CJK Unified Ideograph
    '7147' => 'EDF8', # U+7147 CJK Unified Ideograph
    'FA15' => 'EDF9', # U+FA15 CJK compatibility Ideograph
    '71C1' => 'EDFA', # U+71C1 CJK Unified Ideograph
    '71FE' => 'EDFB', # U+71FE CJK Unified Ideograph
    '72B1' => 'EDFC', # U+72B1 CJK Unified Ideograph
    '72BE' => 'EE40', # U+72BE CJK Unified Ideograph
    '7324' => 'EE41', # U+7324 CJK Unified Ideograph
    'FA16' => 'EE42', # U+FA16 CJK compatibility Ideograph
    '7377' => 'EE43', # U+7377 CJK Unified Ideograph
    '73BD' => 'EE44', # U+73BD CJK Unified Ideograph
    '73C9' => 'EE45', # U+73C9 CJK Unified Ideograph
    '73D6' => 'EE46', # U+73D6 CJK Unified Ideograph
    '73E3' => 'EE47', # U+73E3 CJK Unified Ideograph
    '73D2' => 'EE48', # U+73D2 CJK Unified Ideograph
    '7407' => 'EE49', # U+7407 CJK Unified Ideograph
    '73F5' => 'EE4A', # U+73F5 CJK Unified Ideograph
    '7426' => 'EE4B', # U+7426 CJK Unified Ideograph
    '742A' => 'EE4C', # U+742A CJK Unified Ideograph
    '7429' => 'EE4D', # U+7429 CJK Unified Ideograph
    '742E' => 'EE4E', # U+742E CJK Unified Ideograph
    '7462' => 'EE4F', # U+7462 CJK Unified Ideograph
    '7489' => 'EE50', # U+7489 CJK Unified Ideograph
    '749F' => 'EE51', # U+749F CJK Unified Ideograph
    '7501' => 'EE52', # U+7501 CJK Unified Ideograph
    '756F' => 'EE53', # U+756F CJK Unified Ideograph
    '7682' => 'EE54', # U+7682 CJK Unified Ideograph
    '769C' => 'EE55', # U+769C CJK Unified Ideograph
    '769E' => 'EE56', # U+769E CJK Unified Ideograph
    '769B' => 'EE57', # U+769B CJK Unified Ideograph
    '76A6' => 'EE58', # U+76A6 CJK Unified Ideograph
    'FA17' => 'EE59', # U+FA17 CJK compatibility Ideograph
    '7746' => 'EE5A', # U+7746 CJK Unified Ideograph
    '52AF' => 'EE5B', # U+52AF CJK Unified Ideograph
    '7821' => 'EE5C', # U+7821 CJK Unified Ideograph
    '784E' => 'EE5D', # U+784E CJK Unified Ideograph
    '7864' => 'EE5E', # U+7864 CJK Unified Ideograph
    '787A' => 'EE5F', # U+787A CJK Unified Ideograph
    '7930' => 'EE60', # U+7930 CJK Unified Ideograph
    'FA18' => 'EE61', # U+FA18 CJK compatibility Ideograph
    'FA19' => 'EE62', # U+FA19 CJK compatibility Ideograph
    'FA1A' => 'EE63', # U+FA1A CJK compatibility Ideograph
    '7994' => 'EE64', # U+7994 CJK Unified Ideograph
    'FA1B' => 'EE65', # U+FA1B CJK compatibility Ideograph
    '799B' => 'EE66', # U+799B CJK Unified Ideograph
    '7AD1' => 'EE67', # U+7AD1 CJK Unified Ideograph
    '7AE7' => 'EE68', # U+7AE7 CJK Unified Ideograph
    'FA1C' => 'EE69', # U+FA1C CJK compatibility Ideograph
    '7AEB' => 'EE6A', # U+7AEB CJK Unified Ideograph
    '7B9E' => 'EE6B', # U+7B9E CJK Unified Ideograph
    'FA1D' => 'EE6C', # U+FA1D CJK compatibility Ideograph
    '7D48' => 'EE6D', # U+7D48 CJK Unified Ideograph
    '7D5C' => 'EE6E', # U+7D5C CJK Unified Ideograph
    '7DB7' => 'EE6F', # U+7DB7 CJK Unified Ideograph
    '7DA0' => 'EE70', # U+7DA0 CJK Unified Ideograph
    '7DD6' => 'EE71', # U+7DD6 CJK Unified Ideograph
    '7E52' => 'EE72', # U+7E52 CJK Unified Ideograph
    '7F47' => 'EE73', # U+7F47 CJK Unified Ideograph
    '7FA1' => 'EE74', # U+7FA1 CJK Unified Ideograph
    'FA1E' => 'EE75', # U+FA1E CJK compatibility Ideograph
    '8301' => 'EE76', # U+8301 CJK Unified Ideograph
    '8362' => 'EE77', # U+8362 CJK Unified Ideograph
    '837F' => 'EE78', # U+837F CJK Unified Ideograph
    '83C7' => 'EE79', # U+83C7 CJK Unified Ideograph
    '83F6' => 'EE7A', # U+83F6 CJK Unified Ideograph
    '8448' => 'EE7B', # U+8448 CJK Unified Ideograph
    '84B4' => 'EE7C', # U+84B4 CJK Unified Ideograph
    '8553' => 'EE7D', # U+8553 CJK Unified Ideograph
    '8559' => 'EE7E', # U+8559 CJK Unified Ideograph
    '856B' => 'EE80', # U+856B CJK Unified Ideograph
    'FA1F' => 'EE81', # U+FA1F CJK compatibility Ideograph
    '85B0' => 'EE82', # U+85B0 CJK Unified Ideograph
    'FA20' => 'EE83', # U+FA20 CJK compatibility Ideograph
    'FA21' => 'EE84', # U+FA21 CJK compatibility Ideograph
    '8807' => 'EE85', # U+8807 CJK Unified Ideograph
    '88F5' => 'EE86', # U+88F5 CJK Unified Ideograph
    '8A12' => 'EE87', # U+8A12 CJK Unified Ideograph
    '8A37' => 'EE88', # U+8A37 CJK Unified Ideograph
    '8A79' => 'EE89', # U+8A79 CJK Unified Ideograph
    '8AA7' => 'EE8A', # U+8AA7 CJK Unified Ideograph
    '8ABE' => 'EE8B', # U+8ABE CJK Unified Ideograph
    '8ADF' => 'EE8C', # U+8ADF CJK Unified Ideograph
    'FA22' => 'EE8D', # U+FA22 CJK compatibility Ideograph
    '8AF6' => 'EE8E', # U+8AF6 CJK Unified Ideograph
    '8B53' => 'EE8F', # U+8B53 CJK Unified Ideograph
    '8B7F' => 'EE90', # U+8B7F CJK Unified Ideograph
    '8CF0' => 'EE91', # U+8CF0 CJK Unified Ideograph
    '8CF4' => 'EE92', # U+8CF4 CJK Unified Ideograph
    '8D12' => 'EE93', # U+8D12 CJK Unified Ideograph
    '8D76' => 'EE94', # U+8D76 CJK Unified Ideograph
    'FA23' => 'EE95', # U+FA23 CJK compatibility Ideograph
    '8ECF' => 'EE96', # U+8ECF CJK Unified Ideograph
    'FA24' => 'EE97', # U+FA24 CJK compatibility Ideograph
    'FA25' => 'EE98', # U+FA25 CJK compatibility Ideograph
    '9067' => 'EE99', # U+9067 CJK Unified Ideograph
    '90DE' => 'EE9A', # U+90DE CJK Unified Ideograph
    'FA26' => 'EE9B', # U+FA26 CJK compatibility Ideograph
    '9115' => 'EE9C', # U+9115 CJK Unified Ideograph
    '9127' => 'EE9D', # U+9127 CJK Unified Ideograph
    '91DA' => 'EE9E', # U+91DA CJK Unified Ideograph
    '91D7' => 'EE9F', # U+91D7 CJK Unified Ideograph
    '91DE' => 'EEA0', # U+91DE CJK Unified Ideograph
    '91ED' => 'EEA1', # U+91ED CJK Unified Ideograph
    '91EE' => 'EEA2', # U+91EE CJK Unified Ideograph
    '91E4' => 'EEA3', # U+91E4 CJK Unified Ideograph
    '91E5' => 'EEA4', # U+91E5 CJK Unified Ideograph
    '9206' => 'EEA5', # U+9206 CJK Unified Ideograph
    '9210' => 'EEA6', # U+9210 CJK Unified Ideograph
    '920A' => 'EEA7', # U+920A CJK Unified Ideograph
    '923A' => 'EEA8', # U+923A CJK Unified Ideograph
    '9240' => 'EEA9', # U+9240 CJK Unified Ideograph
    '923C' => 'EEAA', # U+923C CJK Unified Ideograph
    '924E' => 'EEAB', # U+924E CJK Unified Ideograph
    '9259' => 'EEAC', # U+9259 CJK Unified Ideograph
    '9251' => 'EEAD', # U+9251 CJK Unified Ideograph
    '9239' => 'EEAE', # U+9239 CJK Unified Ideograph
    '9267' => 'EEAF', # U+9267 CJK Unified Ideograph
    '92A7' => 'EEB0', # U+92A7 CJK Unified Ideograph
    '9277' => 'EEB1', # U+9277 CJK Unified Ideograph
    '9278' => 'EEB2', # U+9278 CJK Unified Ideograph
    '92E7' => 'EEB3', # U+92E7 CJK Unified Ideograph
    '92D7' => 'EEB4', # U+92D7 CJK Unified Ideograph
    '92D9' => 'EEB5', # U+92D9 CJK Unified Ideograph
    '92D0' => 'EEB6', # U+92D0 CJK Unified Ideograph
    'FA27' => 'EEB7', # U+FA27 CJK compatibility Ideograph
    '92D5' => 'EEB8', # U+92D5 CJK Unified Ideograph
    '92E0' => 'EEB9', # U+92E0 CJK Unified Ideograph
    '92D3' => 'EEBA', # U+92D3 CJK Unified Ideograph
    '9325' => 'EEBB', # U+9325 CJK Unified Ideograph
    '9321' => 'EEBC', # U+9321 CJK Unified Ideograph
    '92FB' => 'EEBD', # U+92FB CJK Unified Ideograph
    'FA28' => 'EEBE', # U+FA28 CJK compatibility Ideograph
    '931E' => 'EEBF', # U+931E CJK Unified Ideograph
    '92FF' => 'EEC0', # U+92FF CJK Unified Ideograph
    '931D' => 'EEC1', # U+931D CJK Unified Ideograph
    '9302' => 'EEC2', # U+9302 CJK Unified Ideograph
    '9370' => 'EEC3', # U+9370 CJK Unified Ideograph
    '9357' => 'EEC4', # U+9357 CJK Unified Ideograph
    '93A4' => 'EEC5', # U+93A4 CJK Unified Ideograph
    '93C6' => 'EEC6', # U+93C6 CJK Unified Ideograph
    '93DE' => 'EEC7', # U+93DE CJK Unified Ideograph
    '93F8' => 'EEC8', # U+93F8 CJK Unified Ideograph
    '9431' => 'EEC9', # U+9431 CJK Unified Ideograph
    '9445' => 'EECA', # U+9445 CJK Unified Ideograph
    '9448' => 'EECB', # U+9448 CJK Unified Ideograph
    '9592' => 'EECC', # U+9592 CJK Unified Ideograph
    'F9DC' => 'EECD', # U+F9DC CJK compatibility Ideograph
    'FA29' => 'EECE', # U+FA29 CJK compatibility Ideograph
    '969D' => 'EECF', # U+969D CJK Unified Ideograph
    '96AF' => 'EED0', # U+96AF CJK Unified Ideograph
    '9733' => 'EED1', # U+9733 CJK Unified Ideograph
    '973B' => 'EED2', # U+973B CJK Unified Ideograph
    '9743' => 'EED3', # U+9743 CJK Unified Ideograph
    '974D' => 'EED4', # U+974D CJK Unified Ideograph
    '974F' => 'EED5', # U+974F CJK Unified Ideograph
    '9751' => 'EED6', # U+9751 CJK Unified Ideograph
    '9755' => 'EED7', # U+9755 CJK Unified Ideograph
    '9857' => 'EED8', # U+9857 CJK Unified Ideograph
    '9865' => 'EED9', # U+9865 CJK Unified Ideograph
    'FA2A' => 'EEDA', # U+FA2A CJK compatibility Ideograph
    'FA2B' => 'EEDB', # U+FA2B CJK compatibility Ideograph
    '9927' => 'EEDC', # U+9927 CJK Unified Ideograph
    'FA2C' => 'EEDD', # U+FA2C CJK compatibility Ideograph
    '999E' => 'EEDE', # U+999E CJK Unified Ideograph
    '9A4E' => 'EEDF', # U+9A4E CJK Unified Ideograph
    '9AD9' => 'EEE0', # U+9AD9 CJK Unified Ideograph
    '9ADC' => 'EEE1', # U+9ADC CJK Unified Ideograph
    '9B75' => 'EEE2', # U+9B75 CJK Unified Ideograph
    '9B72' => 'EEE3', # U+9B72 CJK Unified Ideograph
    '9B8F' => 'EEE4', # U+9B8F CJK Unified Ideograph
    '9BB1' => 'EEE5', # U+9BB1 CJK Unified Ideograph
    '9BBB' => 'EEE6', # U+9BBB CJK Unified Ideograph
    '9C00' => 'EEE7', # U+9C00 CJK Unified Ideograph
    '9D70' => 'EEE8', # U+9D70 CJK Unified Ideograph
    '9D6B' => 'EEE9', # U+9D6B CJK Unified Ideograph
    'FA2D' => 'EEEA', # U+FA2D CJK compatibility Ideograph
    '9E19' => 'EEEB', # U+9E19 CJK Unified Ideograph
    '9ED1' => 'EEEC', # U+9ED1 CJK Unified Ideograph
);
for my $unicode (sort keys %CP932NEC) {
    $CP932NEC_by_Unicode{$unicode} = $CP932NEC{$unicode};
}

sub CP932NEC_by_Unicode {
    my($unicode) = @_;
    return $CP932NEC_by_Unicode{$unicode};
}

sub keys_of_CP932NEC_by_Unicode {
    return keys %CP932NEC_by_Unicode;
}

sub values_of_CP932NEC_by_Unicode {
    return values %CP932NEC_by_Unicode;
}

1;

__END__
