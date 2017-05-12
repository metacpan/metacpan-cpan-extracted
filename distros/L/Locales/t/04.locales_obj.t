use Test::More tests => 424;
use Test::Carp;

use lib 'lib', '../lib';

BEGIN {
    use_ok('Locales');
}

use Locales::DB::Language::ja;
use Locales::DB::Language::fr;
use Locales::DB::Territory::en_au;
use Locales::DB::Territory::en;
use Locales::DB::Language::ar;

## functions ##
# split_tag
# get_i_tag_for_string
# normalize_tag
# normalize_tag with trailing _

is_deeply( [ Locales::non_locale_list() ], [ 'art', 'mis', 'mul', 'und', 'zxx' ], 'Locales::non_locale_list()' );
ok( !Locales::is_non_locale("fr"),       'Locales::is_non_locale() false w/ locale tag' );
ok( Locales::is_non_locale("ART"),       'Locales::is_non_locale() true w/ non-locale tag' );
ok( !Locales::is_non_locale('adfvadfd'), 'Locales::is_non_locale() false w/ non-existent tag' );

is_deeply( [ Locales::typical_en_alias_list() ], [ 'en_us', 'i_default' ], 'Locales::typical_en_alias_list()' );
ok( !Locales::is_typical_en_alias("fr"),       'Locales::is_typical_en_alias() false w/ locale tag' );
ok( Locales::is_typical_en_alias("en-US"),     'Locales::is_typical_en_alias() true w/ non-locale tag' );
ok( !Locales::is_typical_en_alias('adfvadfd'), 'Locales::is_typical_en_alias() false w/ non-existent tag' );

# normalize_tag_for_datetime_locale
is( Locales::normalize_tag_for_datetime_locale("EN"),    'en',    'DT with no country part' );
is( Locales::normalize_tag_for_datetime_locale("en-gb"), 'en_GB', 'DT with country part' );

# normalize_tag_for_ietf
is( Locales::normalize_tag_for_ietf("EN"),    'en',    'IETF with no country part' );
is( Locales::normalize_tag_for_ietf("en-gb"), 'en-GB', 'IETF with country part' );

# normalize_tag_for_datetime_locale
# normalize_for_key_lookup

is( Locales::get_cldr_version(), $Locales::cldr_version, 'get_cldr_version() as function' );
is( Locales->get_cldr_version(), $Locales::cldr_version, 'get_cldr_version() as class method' );
my $t = Locales->new();
is( $t->get_cldr_version(), $Locales::cldr_version, 'get_cldr_version() as object method' );

ok( scalar( Locales::get_loadable_language_codes() ) > 42, 'Locales::get_loadable_language_codes() has data' );           # number is arbitrary, there are lots more in actuality, I just needed a reasonable number and I like 42
ok( Locales::territory_code_is_known('mx'),                'Locales::territory_code_is_known() w/ known territory' );
ok( Locales::tag_is_loadable('es'),                        'Locales::tag_is_loadable() w/ loadable tag' );
ok( !Locales::territory_code_is_known('WAKKA'),            'Locales::territory_code_is_known() w/ unknown territory' );
ok( !Locales::tag_is_loadable('WAKKA'),                    'Locales::tag_is_loadable() w/ unloadable tag' );
for my $nlt ( Locales::non_locale_list() ) {
    ok( !Locales::tag_is_loadable($nlt),         "Locales::tag_is_loadable() w/ non-locale tag ($nlt) returns false" );
    ok( !Locales::territory_code_is_known($nlt), "Locales::territory_code_is_known() w/ non-locale tag ($nlt) returns false" );
}

my $class = 'Locales';
my $cobj  = Locales->new("fr");
my $sobj  = $class->new("fr");
is_deeply( $cobj, $sobj, "VAR->new() returns expected object" );
my $oobj = $cobj->new("fr");
is_deeply( $cobj, $oobj, "OBJ->new() returns expected object" );

my $soft = Locales->new("es-MX");
ok( $soft, 'Soft locale: object created' );
is( $soft->{'locale'},                             'es_mx',              'Soft locale: locale is entire tag' );
is( $soft->get_locale(),                           'es_mx',              'get_locale() is correct' );
is( $soft->{'soft_locale_fallback'},               'es',                 'Soft locale: soft_locale_fallback is the super tag' );
is( $soft->get_soft_locale_fallback(),             'es',                 'Soft locale: get_soft_locale_fallback() is correct' );
is( $soft->get_language(),                         'es',                 'Soft locale: get_language() is correct' );
is( $soft->get_territory(),                        'mx',                 'Soft locale: get_territory() is correct' );
is( $soft->get_native_language_from_code(),        'español (México)', 'Soft locale: get_native_language_from_code() is correct w/ out passing always-return boolean' );
is( $soft->get_locale_display_pattern_from_code(), '{0} ({1})',          'Soft locale: get_locale_display_pattern_from_code() is correct w/ out passing always-return boolean' );
is( $soft->get_character_orientation_from_code(),  'left-to-right',      'Soft locale: get_character_orientation_from_code() is correct w/ out passing always-return boolean' );
is( $soft->get_language_from_code(),               'español (México)', 'Soft locale: get_language_from_code() returns as expected w/ out passing always-return boolean' );
is( $soft->get_language_from_code('fr'),           'francés',           'Soft locale: get_language_from_code() on argument returns as expected' );
is( $soft->get_territory_from_code(),              'México',            'Soft locale: get_territory_from_code() returns as expected (no force logic required)' );

is( $t->quote("foo"),     "“foo”", 'quote() does quotation_' );
is( $t->quote_alt("foo"), '‘foo’', 'quote_alt() does alternate_quotation_' );

{
    local $t->{'misc'}{'list_quote_mode'} = 'unknown';

    does_carp_that_matches(
        sub {
            is( $t->get_list_and( 1, 2, 3, 4 ), '1, 2, 3, and 4', 'get_list_and() w/ invalid list_quote_mode default to none behavior' );
        },
        qr/\{misc\}\{list_quote_mode\} is set to an unknown value/,
    );
    does_carp_that_matches(
        sub {
            is( $t->get_list_or( 1, 2, 3, 4 ), '1, 2, 3, or 4', 'get_list_and() w/ invalid list_quote_mode default to none behavior' );
        },
        qr/\{misc\}\{list_quote_mode\} is set to an unknown value/
    );

    delete $t->{'misc'}{'list_quote_mode'};
    is( $t->get_list_and( 1, 2, 3, 4 ), '1, 2, 3, and 4', 'get_list_and() w/ missing list_quote_mode default to none behavior' );
    is( $t->get_list_or( 1, 2, 3, 4 ), '1, 2, 3, or 4', 'get_list_and() w/ missing list_quote_mode default to none behavior' );
}

is( $t->{'misc'}{'list_quote_mode'}, 'none', "{'misc'}{'list_quote_mode'} default to 'all'" );
{
    local $t->{'misc'}{'list_quote_mode'} = 'all';

    is( $t->get_list_and(), '“”', 'get_list_and() no args, list_quote_mode=all' );
    is( $t->get_list_and( 'a', undef, 2, "", 0, "  ", "\xc2\xa0" ), "“a”, “”, “2”, “”, “0”, “  ”, and “\xc2\xa0”", 'get_list_and() arg types, list_quote_mode=all' );
    is( $t->get_list_and(qw({0} {1} {0} {0})), '“{0}”, “{1}”, “{0}”, and “{0}”', 'CLDR parsing handles patterns passed in as args - AND, list_quote_mode=all' );
    is( $t->get_list_or(), '“”', 'get_list_or() no args, list_quote_mode=all' );    # get_list_or() is a stub …
    is( $t->get_list_or( 'a', undef, 2, "", 0, "  ", "\xc2\xa0" ), "“a”, “”, “2”, “”, “0”, “  ”, or “\xc2\xa0”", 'get_list_or() arg types, list_quote_mode=all' );    # get_list_or() is a stub …
    is( $t->get_list_or(qw({0} {1} {0} {0})), '“{0}”, “{1}”, “{0}”, or “{0}”', 'CLDR parsing handles patterns passed in as args - OR, list_quote_mode=all' );

    $t->{'misc'}{'list_quote_mode'} = 'some';
    is( $t->get_list_and(), '“”', 'get_list_and() no args, list_quote_mode=some' );
    is( $t->get_list_and( 'a', undef, 2, "", 0, "  ", "\xc2\xa0" ), "a, “”, 2, “”, 0, “  ”, and “\xc2\xa0”", 'get_list_and() arg types, list_quote_mode=some' );
    is( $t->get_list_and(qw({0} {1} {0} {0})), '{0}, {1}, {0}, and {0}', 'CLDR parsing handles patterns passed in as args - AND, list_quote_mode=some' );
    is( $t->get_list_or(),                     '“”',                 'get_list_or() no args, list_quote_mode=some' );                                                                         # get_list_or() is a stub …
    is( $t->get_list_or( 'a', undef, 2, "", 0, "  ", "\xc2\xa0" ), "a, “”, 2, “”, 0, “  ”, or “\xc2\xa0”", 'get_list_or() arg types, list_quote_mode=some' );                     # get_list_or() is a stub …
    is( $t->get_list_or(qw({0} {1} {0} {0})), '{0}, {1}, {0}, or {0}', 'CLDR parsing handles patterns passed in as args - OR, list_quote_mode=some' );
}

is( $t->get_list_and(),                    undef,                    'get_list_and() no args means nothing returned' );
is( $t->get_list_and('a'),                 'a',                      'get_list_and() 1 arg' );
is( $t->get_list_and(qw(a b)),             'a and b',                'get_list_and() 2 args' );
is( $t->get_list_and(qw(a b c)),           'a, b, and c',            'get_list_and() 3 args' );
is( $t->get_list_and(qw(a b c d)),         'a, b, c, and d',         'get_list_and() 3+ args 1' );
is( $t->get_list_and(qw(a b c d e)),       'a, b, c, d, and e',      'get_list_and() 3+ args 2' );
is( $t->get_list_and(qw(a b c d e f)),     'a, b, c, d, e, and f',   'get_list_and() 3+ args 3' );
is( $t->get_list_and(qw({0} {1} {0} {0})), '{0}, {1}, {0}, and {0}', 'CLDR parsing handles patterns passed in as args - AND' );

# get_list_or() is a stub that is english only until the OR info is in the CLDR (http://unicode.org/cldr/trac/ticket/4051)
is( $t->get_list_or(),                    undef,                   'get_list_or() no args means nothing returned' );
is( $t->get_list_or('a'),                 'a',                     'get_list_or() 1 arg' );
is( $t->get_list_or(qw(a b)),             'a or b',                'get_list_or() 2 args' );
is( $t->get_list_or(qw(a b c)),           'a, b, or c',            'get_list_or() 3 args' );
is( $t->get_list_or(qw(a b c d)),         'a, b, c, or d',         'get_list_or() 3+ args 1' );
is( $t->get_list_or(qw(a b c d e)),       'a, b, c, d, or e',      'get_list_or() 3+ args 2' );
is( $t->get_list_or(qw(a b c d e f)),     'a, b, c, d, e, or f',   'get_list_or() 3+ args 3' );
is( $t->get_list_or(qw({0} {1} {0} {0})), '{0}, {1}, {0}, or {0}', 'CLDR parsing handles patterns passed in as args - OR' );

is( $t->get_formatted_ellipsis_initial("foo"), '…foo', 'get_formatted_ellipsis_initial()' );
is( $t->get_formatted_ellipsis_medial( "bar", "baz" ), 'bar…baz', 'get_formatted_ellipsis_medial()' );
is( $t->get_formatted_ellipsis_final("zop"), 'zop…', 'get_formatted_ellipsis_final()' );

my $de = Locales->new('de');
is( $de->get_formatted_ellipsis_initial("foo"), '… foo', 'get_formatted_ellipsis_initial()' );
is( $de->get_formatted_ellipsis_medial( "bar", "baz" ), 'bar … baz', 'get_formatted_ellipsis_medial()' );
is( $de->get_formatted_ellipsis_final("zop"), 'zop …', 'get_formatted_ellipsis_final()' );

my $es = Locales->new("es");
$es->{'misc'}{'list_quote_mode'} = 'none';

is( $es->get_list_and(),                undef,               'get_list_and() no args means nothing returned' );
is( $es->get_list_and('a'),             'a',                 'get_list_and() 1 arg' );
is( $es->get_list_and(qw(a b)),         'a y b',             'get_list_and() 2 args' );
is( $es->get_list_and(qw(a b c)),       'a, b y c',          'get_list_and() 3 args' );
is( $es->get_list_and(qw(a b c d)),     'a, b, c y d',       'get_list_and() 3+ args 1' );
is( $es->get_list_and(qw(a b c d e)),   'a, b, c, d y e',    'get_list_and() 3+ args 2' );
is( $es->get_list_and(qw(a b c d e f)), 'a, b, c, d, e y f', 'get_list_and() 3+ args 3' );

# get_list_or() is a stub that is english only get_list_and() until the OR info is in the CLDR (http://unicode.org/cldr/trac/ticket/4051)
is( $es->get_list_or(),                undef,                 'get_list_or() no args means nothing returned' );
is( $es->get_list_or('a'),             'a',                   'get_list_or() 1 arg' );
is( $es->get_list_or(qw(a b)),         'a or b',              'get_list_or() 2 args' );
is( $es->get_list_or(qw(a b c)),       'a, b, or c',          'get_list_or() 3 args' );
is( $es->get_list_or(qw(a b c d)),     'a, b, c, or d',       'get_list_or() 3+ args 1' );
is( $es->get_list_or(qw(a b c d e)),   'a, b, c, d, or e',    'get_list_or() 3+ args 2' );
is( $es->get_list_or(qw(a b c d e f)), 'a, b, c, d, e, or f', 'get_list_or() 3+ args 3' );

# get_formatted_decimal()
is( $t->get_formatted_decimal(1234567890),          '1,234,567,890',        'basic int - num' );
is( $t->get_formatted_decimal('1234567890'),        '1,234,567,890',        'basic int - str' );
is( $t->get_formatted_decimal(-1234567890),         '-1,234,567,890',       'basic int negative - num' );
is( $t->get_formatted_decimal('-1234567890'),       '-1,234,567,890',       'basic int negative - str' );
is( $t->get_formatted_decimal(1234567890.12345),    '1,234,567,890.12345',  'basic dec - num' );
is( $t->get_formatted_decimal('1234567890.12345'),  '1,234,567,890.12345',  'basic dec - str' );
is( $t->get_formatted_decimal(-1234567890.12345),   '-1,234,567,890.12345', 'basic dec negative - num' );
is( $t->get_formatted_decimal('-1234567890.12345'), '-1,234,567,890.12345', 'basic dec negative - str' );

is( $t->get_formatted_decimal( 1234567890,         3 ), '1,234,567,890',      'max - basic int - num' );
is( $t->get_formatted_decimal( '1234567890',       3 ), '1,234,567,890',      'max - basic int - str' );
is( $t->get_formatted_decimal( -1234567890,        3 ), '-1,234,567,890',     'max - basic int negative - num' );
is( $t->get_formatted_decimal( '-1234567890',      3 ), '-1,234,567,890',     'max - basic int negative - str' );
is( $t->get_formatted_decimal( 1234567890.12345,   3 ), '1,234,567,890.123',  'max - no round - basic dec - num' );
is( $t->get_formatted_decimal( '1234567890.12345', 3 ), '1,234,567,890.123',  'max - no round - basic dec - str' );
is( $t->get_formatted_decimal( -1234567890.12345,  3 ), '-1,234,567,890.123', 'max - no round - basic dec negative - num' );

# use like() instead of is() here due to numeric behavior and nvsize issues (see rt 72788)
like( $t->get_formatted_decimal( '-1234567890.12345', 4 ), qr/^-1,234,567,890\.123[45]$/, 'max - no round - basic dec negative - str' );
like( $t->get_formatted_decimal( 1234567890.12345,    4 ), qr/^1,234,567,890\.123[45]$/,  'max - round - basic dec - num' );
like( $t->get_formatted_decimal( '1234567890.12345',  4 ), qr/^1,234,567,890\.123[45]$/,  'max - round - basic dec - str' );
like( $t->get_formatted_decimal( -1234567890.12345,   4 ), qr/^-1,234,567,890\.123[45]$/, 'max - round - basic dec negative - num' );
like( $t->get_formatted_decimal( '-1234567890.12345', 4 ), qr/^-1,234,567,890\.123[45]$/, 'max - round - basic dec negative - str' );

like( $t->get_formatted_decimal(99999999999999999983222787.1234), qr/e/i, 'exponential number is passed through' );
is( $t->get_formatted_decimal("99999999999999999983222787.1234"), '99,999,999,999,999,999,983,222,787.1234', 'exponential number as string is formatted' );
like( $t->get_formatted_decimal(99999999999999999983222787.1234), qr/e/i, 'exponential number is passed through' );
is( $t->get_formatted_decimal("99999999999999999983222787.1234"), '99,999,999,999,999,999,983,222,787.1234', 'exponential number as string is formatted' );

# small num, long dec
is( $t->get_formatted_decimal(12.99999999999999),   '13', 'small num, long dec - num' );
is( $t->get_formatted_decimal("12.99999999999999"), '13', 'small num, long dec - str' );
is( $t->get_formatted_decimal( 12.99999999999999,   13 ), '13',                'small num, long dec < max- num' );
is( $t->get_formatted_decimal( "12.99999999999999", 13 ), '13',                'small num, long dec < max - str' );
is( $t->get_formatted_decimal( 12.99999999999999,   14 ), '12.99999999999999', 'small num, long dec = max- num' );
is( $t->get_formatted_decimal( "12.99999999999999", 14 ), '12.99999999999999', 'small num, long dec = max - str' );
is( $t->get_formatted_decimal( 12.99999999999999,   15 ), '12.99999999999999', 'small num, long dec > max- num' );
is( $t->get_formatted_decimal( "12.99999999999999", 15 ), '12.99999999999999', 'small num, long dec > max - str' );

# big num, long dec
is( $t->get_formatted_decimal(10000000001.99999999999999),   '10,000,000,002',   'big num, long dec - num' );
is( $t->get_formatted_decimal("10000000001.99999999999999"), '10,000,000,001.1', 'big num, long dec - str' );
is( $t->get_formatted_decimal( 10000000001.99999999999999,   13 ), '10,000,000,002',                'big num, long dec < max- num' );
is( $t->get_formatted_decimal( "10000000001.99999999999999", 13 ), '10,000,000,001.1',              'big num, long dec < max - str' );
is( $t->get_formatted_decimal( 10000000001.99999999999999,   14 ), '10,000,000,002',                'big num, long dec = max- num' );
is( $t->get_formatted_decimal( "10000000001.99999999999999", 14 ), '10,000,000,001.99999999999999', 'big num, long dec = max - str' );
is( $t->get_formatted_decimal( 10000000001.99999999999999,   15 ), '10,000,000,002',                'big num, long dec > max- num' );
is( $t->get_formatted_decimal( "10000000001.99999999999999", 15 ), '10,000,000,001.99999999999999', 'big num, long dec > max - str' );

{
    my $hi = Locales->new('hi');    # hi #,##,##0.###
    is( $hi->get_formatted_decimal(1234567890.12345), '1,23,45,67,890.12345', 'non standard format' );
    my $ar = Locales->new('ar');    # ar #,##0.###;#,##0.###-
    is( $ar->get_formatted_decimal(1234567890.12345),  '1٬234٬567٬890٫12345',  'non standard format w/ neg - pos' );
    is( $ar->get_formatted_decimal(-1234567890.12345), '1٬234٬567٬890٫12345-', 'non standard format w/ neg - neg' );
    my $hy = Locales->new('hy');    # hy #0.###
    is( $hy->get_formatted_decimal(1234567890.12345), '1234567890,12345', 'non standard format only one part' );

    my $de = Locales->new('de');
    is( $de->get_formatted_decimal(1234567890.12345), '1.234.567.890,12345', 'rt 91549 - chicken and egg swap bug' );
}

is( $t->get_formatted_decimal(100_000_001),                   '100,000,001', 'integer via underscore stringified by perl OK' );
is( $t->get_formatted_decimal(0575360401),                    '100,000,001', 'octal stringified by perl OK' );
is( $t->get_formatted_decimal(0b101111101011110000100000001), '100,000,001', 'binary stringified by perl OK' );
is( $t->get_formatted_decimal(0x5f5e101),                     '100,000,001', 'hexidecimal stringified by perl OK' );

is_deeply( [ Locales::get_cldr_plural_category_list() ],  [qw(one two few many other zero)],  'plural category list (arg order) is as expected (content and order)' );
is_deeply( [ Locales::get_cldr_plural_category_list(1) ], [qw(zero one two few many other )], 'plural category (proc order) list is as expected (content and order)' );
ok( Locales::normalize_tag("123456789_abc_1234567812345678123456789_12345678_12345678") eq '12345678_9_abc_12345678_12345678_12345678_9_12345678_12345678', '> 8 char sequence, less than 8, 8 followed by _ , multiple 8 run + extra, and 8 at the end' );

# # http://unicode.org/repos/cldr-tmp/trunk/diff/supplemental/language_plural_rules.html has fractional data in the table but it isn't immediately clear that the table is made based on the 'within' statement
# # this was the initial manual data struct based on that table, these tests should verify one or more (all?) are correctly handled
# # 0.x, 1.x, 2.x-127.x
# '_frac_cats' => [
#       ( grep { $tag eq $_ } (qw(fr ff kab lag)) ) ? ( 'one', 'one',   'other' )
#     : ( grep { $tag eq $_ } (qw(shi)) )           ? ( 'one', 'other', 'other' )
#     : ( 'other', 'other', 'other' )
# ],

my @plural_tests = (
    [ 'n is 4', [ 4, -4 ], [ 3, 4.2 ] ],
    [ 'n mod 100 is 4', [ 4, -4, '4.0', -104, 104, 204 ], [ 5, 4.1, -4.0002 ] ],
    [ 'n is not 4',         [ 3,   5,   4.1 ], [ 4, -4 ] ],
    [ 'n mod 100 is not 4', [ 3,   103, 205 ], [ 4, 104, -4, -204 ] ],
    [ 'n not in 1..3',      [ 2.5, 0,   4 ],   [ 1, 2, 3, -1, -2, -3 ] ],
    [ 'n mod 100 not in 1..3', [ 102.4, -202.5, 6 ],  [ 101, 202, -303 ] ],
    [ 'n not within 2..6',     [ 1,     7,      -8 ], [ 2,   3.5, -4.7 ] ],
    [ 'n mod 100 not within 4..6', [ 2, 407, -301 ], [ 4.7, -304.5 ] ],
    [ 'n in 3..4', [ 3, 4 ], [ 2, 5, -606 ] ],
    [ 'n mod 100 in 5..6', [ 5, 6, -205 ], [ 7, -208, 3 ] ],
    [ 'n within 4..7', [ 4, 5, 6, 6.6, 7, -4.8 ], [ 7.1, -3 ] ],
    [ 'n is 4 and n is 4 and n is 4', [ 4, -4 ], [ 3, 5, 208 ] ],
    [ 'n is 4 or n is 4 or n is 4',   [ 4, -4 ], [ 3, 5, 208 ] ],
    [ 'n is 4 or n is 5 and n is 6 or n is 7', [ 4, 7, -7 ], [ 3, 4.5, 5, 6, -5, -6, -8 ] ],
);
for my $plural_test (@plural_tests) {
    my ( $rule_string, $should_match, $should_not_match ) = @{$plural_test};

    my $rule = Locales::plural_rule_string_to_code($rule_string);
    $rule = eval "$rule";

    for my $match_this ( @{$should_match} ) {
        ## See details in comment above Locales::get_plural_form(), basically, "negatives keep same category as positive"
        ## We still leave negatives in @plural_tests in case the details in said details ever happens, then we can quickly adjust the tests to match
        my $pos = abs($match_this);
        ok( $rule->($pos), "plural_rule behavior: '$rule_string' is true for abs($match_this)" );
    }

    for my $dont_match ( @{$should_not_match} ) {
        ## See details in comment above Locales::get_plural_form(), basically, "negatives keep same category as positive"
        ## We still leave negatives in @plural_tests in case the details in said details ever happens, then we can quickly adjust the tests to match
        my $pos = abs($dont_match);
        ok( !$rule->($pos), "plural_rule behavior: '$rule_string' is false for abs($dont_match)" );
    }
}

my $one_one_other = Locales->new('fr');
is( $one_one_other->get_plural_form("0.1"), "one",   "special category 1 0.x" );
is( $one_one_other->get_plural_form("1.1"), "one",   "special category 1 1.x" );
is( $one_one_other->get_plural_form("2.1"), "other", "special category 1 2.x +" );
my $one_other_other = Locales->new('shi');
is( $one_other_other->get_plural_form("0.1"), "one",   "special category 2 0.x" );
is( $one_other_other->get_plural_form("1.1"), "other", "special category 2 1.x" );
is( $one_other_other->get_plural_form("2.1"), "other", "special category 2 2.x +" );
my $other_other_other = Locales->new('en');
is( $other_other_other->get_plural_form("0.1"), "other", "special category 0 0.x" );
is( $other_other_other->get_plural_form("1.1"), "other", "special category 0 1.x" );
is( $other_other_other->get_plural_form("2.1"), "other", "special category 0 2.x +" );

ok( !$one_one_other->supports_special_zeroth(), 'supports_special_zeroth() is false as expected' );
is( $one_one_other->plural_category_count(), 2, 'plural_category_count() is correct count and does not fatcor in special zeroth' );
ok( !$one_other_other->supports_special_zeroth(), 'supports_special_zeroth() is false as expected' );
is( $one_other_other->plural_category_count(), 3, 'plural_category_count() is correct count and does not fatcor in special zeroth' );
ok( $other_other_other->supports_special_zeroth(), 'supports_special_zeroth() is true as expected' );
is( $other_other_other->plural_category_count(), 2, 'plural_category_count() is correct count and does not fatcor in special zeroth' );

does_carp_that_matches(
    sub {
        local $other_other_other->{'verbose'} = 1;
        $other_other_other->get_plural_form( 42, qw(a b c d e f g h i j k) );
    },
    qr/The number of given values \(\d+\) does not match the number of categories \(\d+\)\./
);

is( $other_other_other->get_plural_form(0), "other", "category name 0" );
is( $other_other_other->get_plural_form(1), "one",   "category name 1" );
is( $other_other_other->get_plural_form(2), "other", "category name 2" );
is_deeply( [ $other_other_other->get_plural_form(0) ], [ "other", 0 ], "category name 0" );
is_deeply( [ $other_other_other->get_plural_form(1) ], [ "one",   0 ], "category name 1" );
is_deeply( [ $other_other_other->get_plural_form(2) ], [ "other", 0 ], "category name 2" );

is( $other_other_other->get_plural_form( 1,  'box', 'boxes' ), 'box',   '1 w/ no zero extra' );
is( $other_other_other->get_plural_form( 42, 'box', 'boxes' ), 'boxes', '>1 w/ no zero extra' );
is( $other_other_other->get_plural_form( 0,  'box', 'boxes' ), 'boxes', '0 w/ no zero extra' );

is( $other_other_other->get_plural_form( 1,  'box', 'boxes', 'no boxes' ), 'box',      '1 w/ zero extra' );
is( $other_other_other->get_plural_form( 42, 'box', 'boxes', 'no boxes' ), 'boxes',    '>1 w/ zero extra' );
is( $other_other_other->get_plural_form( 0,  'box', 'boxes', 'no boxes' ), 'no boxes', '0 w/ no zero extra' );

is_deeply( [ $other_other_other->get_plural_form( 1,  'box', 'boxes' ) ], [ 'box',   0 ], '1 w/ no zero extra - array context' );
is_deeply( [ $other_other_other->get_plural_form( 42, 'box', 'boxes' ) ], [ 'boxes', 0 ], '>1 w/ no zero extra - array context' );
is_deeply( [ $other_other_other->get_plural_form( 0,  'box', 'boxes' ) ], [ 'boxes', 0 ], '0 w/ no zero extra - array context' );

is_deeply( [ $other_other_other->get_plural_form( 1,  'box', 'boxes', 'no boxes' ) ], [ 'box',      0 ], '1 w/ zero extra - array context' );
is_deeply( [ $other_other_other->get_plural_form( 42, 'box', 'boxes', 'no boxes' ) ], [ 'boxes',    0 ], '>1 w/ zero extra - array context' );
is_deeply( [ $other_other_other->get_plural_form( 0,  'box', 'boxes', 'no boxes' ) ], [ 'no boxes', 1 ], '0 w/ no zero extra - array context' );

ok( Locales::get_i_tag_for_string('i_win') eq 'i_win', "i_ tag not prepended when we have it already" );
ok( Locales::get_i_tag_for_string('win') eq 'i_win',   "i_ tag prepended when we don't have it already" );

is_deeply(
    [ $other_other_other->get_plural_form_categories() ],
    $other_other_other->{'language_data'}{'misc_info'}{'plural_forms'}{'category_list'},
    'get_plural_form_categories() returns correct data (1)'
);

is_deeply(
    [ $one_one_other->get_plural_form_categories() ],
    $one_one_other->{'language_data'}{'misc_info'}{'plural_forms'}{'category_list'},
    'get_plural_form_categories() returns correct data (2)'
);

# plural_rule_hashref_to_code()
my $ehr    = {};
my $def_cr = Locales::plural_rule_hashref_to_code($ehr);
is_deeply(
    $ehr,
    { 'category_rules_compiled' => { 'one' => q{sub { return 'one' if ( ( $n == 1 ) ); return;};} } },
    'no category_rules gets default category_rules_compiled'
);
is( $def_cr->(1), 'one', 'no category_rules gets default cr 1 res' );
ok( !defined $def_cr->(0), 'no category_rules gets default cr other res' );

# test each type of 'category_rules' via plural_rule_string_to_code()

is( Locales::plural_rule_string_to_code( 'n is 4', "RETVAL" ), q{sub { if ( (( $_[0] == 4))) { return 'RETVAL'; } return;}}, 'plural rule: n is …' );
is( Locales::plural_rule_string_to_code( 'n mod 100 is 4', "RETVAL" ), q{sub { if ( (( ( ($_[0] % 100) + ($_[0]-int($_[0])) ) == 4))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … is …' );

is( Locales::plural_rule_string_to_code( 'n is not 4', "RETVAL" ), q{sub { if ( (( $_[0] != 4))) { return 'RETVAL'; } return;}}, 'plural rule: n is not …' );
is( Locales::plural_rule_string_to_code( 'n mod 100 is not 4', "RETVAL" ), q{sub { if ( (( ( ($_[0] % 100) + ($_[0]-int($_[0])) ) != 4))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … is not …' );

is( Locales::plural_rule_string_to_code( 'n not in 1..3', "RETVAL" ), q{sub { if ( (( int($_[0]) != $_[0] || $_[0] < 1 || $_[0] > 3 ))) { return 'RETVAL'; } return;}}, 'plural rule: n not in 1..3' );
is( Locales::plural_rule_string_to_code( 'n mod 100 not in 1..3', "RETVAL" ), q{sub { if ( (( int($_[0]) != $_[0] || ( ($_[0] % 100) + ($_[0]-int($_[0])) ) < 1 || ( ($_[0] % 100) + ($_[0]-int($_[0])) ) > 3 ))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … not in 1..3' );

is( Locales::plural_rule_string_to_code( 'n not within 2..6', "RETVAL" ), q{sub { if ( (( ($_[0] < 2 || $_[0] > 6) ))) { return 'RETVAL'; } return;}}, 'plural rule: n not within 2..6' );
is( Locales::plural_rule_string_to_code( 'n mod 100 not within 4..6', "RETVAL" ), q{sub { if ( (( (( ($_[0] % 100) + ($_[0]-int($_[0])) ) < 4 || ( ($_[0] % 100) + ($_[0]-int($_[0])) ) > 6) ))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … not within 4..6' );

is( Locales::plural_rule_string_to_code( 'n in 3..4', "RETVAL" ), q{sub { if ( (( int($_[0]) == $_[0] && $_[0] >= 3 && $_[0] <= 4 ))) { return 'RETVAL'; } return;}}, 'plural rule: n in 3..4' );
is( Locales::plural_rule_string_to_code( 'n mod 100 in 5..6', "RETVAL" ), q{sub { if ( (( int($_[0]) == $_[0] && ( ($_[0] % 100) + ($_[0]-int($_[0])) ) >= 5 && ( ($_[0] % 100) + ($_[0]-int($_[0])) ) <= 6 ))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … in 5..6' );

is( Locales::plural_rule_string_to_code( 'n within 4..7', "RETVAL" ), q{sub { if ( (( $_[0] >= 4 && $_[0] <= 7 ))) { return 'RETVAL'; } return;}}, 'plural rule: n within 4..7' );
is( Locales::plural_rule_string_to_code( 'n mod 100 within 2..5', "RETVAL" ), q{sub { if ( (( ( ($_[0] % 100) + ($_[0]-int($_[0])) ) >= 2 && ( ($_[0] % 100) + ($_[0]-int($_[0])) ) <= 5 ))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … within 2..5' );

ok( Locales::plural_rule_string_to_code( 'n within 4..7', "RETVAL" ) =~ m/return \'RETVAL\'/, "retval given" );
ok( Locales::plural_rule_string_to_code('n within 4..7') =~ m/return \'1\'/, "retval not given" );
ok( Locales::plural_rule_string_to_code( 'n within 4..7', 0 ) =~ m/return \'0\'/,       "retval given 0" );
ok( Locales::plural_rule_string_to_code( 'n within 4..7', undef() ) =~ m/return \'1\'/, "retval given undef()" );
ok( Locales::plural_rule_string_to_code( 'n within 4..7', '' ) =~ m/return \'\'/,       "retval given ''" );

# and/or
is( Locales::plural_rule_string_to_code('n is 4 and n is 4 and n is 4'),          q{sub { if ( (( $_[0] == 4) && ( $_[0] == 4) && ( $_[0] == 4))) { return '1'; } return;}},                        'plural_rule: and' );
is( Locales::plural_rule_string_to_code('n is 4 or n is 4 or n is 4'),            q{sub { if ( (( $_[0] == 4)) ||  (( $_[0] == 4)) ||  (( $_[0] == 4))) { return '1'; } return;}},                  'plural_rule: or' );
is( Locales::plural_rule_string_to_code('n is 4 or n is 5 and n is 6 or n is 7'), q{sub { if ( (( $_[0] == 4)) ||  (( $_[0] == 5) && ( $_[0] == 6)) ||  (( $_[0] == 7))) { return '1'; } return;}}, 'plural_rule: and and or' );

# JavaScript
is( Locales::plural_rule_string_to_javascript_code( 'n is 4',         "RETVAL" ), q{function (n) {if ( (( n == 4))) { return 'RETVAL'; } return;}},         'plural rule: n is …' );
is( Locales::plural_rule_string_to_javascript_code( 'n mod 100 is 4', "RETVAL" ), q{function (n) {if ( (( (n % 100) == 4))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … is …' );

is( Locales::plural_rule_string_to_javascript_code( 'n is not 4',         "RETVAL" ), q{function (n) {if ( (( n != 4))) { return 'RETVAL'; } return;}},         'plural rule: n is not …' );
is( Locales::plural_rule_string_to_javascript_code( 'n mod 100 is not 4', "RETVAL" ), q{function (n) {if ( (( (n % 100) != 4))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … is not …' );

is( Locales::plural_rule_string_to_javascript_code( 'n not in 1..3', "RETVAL" ), q{function (n) {if ( (( parseInt(n) != n || n < 1 || n > 3 ))) { return 'RETVAL'; } return;}}, 'plural rule: n not in 1..3' );
is( Locales::plural_rule_string_to_javascript_code( 'n mod 100 not in 1..3', "RETVAL" ), q{function (n) {if ( (( parseInt(n) != n || (n % 100) < 1 || (n % 100) > 3 ))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … not in 1..3' );

is( Locales::plural_rule_string_to_javascript_code( 'n not within 2..6', "RETVAL" ), q{function (n) {if ( (( (n < 2 || n > 6) ))) { return 'RETVAL'; } return;}}, 'plural rule: n not within 2..6' );
is( Locales::plural_rule_string_to_javascript_code( 'n mod 100 not within 4..6', "RETVAL" ), q{function (n) {if ( (( ((n % 100) < 4 || (n % 100) > 6) ))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … not within 4..6' );

is( Locales::plural_rule_string_to_javascript_code( 'n in 3..4', "RETVAL" ), q{function (n) {if ( (( parseInt(n) == n && n >= 3 && n <= 4 ))) { return 'RETVAL'; } return;}}, 'plural rule: n in 3..4' );
is( Locales::plural_rule_string_to_javascript_code( 'n mod 100 in 5..6', "RETVAL" ), q{function (n) {if ( (( parseInt(n) == n && (n % 100) >= 5 && (n % 100) <= 6 ))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … in 5..6' );

is( Locales::plural_rule_string_to_javascript_code( 'n within 4..7', "RETVAL" ), q{function (n) {if ( (( n >= 4 && n <= 7 ))) { return 'RETVAL'; } return;}}, 'plural rule: n within 4..7' );
is( Locales::plural_rule_string_to_javascript_code( 'n mod 100 within 2..5', "RETVAL" ), q{function (n) {if ( (( (n % 100) >= 2 && (n % 100) <= 5 ))) { return 'RETVAL'; } return;}}, 'plural rule: n mod … within 2..5' );

ok( Locales::plural_rule_string_to_javascript_code( 'n within 4..7', "RETVAL" ) =~ m/return \'RETVAL\'/, "retval given" );
ok( Locales::plural_rule_string_to_javascript_code('n within 4..7') =~ m/return \'1\'/, "retval not given" );
ok( Locales::plural_rule_string_to_javascript_code( 'n within 4..7', 0 ) =~ m/return \'0\'/,       "retval given 0" );
ok( Locales::plural_rule_string_to_javascript_code( 'n within 4..7', undef() ) =~ m/return \'1\'/, "retval given undef()" );
ok( Locales::plural_rule_string_to_javascript_code( 'n within 4..7', '' ) =~ m/return \'\'/,       "retval given ''" );

# and/or
is( Locales::plural_rule_string_to_javascript_code('n is 4 and n is 4 and n is 4'),          q{function (n) {if ( (( n == 4) && ( n == 4) && ( n == 4))) { return '1'; } return;}},                    'plural_rule: and' );
is( Locales::plural_rule_string_to_javascript_code('n is 4 or n is 4 or n is 4'),            q{function (n) {if ( (( n == 4)) ||  (( n == 4)) ||  (( n == 4))) { return '1'; } return;}},              'plural_rule: or' );
is( Locales::plural_rule_string_to_javascript_code('n is 4 or n is 5 and n is 6 or n is 7'), q{function (n) {if ( (( n == 4)) ||  (( n == 5) && ( n == 6)) ||  (( n == 7))) { return '1'; } return;}}, 'plural_rule: and and or' );

#/ JavaScript

# syntax errors
# ok(!defined Locales::plural_rule_string_to_code('number is 4'), 'simply rule, syntax error');
# ok(!defined Locales::plural_rule_string_to_code('n is 4 and 3 is in 1 or n is not 7'), 'complex rule, syntax error');
# does_carp_that_matches(\&Locales::plural_rule_string_to_code, 'number is 4', qr/Unknown plural rule syntax/);
# does_carp_that_matches(\&Locales::plural_rule_string_to_code, 'n is 4 and 3 is in 1 or n is not 7', qr/Unknown plural rule syntax/);
# the ok's will carp so:
does_carp_that_matches(
    sub {
        ok( !defined Locales::plural_rule_string_to_code('number is 4'), 'simply rule, syntax error' );
    },
    qr/Unknown plural rule syntax/
);
does_carp_that_matches(
    sub {
        ok( !defined Locales::plural_rule_string_to_code('n is 4 and 3 is in 1 or n is not 7'), 'simply rule, syntax error' );
    },
    qr/Unknown plural rule syntax/
);

# TODO: plural_rule_string_to_code() logic is sane?

my $nhr = {
    'category_list'  => [ 'one', 'other' ],
    'category_rules' => {
        'one' => 'n is not 1 and n is not 3 or n is not 4 and n is not 5 and n is not 6 or n is 7',
    },
};
my $ncr = Locales::plural_rule_hashref_to_code($nhr);
is_deeply(
    $nhr->{'category_rules_compiled'},
    { 'one' => 'sub { if ( (( $_[0] != 1) && ( $_[0] != 3)) ||  (( $_[0] != 4) && ( $_[0] != 5) && ( $_[0] != 6)) ||  (( $_[0] == 7))) { return \'one\'; } return;}' },
    'category_rules_compiled built correctly, and/or as expected'
);

# use Data::Dumper;diag(Dumper($nhr));

## new && get_locale && singleton ##
my $no_arg = Locales->new();
my $en     = Locales->new('en');
my $fr     = Locales->new('fr');
my $ar     = Locales->new('ar');
my $it     = Locales->new('it');

is( $it->get_cldr_number_symbol_group(),   '.', 'get_cldr_number_symbol_group()' );
is( $it->get_cldr_number_symbol_decimal(), ',', 'get_cldr_number_symbol_decimal()' );
my $fr_ca = Locales->new('fr_ca');
is_deeply(
    [ $fr_ca->get_fallback_list() ],
    [qw(fr_ca fr en)],
    'get_fallback_list() (super) no args'
);
is_deeply(
    [ $fr_ca->get_fallback_list( sub { return $_[0] =~ m/fr/ ? qw(i_yoda i-Love-Rhi ***) : () } ) ],
    [qw(fr_ca fr i_yoda i_love_rhi en)],
    'get_fallback_list() (super) code arg (w/ unnormalized value and an invalid value)'
);
is_deeply(
    [ $fr->get_fallback_list() ],
    [qw(fr en)],
    'get_fallback_list() (no super) no args'
);
is_deeply(
    [ $fr->get_fallback_list( sub { return $_[0] =~ m/fr/ ? qw(i_yoda i-Love-Rhi ***) : () } ) ],
    [qw(fr i_yoda i_love_rhi en)],
    'get_fallback_list() (no super) code arg (w/ unnormalized value and an invalid value)'
);
my $uk = Locales->new('uk');
is_deeply(
    [ $uk->get_fallback_list() ],
    [qw(uk ru en)],
    'get_fallback_list() CLDR'
);

ok( $en->get_native_language_from_code('en') eq $Locales::DB::Language::en::code_to_name{'en'}, 'get_native_language_from_code() 1 w/ en' );
ok( $en->get_native_language_from_code('fr') eq $Locales::DB::Language::fr::code_to_name{'fr'}, 'get_native_language_from_code() 2 w/ en' );
ok( $fr->get_native_language_from_code('en') eq $Locales::DB::Language::en::code_to_name{'en'}, 'get_native_language_from_code() 1 w/ non-en' );
ok( $fr->get_native_language_from_code('fr') eq $Locales::DB::Language::fr::code_to_name{'fr'}, 'get_native_language_from_code() 2 w/ non-en' );

ok( $en->get_native_language_from_code() eq $Locales::DB::Language::en::code_to_name{'en'}, 'get_native_language_from_code() no-arg w/ en' );
ok( $fr->get_native_language_from_code() eq $Locales::DB::Language::fr::code_to_name{'fr'}, 'get_native_language_from_code() no-arg w/ non-en' );

for my $m (qw(get_character_orientation_from_code get_character_orientation_from_code_fast)) {
    is( $en->$m('en'), $Locales::DB::Language::en::misc_info{'orientation'}{'characters'}, "$m() 1 w/ en" );
    is( $en->$m('ar'), $Locales::DB::Language::ar::misc_info{'orientation'}{'characters'}, "$m() 2 w/ en" );
    is( $ar->$m('en'), $Locales::DB::Language::en::misc_info{'orientation'}{'characters'}, "$m() 1 w/ non-en" );
    is( $ar->$m('ar'), $Locales::DB::Language::ar::misc_info{'orientation'}{'characters'}, "$m() 2 w/ non-en" );

    is( $en->$m(), $Locales::DB::Language::en::misc_info{'orientation'}{'characters'}, "$m() no-arg w/ en" );
    is( $ar->$m(), $Locales::DB::Language::ar::misc_info{'orientation'}{'characters'}, "$m() no-arg w/ non-en" );
}

for my $m (qw(get_locale_display_pattern_from_code get_locale_display_pattern_from_code_fast)) {
    is( $en->$m('en'), $Locales::DB::Language::en::misc_info{'cldr_formats'}{'locale'}, "$m() 1 w/ en" );
    is( $en->$m('ar'), $Locales::DB::Language::ar::misc_info{'cldr_formats'}{'locale'}, "$m() 2 w/ en" );
    is( $ar->$m('en'), $Locales::DB::Language::en::misc_info{'cldr_formats'}{'locale'}, "$m() 1 w/ non-en" );
    is( $ar->$m('ar'), $Locales::DB::Language::ar::misc_info{'cldr_formats'}{'locale'}, "$m() 2 w/ non-en" );

    is( $en->$m(), $Locales::DB::Language::en::misc_info{'cldr_formats'}{'locale'}, "$m() no-arg w/ en" );
    is( $ar->$m(), $Locales::DB::Language::ar::misc_info{'cldr_formats'}{'locale'}, "$m() no-arg w/ non-en" );
}

my $xx = Locales->new('adfvddsfvsdfv');
ok( $@,                          '$@ is set after invalid arg' );
ok( !$xx,                        'new() returns false on invalid arg' );
ok( $no_arg->get_locale eq 'en', 'no arg default to en' );
ok( $en->get_locale eq 'en',     'en arg is en' );
ok( $no_arg eq $en,              '>1 en\'s singleton' );
ok( $fr->get_locale eq 'fr',     'known arg is correct locale' );
Locales->new("Locales;print 'injection attack;'");
ok( $@ =~ m{Locales\/DB\/Language\/locales_print_injectio_nattack\.pm}, 'injection attack via eval thwarted by normalization' );

##  get_territory() && get_language ##
ok( $en->get_language() eq 'en', 'get_language tag w/ no territory' );
ok( !$en->get_territory(),       'get_territory tag w/ no territory' );
my $en_au = Locales->new('en_au');
ok( $en_au->get_language() eq 'en',  'get_language tag w/ territory' );
ok( $en_au->get_territory() eq 'au', 'get_territory tag w/ territory' );

## get_* territory ##
is_deeply( [ sort( keys %Locales::DB::Territory::en::code_to_name ) ],   [ sort( $en->get_territory_codes() ) ], 'get_territory_codes()' );
is_deeply( [ sort( values %Locales::DB::Territory::en::code_to_name ) ], [ sort( $en->get_territory_names() ) ], 'get_territory_names()' );
my %lu = $en->get_territory_lookup();
is_deeply( \%lu, \%Locales::DB::Territory::en::code_to_name, 'get_territory_lookup() returns expected data' );
$lu->{"this is not a locale code"} = 42;
ok( !exists $Locales::DB::Territory::en::code_to_name{"this is not a locale code"}, "get_territory_lookup() is a copy that does not modify the internal data" );

ok( $en->get_territory_from_code('us') eq $Locales::DB::Territory::en::code_to_name{'us'},      'get_territory_from_code() w/ known arg' );
ok( $en->get_territory_from_code('  en-GB') eq $Locales::DB::Territory::en::code_to_name{'gb'}, 'get_territory_from_code() normalized' );
ok( !$en->get_territory_from_code('ucscs'),                                                     'get_territory_from_code() w/ unknown arg' );
ok( $en->get_territory_from_code( 'ucscs', 1 ) eq 'ucscs', 'get_territory_from_code() w/ unknown arg + always_return' );
ok( $en->get_code_from_territory( $Locales::DB::Territory::en::code_to_name{'us'} ) eq 'us', 'get_territory_from_code() w/ known arg' );
ok( !$en->get_code_from_territory('asdcasdcasdcdc'),                                         'get_code_from_territory() w/ unknown arg' );

ok( !$en->get_territory_from_code(),                                                                              'get_territory_from_code() no arg on locale w/ out a territory' );
ok( $en_au->get_territory_from_code() eq $Locales::DB::Territory::en_au::code_to_name{ $en_au->get_territory() }, 'get_territory_from_code() no arg on locale w/ a territory' );

ok( \&Locales::code2territory eq \&Locales::get_territory_from_code, 'code2territory aliases get_territory_from_code' );
ok( \&Locales::territory2code eq \&Locales::get_code_from_territory, 'territory2code aliases get_code_from_territory' );

## get* language ##
is_deeply( [ sort( keys %Locales::DB::Language::en::code_to_name ) ],   [ sort( $en->get_language_codes() ) ], 'get_language_codes()' );
is_deeply( [ sort( values %Locales::DB::Language::en::code_to_name ) ], [ sort( $en->get_language_names() ) ], 'get_language_names()' );
%lu = $en->get_language_lookup();
is_deeply( \%lu, \%Locales::DB::Language::en::code_to_name, 'get_language_lookup() returns expected data' );
$lu->{"this is not a locale code"} = 42;
ok( !exists $Locales::DB::Language::en::code_to_name{"this is not a locale code"}, "get_language_lookup() is a copy that does not modify the internal data" );

ok( $en->get_language_from_code('en') eq $Locales::DB::Language::en::code_to_name{'en'},         'get_language_from_code() w/ known arg' );
ok( $en->get_language_from_code('  en-GB') eq $Locales::DB::Language::en::code_to_name{'en_gb'}, 'get_language_from_code() normalized' );
ok( !$en->get_language_from_code('ucscs'),                                                       'get_language_from_code() w/ unknown arg' );
ok( $en->get_territory_from_code( 'ucscs', 1 ) eq 'ucscs', 'get_language_from_code() w/ unknown arg + always_return' );
ok( $en->get_code_from_language( $Locales::DB::Language::en::code_to_name{'en'} ) eq 'en', 'get_code_from_language() w/ known arg' );
ok( !$en->get_code_from_language('asdcasdcasdcdc'),                                        'get_code_from_language() w/ unknown arg' );

ok( $en->get_language_from_code() eq $Locales::DB::Language::en_au::code_to_name{ $en->get_locale() },       'get_language_from_code() no arg on locale w/ out a territory' );
ok( $en_au->get_language_from_code() eq $Locales::DB::Language::en_au::code_to_name{ $en_au->get_locale() }, 'get_territory_from_code() no arg on locale w/ a territory' );

ok( $en->get_language_from_code( 'yyyy',       1 ) eq 'yyyy',                                                   'get_language_from_code() + unknown lang only + always_return' );
ok( $en->get_language_from_code( 'yyyy_zzzzz', 1 ) eq 'yyyy_zzzzz',                                             'get_language_from_code() + unknown lang & unknown territory + always_return' );
ok( $en->get_language_from_code( 'en_zzzzz',   1 ) eq "$Locales::DB::Language::en::code_to_name{'en'} (zzzzz)", 'get_language_from_code() + known lang & unknown territory + always_return' );
ok( $en->get_language_from_code( 'yyyy_us',    1 ) eq "yyyy ($Locales::DB::Territory::en::code_to_name{'us'})", 'get_language_from_code() + unknown lang & known territory + always_return' );

ok( $en->get_native_language_from_code( 'yyyy',       1 ) eq $en->get_language_from_code( 'yyyy',       1 ), 'get_language_from_code() + unknown lang only + always_return' );
ok( $en->get_native_language_from_code( 'yyyy_zzzzz', 1 ) eq $en->get_language_from_code( 'yyyy_zzzzz', 1 ), 'get_language_from_code() + unknown lang & unknown territory + always_return' );
ok( $en->get_native_language_from_code( 'en_zzzzz',   1 ) eq $en->get_language_from_code( 'en_zzzzz',   1 ), 'get_language_from_code() + known lang & unknown territory + always_return' );
ok( $en->get_native_language_from_code( 'yyyy_us',    1 ) eq $en->get_language_from_code( 'yyyy_us',    1 ), 'get_language_from_code() + unknown lang & known territory + always_return' );

ok( $fr->get_native_language_from_code( 'yyyy',       1 ) eq $fr->get_language_from_code( 'yyyy',       1 ), 'get_language_from_code() + unknown lang only + always_return' );
ok( $fr->get_native_language_from_code( 'yyyy_zzzzz', 1 ) eq $fr->get_language_from_code( 'yyyy_zzzzz', 1 ), 'get_language_from_code() + unknown lang & unknown territory + always_return' );
ok( $fr->get_native_language_from_code( 'fr_zzzzz',   1 ) eq $fr->get_language_from_code( 'fr_zzzzz',   1 ), 'get_language_from_code() + known lang & unknown territory + always_return' );
ok( $fr->get_native_language_from_code( 'yyyy_us',    1 ) eq $fr->get_language_from_code( 'yyyy_us',    1 ), 'get_language_from_code() + unknown lang & known territory + always_return' );

ok( \&Locales::code2language eq \&Locales::get_language_from_code, 'code2language aliases get_language_from_code' );
ok( \&Locales::language2code eq \&Locales::get_code_from_language, 'language2code aliases get_code_from_language' );

# misc_info
my $ja = Locales->new('ja');    # ja ='{0}({1})' not '{0} ({1})'
ok( $ja->get_language_from_code( 'en_zzzzz', 1 ) eq "$Locales::DB::Language::ja::code_to_name{'en'}(zzzzz)", 'get_language_from_code() unknown part pattern' );

ok( $en->numf() eq '1', 'numf() RC == numf_comma(0)' );
ok( $it->numf() eq '2', 'numf() RC == numf_comma(1)' );

ok( ref( $ar->numf() ) eq 'ARRAY', 'numf() RC == ARRAY format' );

# is($ar->numf(1), '2', 'soft value - format diff but data matches');

# relies on 'fr' remaining broken (i.e. missing '_decimal_format_group')
ok( ref( $fr->numf() ) eq 'ARRAY', 'numf() RC == ARRAY missing data' );

# is($fr->numf(1), '2', 'soft value - only one pattern string');
