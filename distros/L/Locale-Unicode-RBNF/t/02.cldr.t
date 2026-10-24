#!perl
##----------------------------------------------------------------------------
## Unicode CLDR Rule-Based Number Format - t/02.cldr.t
##
## Expectations generated with ICU 79.1 (RuleBasedNumberFormat) fed with the
## same CLDR rules.
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use File::Spec;
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'Locale::Unicode::RBNF' ) || BAIL_OUT( 'Unable to load Locale::Unicode::RBNF' );
};

my $cldr = File::Spec->catdir( 't', 'cldr' );

my @formats = (
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 0, "z\x{00E9}ro" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 1, "un" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 16, "seize" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 17, "dix-sept" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 21, "vingt-et-un" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 71, "soixante-et-onze" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 80, "quatre-vingts" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 81, "quatre-vingt-un" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 91, "quatre-vingt-onze" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 100, "cent" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 101, "cent un" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 180, "cent quatre-vingts" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 200, "deux cents" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 201, "deux cent un" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 1000, "mille" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 1980, "mille neuf cent quatre-vingts" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 2026, "deux mille vingt-six" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 1000000, "un million" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 2000000, "deux millions" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', 1234567, "un million deux cent trente-quatre mille cinq cent soixante-sept" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'i', -42, "moins quarante-deux" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'd', 3.14, "trois virgule un quatre" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'd', 0.5, "z\x{00E9}ro virgule cinq" ],
    [ 'fr', 'spellout', '%spellout-numbering', 'd', -2.75, "moins deux virgule sept cinq" ],
    [ 'fr', 'spellout', '%spellout-cardinal-feminine', 'i', 1, "une" ],
    [ 'fr', 'spellout', '%spellout-cardinal-feminine', 'i', 21, "vingt-et-une" ],
    [ 'fr', 'spellout', '%spellout-cardinal-feminine', 'i', 71, "soixante-et-onze" ],
    [ 'fr', 'spellout', '%spellout-cardinal-feminine', 'i', 1001, "mille une" ],
    [ 'fr', 'spellout', '%spellout-ordinal-masculine', 'i', 1, "premier" ],
    [ 'fr', 'spellout', '%spellout-ordinal-masculine', 'i', 2, "deuxi\x{00E8}me" ],
    [ 'fr', 'spellout', '%spellout-ordinal-masculine', 'i', 21, "vingt-et-uni\x{00E8}me" ],
    [ 'fr', 'spellout', '%spellout-ordinal-masculine', 'i', 100, "centi\x{00E8}me" ],
    [ 'fr', 'spellout', '%spellout-ordinal-masculine', 'i', 1000, "milli\x{00E8}me" ],
    [ 'fr', 'spellout', '%spellout-ordinal-feminine', 'i', 1, "premi\x{00E8}re" ],
    [ 'fr', 'spellout', '%spellout-ordinal-feminine', 'i', 2, "deuxi\x{00E8}me" ],
    [ 'fr', 'spellout', '%spellout-ordinal-feminine', 'i', 80, "quatre-vingti\x{00E8}me" ],
    [ 'fr', 'spellout', '%spellout-numbering-year', 'i', 1100, "onze-cents" ],
    [ 'fr', 'spellout', '%spellout-numbering-year', 'i', 1789, "dix-sept-cent quatre-vingt-neuf" ],
    [ 'fr', 'spellout', '%spellout-numbering-year', 'i', 1999, "dix-neuf-cent quatre-vingt-dix-neuf" ],
    [ 'fr', 'spellout', '%spellout-numbering-year', 'i', 2026, "deux mille vingt-six" ],
    [ 'fr', 'ordinal', '%digits-ordinal-masculine', 'i', 1, "1er" ],
    [ 'fr', 'ordinal', '%digits-ordinal-masculine', 'i', 2, "2e" ],
    [ 'fr', 'ordinal', '%digits-ordinal-masculine', 'i', 21, "21e" ],
    [ 'fr', 'ordinal', '%digits-ordinal-feminine', 'i', 1, "1re" ],
    [ 'fr', 'ordinal', '%digits-ordinal-feminine', 'i', 2, "2e" ],
    [ 'fr_CH', 'spellout', '%spellout-numbering', 'i', 70, "septante" ],
    [ 'fr_CH', 'spellout', '%spellout-numbering', 'i', 80, "huitante" ],
    [ 'fr_CH', 'spellout', '%spellout-numbering', 'i', 90, "nonante" ],
    [ 'fr_CH', 'spellout', '%spellout-numbering', 'i', 99, "nonante-neuf" ],
    [ 'fr_CH', 'spellout', '%spellout-numbering', 'i', 1980, "mille neuf cent huitante" ],
    [ 'en', 'spellout', '%spellout-numbering', 'i', 0, "zero" ],
    [ 'en', 'spellout', '%spellout-numbering', 'i', 13, "thirteen" ],
    [ 'en', 'spellout', '%spellout-numbering', 'i', 21, "twenty-one" ],
    [ 'en', 'spellout', '%spellout-numbering', 'i', 101, "one hundred one" ],
    [ 'en', 'spellout', '%spellout-numbering', 'i', 1234, "one thousand two hundred thirty-four" ],
    [ 'en', 'spellout', '%spellout-numbering', 'i', 1000000, "one million" ],
    [ 'en', 'spellout', '%spellout-numbering', 'i', 1234567890, "one billion two hundred thirty-four million five hundred sixty-seven thousand eight hundred ninety" ],
    [ 'en', 'spellout', '%spellout-numbering', 'i', 1000000000000000000, "1,000,000,000,000,000,000" ],
    [ 'en', 'spellout', '%spellout-numbering', 'i', -7, "minus seven" ],
    [ 'en', 'spellout', '%spellout-numbering', 'd', 1.5, "one point five" ],
    [ 'en', 'spellout', '%spellout-numbering', 'd', 0.25, "zero point two five" ],
    [ 'en', 'spellout', '%spellout-numbering-verbose', 'i', 101, "one hundred and one" ],
    [ 'en', 'spellout', '%spellout-numbering-verbose', 'i', 1234, "one thousand two hundred and thirty-four" ],
    [ 'en', 'spellout', '%spellout-numbering-verbose', 'i', 2001, "two thousand and one" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 1, "first" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 2, "second" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 3, "third" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 4, "fourth" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 11, "eleventh" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 12, "twelfth" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 13, "thirteenth" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 20, "twentieth" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 21, "twenty-first" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 22, "twenty-second" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 100, "one hundredth" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 101, "one hundred first" ],
    [ 'en', 'spellout', '%spellout-ordinal', 'i', 1000, "one thousandth" ],
    [ 'en', 'spellout', '%spellout-numbering-year', 'i', 1900, "nineteen hundred" ],
    [ 'en', 'spellout', '%spellout-numbering-year', 'i', 1999, "nineteen ninety-nine" ],
    [ 'en', 'spellout', '%spellout-numbering-year', 'i', 2000, "two thousand" ],
    [ 'en', 'spellout', '%spellout-numbering-year', 'i', 2001, "two thousand one" ],
    [ 'en', 'spellout', '%spellout-numbering-year', 'i', 2026, "twenty twenty-six" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 1, "1st" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 2, "2nd" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 3, "3rd" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 4, "4th" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 11, "11th" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 12, "12th" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 13, "13th" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 21, "21st" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 22, "22nd" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 23, "23rd" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 101, "101st" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 111, "111th" ],
    [ 'en', 'ordinal', '%digits-ordinal', 'i', 1234, "1,234th" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 0, "\x{3007}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 1, "\x{4E00}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 10, "\x{5341}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 11, "\x{5341}\x{4E00}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 20, "\x{4E8C}\x{5341}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 100, "\x{767E}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 1000, "\x{5343}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 10000, "\x{4E00}\x{4E07}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 12345, "\x{4E00}\x{4E07}\x{4E8C}\x{5343}\x{4E09}\x{767E}\x{56DB}\x{5341}\x{4E94}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 100000000, "\x{4E00}\x{5104}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'i', 3000000, "\x{4E09}\x{767E}\x{4E07}" ],
    [ 'ja', 'spellout', '%spellout-numbering', 'd', 1.5, "\x{4E00}\x{30FB}\x{4E94}" ],
    [ 'ja', 'spellout', '%spellout-cardinal-financial', 'i', 1, "\x{58F1}" ],
    [ 'ja', 'spellout', '%spellout-cardinal-financial', 'i', 2, "\x{5F10}" ],
    [ 'ja', 'spellout', '%spellout-cardinal-financial', 'i', 10, "\x{62FE}" ],
    [ 'ja', 'spellout', '%spellout-cardinal-financial', 'i', 1000, "\x{58F1}\x{5343}" ],
    [ 'ja', 'spellout', '%spellout-cardinal-financial', 'i', 3000000, "\x{53C2}\x{767E}\x{842C}" ],
    [ 'ja', 'spellout', '%spellout-cardinal-financial', 'i', 10000000, "\x{58F1}\x{5343}\x{842C}" ],
    [ 'ja', 'spellout', '%spellout-cardinal-financial', 'i', 123456789, "\x{58F1}\x{5104}\x{5F10}\x{5343}\x{53C2}\x{767E}\x{56DB}\x{62FE}\x{4F0D}\x{842C}\x{516D}\x{5343}\x{4E03}\x{767E}\x{516B}\x{62FE}\x{4E5D}" ],
    [ 'ja', 'spellout', '%spellout-numbering-year', 'i', 1945, "\x{4E00}\x{4E5D}\x{56DB}\x{4E94}" ],
    [ 'ja', 'spellout', '%spellout-numbering-year', 'i', 2026, "\x{4E8C}\x{3007}\x{4E8C}\x{516D}" ],
    [ 'ja', 'ordinal', '%digits-ordinal', 'i', 1, "\x{7B2C}1" ],
    [ 'ja', 'ordinal', '%digits-ordinal', 'i', 10, "\x{7B2C}10" ],
    [ 'root', 'numbering_system', '%roman-upper', 'i', 1, "I" ],
    [ 'root', 'numbering_system', '%roman-upper', 'i', 4, "IV" ],
    [ 'root', 'numbering_system', '%roman-upper', 'i', 9, "IX" ],
    [ 'root', 'numbering_system', '%roman-upper', 'i', 14, "XIV" ],
    [ 'root', 'numbering_system', '%roman-upper', 'i', 40, "XL" ],
    [ 'root', 'numbering_system', '%roman-upper', 'i', 90, "XC" ],
    [ 'root', 'numbering_system', '%roman-upper', 'i', 400, "CD" ],
    [ 'root', 'numbering_system', '%roman-upper', 'i', 1994, "MCMXCIV" ],
    [ 'root', 'numbering_system', '%roman-upper', 'i', 2026, "MMXXVI" ],
    [ 'root', 'numbering_system', '%roman-upper', 'i', 3999, "MMMCMXCIX" ],
    [ 'root', 'numbering_system', '%roman-lower', 'i', 7, "vii" ],
    [ 'root', 'numbering_system', '%roman-lower', 'i', 49, "xlix" ],
    [ 'root', 'numbering_system', '%roman-lower', 'i', 2026, "mmxxvi" ],
    [ 'root', 'numbering_system', '%hebrew', 'i', 1, "\x{05D0}\x{05F3}" ],
    [ 'root', 'numbering_system', '%hebrew', 'i', 15, "\x{05D8}\x{05F4}\x{05D5}" ],
    [ 'root', 'numbering_system', '%hebrew', 'i', 16, "\x{05D8}\x{05F4}\x{05D6}" ],
    [ 'root', 'numbering_system', '%hebrew', 'i', 100, "\x{05E7}\x{05F3}" ],
    [ 'root', 'numbering_system', '%hebrew', 'i', 5786, "\x{05D4}\x{05F3}\x{05EA}\x{05E9}\x{05E4}\x{05F4}\x{05D5}" ],
    [ 'tr', 'spellout', '%spellout-numbering', 'i', 1, "bir" ],
    [ 'tr', 'spellout', '%spellout-numbering', 'i', 2, "iki" ],
    [ 'tr', 'spellout', '%spellout-numbering', 'i', 21, "yirmi bir" ],
    [ 'tr', 'spellout', '%spellout-numbering', 'i', 1000, "bin" ],
);

my @parses = (
    [ 'fr', 'spellout', 0, "deux mille vingt-six", 2026, 20, -1 ],
    [ 'fr', 'spellout', 0, "quatre-vingt-onze", 91, 17, -1 ],
    [ 'fr', 'spellout', 0, "soixante-et-onze", 71, 16, -1 ],
    [ 'fr', 'spellout', 0, "moins quarante-deux", -42, 19, -1 ],
    [ 'fr', 'spellout', 0, "trois virgule un quatre", 3.1400000000000001, 23, -1 ],
    [ 'fr', 'spellout', 0, "cent uni\x{00E8}me", 101, 11, -1 ],
    [ 'fr', 'spellout', 0, "n importe quoi", 0, 0, 0 ],
    [ 'fr', 'spellout', 1, "Deux Mille Vingt Six", 2026, 20, -1 ],
    [ 'fr', 'spellout', 1, "QUATRE VINGT ONZE", 91, 17, -1 ],
    [ 'fr', 'spellout', 1, "soixante\x{2011}et\x{2011}onze", 71, 16, -1 ],
    [ 'en', 'spellout', 0, "one thousand two hundred thirty-four", 1234, 36, -1 ],
    [ 'en', 'spellout', 0, "twenty-first", 21, 12, -1 ],
    [ 'en', 'spellout', 0, "minus seven", -7, 11, -1 ],
    [ 'en', 'spellout', 0, "one point five", 1.5, 14, -1 ],
    [ 'en', 'spellout', 1, "One Thousand, Two Hundred and Thirty Four", 1234, 41, -1 ],
    [ 'en', 'spellout', 1, "TWENTY FIRST", 21, 12, -1 ],
    [ 'ja', 'spellout', 0, "\x{4E00}\x{4E07}\x{4E8C}\x{5343}\x{4E09}\x{767E}\x{56DB}\x{5341}\x{4E94}", 12345, 9, -1 ],
    [ 'ja', 'spellout', 0, "\x{4E09}\x{767E}\x{4E07}", 3000000, 3, -1 ],
    [ 'ja', 'spellout', 0, "\x{53C2}\x{767E}\x{4E07}", 300, 2, -1 ],
    [ 'root', 'numbering_system', 0, "MMXXVI", 2026, 6, -1 ],
    [ 'root', 'numbering_system', 0, "mcmxciv", 1994, 7, -1 ],
    [ 'tr', 'spellout', 1, "\x{0130}K\x{0130}", 2, 3, -1 ],
    [ 'tr', 'spellout', 1, "B\x{0130}R", 1, 3, -1 ],
    [ 'tr', 'spellout', 1, "yirmi bir", 21, 9, -1 ],
);

my $cache = {};
my $get = sub
{
    my( $loc, $type ) = @_;
    return( $cache->{ "$loc:$type" } //= Locale::Unicode::RBNF->new( locale => $loc, type => $type, cldr => $cldr ) );
};

foreach my $def ( @formats )
{
    my( $loc, $type, $rs, $kind, $n, $expect ) = @$def;
    my $fmt = $get->( $loc, $type ) || BAIL_OUT( "Unable to instantiate $loc $type: " . Locale::Unicode::RBNF->error );
    my $got = $kind eq 'i' ? $fmt->format_int( $n, $rs ) : $fmt->format_double( $n, $rs );
    is( $got, $expect, "$loc $rs $n" );
}

foreach my $def ( @parses )
{
    my( $loc, $type, $lenient, $text, $value, $index, $error ) = @$def;
    my $fmt = $get->( $loc, $type );
    $fmt->lenient( $lenient );
    my( $v, $i, $e ) = $fmt->parse( $text );
    $v //= 0;
    ok( abs( $v - $value ) < 1e-9, "$loc parse (lenient=$lenient) '$text' value" ) || diag( "got $v, expected $value" );
    is( $i, $index, "$loc parse (lenient=$lenient) '$text' index" );
    is( $e, $error, "$loc parse (lenient=$lenient) '$text' error index" );
}

done_testing();

__END__
