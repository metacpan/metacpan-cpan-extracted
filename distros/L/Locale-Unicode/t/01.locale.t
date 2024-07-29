#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Locale::Unicode' ) || BAIL_OUT( 'Unable to load Locale::Unicode' );
    use_ok( 'DateTime::Locale' ) || BAIL_OUT( "Cannot load DateTime::Locale" );
};

use strict;
use warnings;

my $loc = Locale::Unicode->new( 'en' );
isa_ok( $loc, 'Locale::Unicode' );

# To generate this list:
# perl -lnE '/^sub (?!new|[A-Z]|_)/ and say "can_ok( \$loc, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/Locale/Unicode.pm
# NOTE: methods check
can_ok( $loc, 'apply' );
can_ok( $loc, 'as_string' );
can_ok( $loc, 'base' );
can_ok( $loc, 'break_exclusion' );
can_ok( $loc, 'ca' );
can_ok( $loc, 'calendar' );
can_ok( $loc, 'canonical' );
can_ok( $loc, 'cf' );
can_ok( $loc, 'clone' );
can_ok( $loc, 'co' );
can_ok( $loc, 'colAlternate' );
can_ok( $loc, 'colBackwards' );
can_ok( $loc, 'colCaseLevel' );
can_ok( $loc, 'colCaseFirst' );
can_ok( $loc, 'collation' );
can_ok( $loc, 'colHiraganaQuaternary' );
can_ok( $loc, 'colNormalisation' );
can_ok( $loc, 'colNormalization' );
can_ok( $loc, 'colNumeric' );
can_ok( $loc, 'colReorder' );
can_ok( $loc, 'colStrength' );
can_ok( $loc, 'colValue' );
can_ok( $loc, 'colVariableTop' );
can_ok( $loc, 'core' );
can_ok( $loc, 'country_code' );
can_ok( $loc, 'cu_format' );
can_ok( $loc, 'cu' );
can_ok( $loc, 'currency' );
can_ok( $loc, 'd0' );
can_ok( $loc, 'dest' );
can_ok( $loc, 'destination' );
can_ok( $loc, 'dx' );
can_ok( $loc, 'em' );
can_ok( $loc, 'emoji' );
can_ok( $loc, 'error' );
can_ok( $loc, 'extended' );
can_ok( $loc, 'false' );
can_ok( $loc, 'first_day' );
can_ok( $loc, 'fw' );
can_ok( $loc, 'grandfathered' );
can_ok( $loc, 'grandfathered_irregular' );
can_ok( $loc, 'grandfathered_regular' );
can_ok( $loc, 'h0' );
can_ok( $loc, 'hc' );
can_ok( $loc, 'hour_cycle' );
can_ok( $loc, 'hybrid' );
can_ok( $loc, 'i0' );
can_ok( $loc, 'input' );
can_ok( $loc, 'k0' );
can_ok( $loc, 'ka' );
can_ok( $loc, 'kb' );
can_ok( $loc, 'kc' );
can_ok( $loc, 'keyboard' );
can_ok( $loc, 'kf' );
can_ok( $loc, 'kh' );
can_ok( $loc, 'kk' );
can_ok( $loc, 'kn' );
can_ok( $loc, 'kr' );
can_ok( $loc, 'ks' );
can_ok( $loc, 'kv' );
can_ok( $loc, 'lang' );
can_ok( $loc, 'lang3' );
can_ok( $loc, 'language' );
can_ok( $loc, 'language_extended' );
can_ok( $loc, 'language3' );
can_ok( $loc, 'language_id' );
can_ok( $loc, 'lb' );
can_ok( $loc, 'line_break' );
can_ok( $loc, 'line_break_word' );
can_ok( $loc, 'locale' );
can_ok( $loc, 'locale3' );
can_ok( $loc, 'lw' );
can_ok( $loc, 'm0' );
can_ok( $loc, 'matches' );
can_ok( $loc, 'measurement' );
can_ok( $loc, 'mechanism' );
can_ok( $loc, 'merge' );
can_ok( $loc, 'ms' );
can_ok( $loc, 'mu' );
can_ok( $loc, 'nu' );
can_ok( $loc, 'number' );
can_ok( $loc, 'overlong' );
can_ok( $loc, 'parse' );
can_ok( $loc, 'pass_error' );
can_ok( $loc, 'private' );
can_ok( $loc, 'privateuse' );
can_ok( $loc, 'region' );
can_ok( $loc, 'region_override' );
can_ok( $loc, 'rg' );
can_ok( $loc, 'reset' );
can_ok( $loc, 's0' );
can_ok( $loc, 'script' );
can_ok( $loc, 'sentence_break' );
can_ok( $loc, 'shiftedGroup' );
can_ok( $loc, 'source' );
can_ok( $loc, 'sd' );
can_ok( $loc, 'ss' );
can_ok( $loc, 'subdivision' );
can_ok( $loc, 't0' );
can_ok( $loc, 't_private' );
can_ok( $loc, 'territory' );
can_ok( $loc, 'time_zone' );
can_ok( $loc, 'timezone' );
can_ok( $loc, 'transform' );
can_ok( $loc, 'transform_locale' );
can_ok( $loc, 'translation' );
can_ok( $loc, 'true' );
can_ok( $loc, 'tz' );
can_ok( $loc, 'tz_id2name' );
can_ok( $loc, 'tz_id2names' );
can_ok( $loc, 'tz_info' );
can_ok( $loc, 'tz_name2id' );
can_ok( $loc, 'unit' );
can_ok( $loc, 'va' );
can_ok( $loc, 'variant' );
can_ok( $loc, 'variants' );
can_ok( $loc, 'vt' );
can_ok( $loc, 'x0' );

my $re;
# NOTE: Using all locale codes provided by DateTime::Locale to test
# From version 0.90 onward, the method 'codes' is available
if( $DateTime::Locale::VERSION >= 0.90 )
{
    my $codes = DateTime::Locale->codes;
    diag( "Found ", scalar( @$codes ), " locales." ) if( $DEBUG );
    foreach my $code ( @$codes )
    {
        $code = 'und' if( $code eq 'root' );
        $re = Locale::Unicode->matches( $code );
        diag( "Failed matching for locale '", ( $code // 'undef' ), "'" ) if( !defined( $re ) || ref( $re ) ne 'HASH' );
        ok( ( defined( $re ) && ref( $re ) eq 'HASH' && scalar( keys( %$re ) ) ), $code );
    }
}

# NOTE: Various locales form test data
my @tests = (
    'gsw-u-sd-chzh' => 
        {
            matches =>
            {
                ext_subdivision => "sd",
                ext_unicode => "u-sd-chzh",
                ext_unicode_subtag => "sd-chzh",
                language3 => "gsw",
                locale_bcp47 => "gsw",
                locale_extensions => "u-sd-chzh",
            },
            parse =>
            {
                language3 => "gsw",
                sd => "chzh",
                unicode_ext => ["sd"],
            },
            subs =>
            {
                language3 => "gsw",
                sd => "chzh",
            },
            stringify => 'gsw-u-sd-chzh',
        },
    'he-IL-u-ca-hebrew-tz-jeruslm' =>
        {
            matches =>
            {
                country_code => "IL",
                ext_calendar => "ca",
                ext_unicode => "u-ca-hebrew-tz-jeruslm",
                ext_unicode_subtag => "ca-hebrew-tz-jeruslm",
                language => "he",
                locale_bcp47 => "he-IL",
                locale_extensions => "u-ca-hebrew-tz-jeruslm",
            },
            parse =>
            {
                ca => "hebrew",
                country_code => "IL",
                language => "he",
                tz => "jeruslm",
                unicode_ext => [qw( ca tz )],
            },
            subs =>
            {
                ca => "hebrew",
                country_code => "IL",
                language => "he",
                tz => "jeruslm",
            },
            stringify => 'he-IL-u-ca-hebrew-tz-jeruslm',
        },
    'ja-t-it' =>
        {
            matches =>
            {
                ext_transform => "t-it",
                ext_transform_locale => "it",
                language => "ja",
                locale_bcp47 => "ja",
                locale_extensions => "t-it",
            },
            parse =>
            {
                language => "ja",
                transform_ext => [],
                transform_locale => 'it',
            },
            subs =>
            {
                language => "ja",
                transform_locale => 'it',
            },
            stringify => 'ja-t-it',
        },
    'ja-Kana-t-it' =>
        {
            matches =>
            {
                ext_transform => "t-it",
                ext_transform_locale => "it",
                language => "ja",
                locale_bcp47 => "ja-Kana",
                locale_extensions => "t-it",
                script => "Kana",
            },
            parse =>
            {
                language => "ja",
                script => "Kana",
                transform_ext => [],
                transform_locale => 'it',
            },
            subs =>
            {
                language => "ja",
                script => "Kana",
                transform_locale => 'it',
            },
            stringify => 'ja-Kana-t-it',
        },
    'und-Latn-t-und-cyrl' =>
        {
            matches =>
            {
                ext_transform => "t-und-cyrl",
                ext_transform_locale => "und-cyrl",
                language3 => "und",
                locale_bcp47 => "und-Latn",
                locale_extensions => "t-und-cyrl",
                script => "Latn",
            },
            parse =>
            {
                language3 => "und",
                script => "Latn",
                transform_ext => [],
                transform_locale => 'und-cyrl',
            },
            subs =>
            {
                language3 => "und",
                script => "Latn",
                transform_locale => 'und-cyrl',
            },
            stringify => 'und-Latn-t-und-cyrl',
        },
    'und-Cyrl-t-und-latn-m0-ungegn-2007' =>
        {
            matches =>
            {
                ext_mechanism => "m0",
                ext_transform => "t-und-latn-m0-ungegn-2007",
                ext_transform_locale => "und-latn",
                ext_transform_subtag => "m0-ungegn-2007",
                language3 => "und",
                locale_bcp47 => "und-Cyrl",
                locale_extensions => "t-und-latn-m0-ungegn-2007",
                script => "Cyrl",
            },
            parse =>
            {
                language3 => "und",
                m0 => "ungegn-2007",
                script => "Cyrl",
                transform_ext => ["m0"],
                transform_locale => 'und-latn',
            },
            subs =>
            {
                language3 => "und",
                m0 => "ungegn-2007",
                script => "Cyrl",
                transform_locale => 'und-latn',
            },
            stringify => 'und-Cyrl-t-und-latn-m0-ungegn-2007',
        },
    'de-u-co-phonebk-ka-shifted' =>
        {
            matches =>
            {
                collation_options => "ka-shifted",
                ext_collation => "co",
                ext_unicode => "u-co-phonebk-ka-shifted",
                ext_unicode_subtag => "co-phonebk",
                language => "de",
                locale_bcp47 => "de",
                locale_extensions => "u-co-phonebk-ka-shifted",
            },
            parse =>
            {
                co => "phonebk",
                ka => "shifted",
                language => "de",
                unicode_ext => [qw( co ka )],
            },
            subs =>
            {
                co => "phonebk",
                ka => "shifted",
                language => "de",
            },
            stringify => 'de-u-co-phonebk-ka-shifted',
        },
    'ja-t-de-t0-und' =>
        {
            matches =>
            {
                ext_transform => "t-de-t0-und",
                ext_transform_locale => "de",
                ext_transform_subtag => "t0-und",
                ext_translation => "t0",
                language => "ja",
                locale_bcp47 => "ja",
                locale_extensions => "t-de-t0-und",
            },
            parse =>
            {
                language => "ja",
                t0 => "und",
                transform_ext => ["t0"],
                transform_locale => 'de',
            },
            subs =>
            {
                language => "ja",
                t0 => "und",
                transform_locale => 'de',
            },
            stringify => 'ja-t-de-t0-und',
        },
    'ja-t-de-t0-und-x0-medical' =>
        {
            matches =>
            {
                ext_transform => "t-de-t0-und-x0-medical",
                ext_transform_locale => "de",
                ext_transform_subtag => "t0-und",
                ext_translation => "t0",
                language => "ja",
                locale_bcp47 => "ja",
                locale_extensions => "t-de-t0-und-x0-medical",
                transform_options => "x0-medical",
            },
            parse =>
            {
                language => "ja",
                t0 => "und",
                transform_ext => [qw( t0 x0 )],
                transform_locale => 'de',
                x0 => "medical",
            },
            subs =>
            {
                language => "ja",
                t0 => "und",
                transform_locale => 'de',
                x0 => "medical",
            },
            stringify => 'ja-t-de-t0-und-x0-medical',
        },
    'ja-t-de-AT-t0-und-x0-medical-u-ca-japanese-tz-jptyo-nu-jpanfin-x-private-subtag' =>
        {
            matches =>
            {
                ext_calendar => "ca",
                ext_transform => "t-de-AT-t0-und-x0-medical",
                ext_transform_locale => "de-AT",
                ext_transform_subtag => "t0-und",
                ext_translation => "t0",
                ext_unicode => "u-ca-japanese-tz-jptyo-nu-jpanfin",
                ext_unicode_subtag => "ca-japanese-tz-jptyo-nu-jpanfin",
                language => "ja",
                locale_bcp47 => "ja",
                locale_extensions => "t-de-AT-t0-und-x0-medical-u-ca-japanese-tz-jptyo-nu-jpanfin",
                private_extension => 'x-private-subtag',
                private_subtag => 'private-subtag',
                transform_options => "x0-medical",
            },
            parse =>
            {
                ca => "japanese",
                language => "ja",
                nu => "jpanfin",
                private => "private-subtag",
                t0 => "und",
                transform_ext => [qw( t0 x0 )],
                transform_locale => 'de-AT',
                tz => "jptyo",
                unicode_ext => [qw( ca tz nu )],
                x0 => "medical",
            },
            subs =>
            {
                ca => "japanese",
                language => "ja",
                nu => "jpanfin",
                private => "private-subtag",
                t0 => "und",
                transform_locale => 'de-AT',
                tz => "jptyo",
                x0 => "medical",
            },
            # It is different intentionally from the string provided, because the Unicode extension 't' comes before the extension 'u'
            stringify => 'ja-u-ca-japanese-nu-jpanfin-tz-jptyo-t-de-AT-t0-und-x0-medical-x-private-subtag',
        },
    'zh-cmn-Hans-CN' =>
        {
            matches =>
            {
                country_code => "CN",
                extended => "cmn",
                language => "zh",
                locale_bcp47 => "zh-cmn-Hans-CN",
                script => "Hans",
                territory => "CN",
            },
            parse =>
            {
                country_code => "CN",
                extended => "cmn",
                language => "zh",
                script => "Hans",
            },
            subs =>
            {
                country_code => "CN",
                extended => "cmn",
                language => "zh",
                language_extended => "zh-cmn",
                core => "zh-cmn-Hans-CN",
                script => "Hans",
                territory => "CN",
            },
            stringify => 'zh-cmn-Hans-CN',
        },
    'zh-yue-HK' =>
        {
            matches =>
            {
                country_code => "HK",
                extended => "yue",
                language => "zh",
                locale_bcp47 => "zh-yue-HK",
                territory => "HK",
            },
            parse =>
            {
                country_code => "HK",
                extended => "yue",
                language => "zh",
            },
            subs =>
            {
                country_code => "HK",
                extended => "yue",
                language => "zh",
                language_extended => "zh-yue",
                core => "zh-yue-HK",
                script => undef,
                territory => "HK",
            },
            stringify => 'zh-yue-HK',
        },
    'root' =>
        {
            matches =>
            {
                locale_bcp47 => "root",
                root => "root",
            },
            parse =>
            {
                language => "root",
            },
            subs =>
            {
                extended => undef,
                language => "root",
                language_extended => "root",
                core => "root",
                script => undef,
                territory => undef,
            },
            stringify => 'root',
        },
    'de-1996-fonipa-1606nict' =>
        {
            matches =>
            {
                language => "de",
                locale_bcp47 => "de-1996-fonipa-1606nict",
                variant => "1996-fonipa-1606nict",
            },
            parse =>
            {
                language => "de",
                variant => "1996-fonipa-1606nict",
            },
            subs =>
            {
                extended => undef,
                language => "de",
                language_extended => "de",
                core => "de-1996-fonipa-1606nict",
                script => undef,
                territory => undef,
                variant => "1996-fonipa-1606nict",
            },
            stringify => 'de-1996-fonipa-1606nict',
        },
    'und-x-i-enochian' =>
        {
            matches =>
            {
                language3 => "und",
                locale_bcp47 => "und",
                private_extension => "x-i-enochian",
                private_subtag => "i-enochian",
            },
            parse =>
            {
                language3 => "und",
                private => "i-enochian",
            },
            subs =>
            {
                extended => undef,
                language => undef,
                language3 => "und",
                language_extended => "und",
                core => "und",
                private => "i-enochian",
                script => undef,
                territory => undef,
                variant => undef,
            },
            stringify => 'und-x-i-enochian',
        },
);

# NOTE: various locales form check
my $meth_cache = {};
for( my $i = 0; $i < scalar( @tests ); $i += 2 )
{
    my $t = $tests[$i];
    my $def = $tests[$i + 1];
    subtest $t => sub
    {
        my $re = Locale::Unicode->matches( $t );
        foreach my $k ( sort( keys( %{$def->{matches}} ) ) )
        {
            is( $re->{ $k }, $def->{matches}->{ $k }, $k );
        }
        my $info = Locale::Unicode->parse( $t );
        ok( $info, 'parse' );
        SKIP:
        {
            if( !defined( $info ) )
            {
                skip( "parse failed for $t: " . Locale::Unicode->error, 1 );
            }
        };
        my $locale = Locale::Unicode->new( $t );
        isa_ok( $locale, 'Locale::Unicode', "Locale::Unicode->new( '$t' )" );
        SKIP:
        {
            if( !defined( $locale ) )
            {
                skip( "Error instantiating Locale::Unicode object for '$t': " . Locale::Unicode->error, 1 );
            }
            is( "$locale", $def->{stringify}, "stringification of object yields ${t}" );
            foreach my $meth ( sort( keys( %{$def->{subs}} ) ) )
            {
                my $code;
                unless( $code = $meth_cache->{ $meth } )
                {
                    if( !( $code = $locale->can( $meth ) ) )
                    {
                        fail( "Unable to get reference for method Locale::Unicode->${meth}" );
                        next;
                    }
                    $meth_cache->{ $meth } = $code;
                }
                my $rv = $code->( $locale );
                is( defined( $rv ) ? "$rv" : undef, $def->{subs}->{ $meth }, "\$locale->${meth}() -> '" . ( $rv // 'undef' ) . "' vs expected '" . ( $def->{subs}->{ $meth } // 'undef' ) . "'" );
            }
        };
    };
}

# NOTE: instantiate and change
subtest 'instantiate and change' => sub
{
    my $locale = Locale::Unicode->new( 'ja-t-de-t0-und' );
    isa_ok( $locale => 'Locale::Unicode' );
    SKIP:
    {
        if( !defined( $locale ) )
        {
            skip( "Failed instantiating Locale::Unicode object for 'ja-t-de-t0-und': " . Locale::Unicode->error, 1 );
        }
        $locale->script( 'Kana' );
        $locale->country_code( 'JP' );
        is( "$locale", 'ja-Kana-JP-t-de-t0-und', 'ja-t-de-t0-und -> ja-Kana-JP-t-de-t0-und' );
    };
};

# NOTE: transform
subtest 'transform' => sub
{
    my $locale = Locale::Unicode->new( 'ja' );
    $locale->transform( 'de-AT' );
    isa_ok( $locale->transform, 'Locale::Unicode', '$locale->transform( $string ) -> Locale::Unicode' );

    my $locale2 = Locale::Unicode->new( 'ko-KR' );
    $locale->transform( $locale2 );
    isa_ok( $locale->transform, 'Locale::Unicode', '$locale->transform( $object ) -> Locale::Unicode' );
};

# NOTE: chaining
subtest 'chaining' => sub
{
    my $locale = Locale::Unicode->new( 'ja' );
    $locale->transform( 'de-AT' )->tz( 'jptyo' )->ca( 'japanese' );
    is( $locale->transform_locale, 'de-AT', 'transform_locale' );
    is( $locale->tz, 'jptyo', 'tz' );
    is( $locale->ca, 'japanese', 'ca' );
};

# NOTE: tz_ functions
subtest 'tz_ functions' => sub
{
    is( Locale::Unicode->tz_id2name( 'jptyo' ), 'Asia/Tokyo', 'tz_id2name' );
    my $ref = Locale::Unicode->tz_id2names( 'ausyd' );
    local $" = ' ';
    is( "@$ref", 'Australia/Sydney Australia/ACT Australia/Canberra Australia/NSW', 'tz_id2names' );
    my $info = Locale::Unicode->tz_info( 'jptyo' );
    my $expected =
    {
        alias => [qw( Asia/Tokyo Japan )],
        desc => "Tokyo, Japan",
        tz => "Asia/Tokyo",
    };
    is_deeply( $info => $expected, 'tz_info' );
    is( Locale::Unicode->tz_name2id( 'Australia/Canberra' ), 'ausyd', 'tz_name2id' );
};

# NOTE: colCaseFirst
subtest 'colCaseFirst' => sub
{
    my @tests = (
        {
            test => 'fr-Latn-FR-u-kf-upper',
            expects => 'upper',
        },
        {
            test => 'en-Latn-US',
            opts => { colCaseFirst => 'lower' },
            expects => 'lower',
        },
    );
    
    foreach my $def ( @tests )
    {
        my $l = Locale::Unicode->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        isa_ok( $l => 'Locale::Unicode' );
        SKIP:
        {
            if( !defined( $l ) )
            {
                skip( "Failed instantiating object for test locale '$def->{test}': " . Locale::Unicode->error, 1 );
            }
            diag( "Locale for '$def->{test}' stringifies to '$l'" ) if( $DEBUG );
            is( $l->colCaseFirst, $def->{expects}, "colCaseFirst for '$def->{test}' -> '$def->{expects}'" );
        };
    }
};

# NOTE: grandfathered irregular
subtest 'grandfathered irregular' => sub
{
    my @tests = (
        {
            test => 'en-GB-oed',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'en-GB-oed',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-ami',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-ami',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-bnn',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-bnn',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-default',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-default',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-enochian',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-enochian',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-hak',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-hak',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-klingon',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-klingon',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-lux',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-lux',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-mingo',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-mingo',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-navajo',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-navajo',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-pwn',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-pwn',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-tao',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-tao',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-tay',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-tay',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'i-tsu',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'i-tsu',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'sgn-BE-FR',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'sgn-BE-FR',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'sgn-BE-NL',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'sgn-BE-NL',
                grandfathered_regular => undef,
            }
        },
    
        {
            test => 'sgn-CH-DE',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => 'sgn-CH-DE',
                grandfathered_regular => undef,
            }
        },
    );

    foreach my $def ( @tests )
    {
        my $l = Locale::Unicode->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        isa_ok( $l => 'Locale::Unicode' );
        SKIP:
        {
            if( !defined( $l ) )
            {
                skip( "Failed instantiating object for test locale '$def->{test}': " . Locale::Unicode->error, 1 );
            }
            diag( "Locale for '$def->{test}' stringifies to '$l'" ) if( $DEBUG );
            foreach my $meth ( sort( keys( %{$def->{expects}} ) ) )
            {
                my $coderef = $l->can( $meth ) || BAIL_OUT( "Unable to find method ${meth} in Locale::Unicode !" );
                my $val = $coderef->( $l );
                is( $val => $def->{expects}->{ $meth }, "${meth} expects " . ( $def->{expects}->{ $meth } // 'undef' ) );
            }
        };
    }

    my $l = Locale::Unicode->new( 'ja-Kana-JP' );
    isa_ok( $l => 'Locale::Unicode' );
    $l->grandfathered( 'sgn-CH-DE' );
    is( $l->grandfathered_irregular, 'sgn-CH-DE', 'grandfathered_irregular() -> sgn-CH-DE' );
    is( $l->grandfathered_regular, undef, 'grandfathered_irregular() -> undef' );
    is( "$l", "sgn-CH-DE", '$l -> sgn-CH-DE' );
};

# NOTE: grandfathered regular
subtest 'grandfathered regular' => sub
{
    my @tests = (
        {
            test => 'art-lojban',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => undef,
                grandfathered_regular => 'art-lojban',
            }
        },
    
        {
            test => 'cel-gaulish',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => undef,
                grandfathered_regular => 'cel-gaulish',
            }
        },
    
        {
            test => 'no-bok',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => undef,
                grandfathered_regular => 'no-bok',
            }
        },
    
        {
            test => 'no-nyn',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => undef,
                grandfathered_regular => 'no-nyn',
            }
        },
    
        {
            test => 'zh-guoyu',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => undef,
                grandfathered_regular => 'zh-guoyu',
            }
        },
    
        {
            test => 'zh-hakka',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => undef,
                grandfathered_regular => 'zh-hakka',
            }
        },
    
        {
            test => 'zh-min',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => undef,
                grandfathered_regular => 'zh-min',
            }
        },
    
        {
            test => 'zh-min-nan',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => undef,
                grandfathered_regular => 'zh-min-nan',
            }
        },
    
        {
            test => 'zh-xiang',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => undef,
                grandfathered_irregular => undef,
                grandfathered_regular => 'zh-xiang',
            }
        },
    );

    foreach my $def ( @tests )
    {
        my $l = Locale::Unicode->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        isa_ok( $l => 'Locale::Unicode' );
        SKIP:
        {
            if( !defined( $l ) )
            {
                skip( "Failed instantiating object for test locale '$def->{test}': " . Locale::Unicode->error, 1 );
            }
            diag( "Locale for '$def->{test}' stringifies to '$l'" ) if( $DEBUG );
            foreach my $meth ( sort( keys( %{$def->{expects}} ) ) )
            {
                my $coderef = $l->can( $meth ) || BAIL_OUT( "Unable to find method ${meth} in Locale::Unicode !" );
                my $val = $coderef->( $l );
                is( $val => $def->{expects}->{ $meth }, "${meth} expects " . ( $def->{expects}->{ $meth } // 'undef' ) );
            }
        };
    }

    my $l = Locale::Unicode->new( 'ja-Kana-JP' );
    isa_ok( $l => 'Locale::Unicode' );
    $l->grandfathered( 'zh-min-nan' );
    is( $l->grandfathered_regular, 'zh-min-nan', 'grandfathered_regular() -> zh-min-nan' );
    is( $l->grandfathered_irregular, undef, 'grandfathered_irregular() -> undef' );
    is( "$l", "zh-min-nan", '$l -> zh-min-nan' );
};

# NOTE: privateuse
subtest 'privateuse' => sub
{
    my @tests = 
    (
        {
            test => 'x-abc',
            expects =>
            {
                language => undef,
                language3 => undef,
                privateuse => 'abc',
                grandfathered_irregular => undef,
                grandfathered_regular => undef,
            }
        }
    );

    foreach my $def ( @tests )
    {
        my $l = Locale::Unicode->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        isa_ok( $l => 'Locale::Unicode' );
        SKIP:
        {
            if( !defined( $l ) )
            {
                skip( "Failed instantiating object for test locale '$def->{test}': " . Locale::Unicode->error, 1 );
            }
            diag( "Locale for '$def->{test}' stringifies to '$l'" ) if( $DEBUG );
            foreach my $meth ( sort( keys( %{$def->{expects}} ) ) )
            {
                my $coderef = $l->can( $meth ) || BAIL_OUT( "Unable to find method ${meth} in Locale::Unicode !" );
                my $val = $coderef->( $l );
                is( $val => $def->{expects}->{ $meth }, "${meth} expects " . ( $def->{expects}->{ $meth } // 'undef' ) );
            }
        };
    }

    my $l = Locale::Unicode->new( 'ja-Kana-JP' );
    isa_ok( $l => 'Locale::Unicode' );
    $l->privateuse( 'abc' );
    is( "$l", "x-abc", '$l -> x-abc' );
};

# NOTE: canonical
subtest 'canonical' => sub
{
    my @tests =
    (
        {
            test => 'ja-kana-jp',
            expects => 'ja-Kana-JP',
        },
        {
            test => 'root',
            expects => 'und',
        },
        {
            test => 'de-1996-fonipa-1996',
            expects => 'de-1996-fonipa',
        }
    );
    foreach my $def ( @tests )
    {
        my $l = Locale::Unicode->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        isa_ok( $l => 'Locale::Unicode' );
        SKIP:
        {
            if( !defined( $l ) )
            {
                skip( "Failed instantiating object for test locale '$def->{test}': " . Locale::Unicode->error, 1 );
            }
            diag( "Locale for '$def->{test}' stringifies to '$l'" ) if( $DEBUG );
            my $me = $l->canonical;
            if( !defined( $me ) )
            {
                diag( "Unable to get the canonical form for object '$def->{test}': ", $l->error ) if( $DEBUG );
            }
            isa_ok( $me => 'Locale::Unicode' );
            is( "$me" => $def->{expects}, "$def->{test} -> $def->{expects}" );
        };
    }
};

# NOTE: merge
subtest 'merge' => sub
{
    my $locale1 = Locale::Unicode->new( 'ja-JP' );
    my $locale2 = Locale::Unicode->new( 'ja-Kana-hepburn-heploc' );
    $locale1->merge( $locale2 );
    is( "$locale1", 'ja-Kana-JP-hepburn-heploc', 'merge -> ja-Kana-JP-hepburn-heploc' );

    $locale1 = Locale::Unicode->new( 'ja-Kana-posix-hepburn' );
    $locale2 = Locale::Unicode->new( 'ja-JP-hepburn-heploc' );
    $locale1->merge( $locale2 );
    is( "$locale1", 'ja-Kana-JP-posix-hepburn-heploc', 'merge -> ja-Kana-JP-posix-hepburn-heploc' );
};

# NOTE: overlong
subtest 'overlong' => sub
{
    # no warnings 'Locale::Unicode';
    # Italian at Vatican City
    my $locale = Locale::Unicode->new( 'it-VAT' );
    is( $locale->extended, 'VAT', 'it-VAT -> VAT is extended subtag' );
    is( $locale->overlong, undef, 'it-VAT -> overlong is undef' );

    # Spanish as spoken at Panama
    $locale = Locale::Unicode->new( 'es-PAN-valencia' );
    is( $locale->extended, 'PAN', 'es-PAN-valencia -> PAN is extended subtag' );
    is( $locale->overlong, undef, 'es-PAN-valencia -> overlong is undef' );

    $locale = Locale::Unicode->new( 'en-US' );
    is( $locale->overlong, undef, '[overlong] en-US -> undef' );
    is( $locale->country_code, 'US', '[country_code] en-US -> US' );
    is( $locale->territory, 'US', '[territory] en-US -> US' );
    # Changing to overlong USA
    $locale->overlong( 'USA' );
    is( $locale->overlong, 'USA', '[overlong] en-US -> USA' );
    is( $locale->country_code, 'USA', '[country_code] en-US -> undef' );
    is( $locale->territory, 'USA', '[territory] en-US -> undef' );
};

# NOTE: base
subtest 'base' => sub
{
    my $locale = Locale::Unicode->new( 'en-US' );
    is( $locale->base, 'en-US', 'base -> en-US' );

    $locale = Locale::Unicode->new( 'en-Latn-US-posix-t-de-AT-t0-und-x0-medical' );
    is( $locale->base, 'en-Latn-US-posix', 'base -> en-Latn-US-posix' );
    ok( $locale->base( 'ja-JP' ), 'base( ja-JP )' );
    is( $locale->base, 'ja-JP', 'base -> ja-JP' );
    is( "$locale", 'ja-JP-t-de-AT-t0-und-x0-medical', 'stringification -> ja-JP-t-de-AT-t0-und-x0-medical' );

    $locale = Locale::Unicode->new( 'en-US' );
    $locale->base( 'en-GB-1996-fonipa-1996' );
    is( $locale->base, 'en-GB-1996-fonipa-1996', 'base -> en-GB-1996-fonipa-1996' );
    is( "$locale", 'en-GB-1996-fonipa-1996', 'stringification -> en-GB-1996-fonipa-1996' );
};

done_testing();

__END__

