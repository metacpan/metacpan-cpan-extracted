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
can_ok( $loc, 'apply' );
can_ok( $loc, 'as_string' );
can_ok( $loc, 'break_exclusion' );
can_ok( $loc, 'ca' );
can_ok( $loc, 'calendar' );
can_ok( $loc, 'cf' );
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
can_ok( $loc, 'false' );
can_ok( $loc, 'first_day' );
can_ok( $loc, 'fw' );
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
can_ok( $loc, 'ms' );
can_ok( $loc, 'mu' );
can_ok( $loc, 'nu' );
can_ok( $loc, 'number' );
can_ok( $loc, 'parse' );
can_ok( $loc, 'pass_error' );
can_ok( $loc, 'private' );
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
can_ok( $loc, 'time_zone' );
can_ok( $loc, 'timezone' );
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
can_ok( $loc, 'vt' );
can_ok( $loc, 'x0' );

my $re;
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

my @tests = (
    'gsw-u-sd-chzh' => 
        {
            matches =>
            {
                ext_subdivision => "sd",
                ext_unicode => "u-sd-chzh",
                ext_unicode_subtag => "sd-chzh",
                locale3 => "gsw",
                locale_bcp47 => "gsw",
                locale_extensions => "u-sd-chzh",
            },
            parse =>
            {
                locale3 => "gsw",
                sd => "chzh",
                unicode_ext => ["sd"],
            },
            subs =>
            {
                locale3 => "gsw",
                sd => "chzh",
            },
        },
    'he-IL-u-ca-hebrew-tz-jeruslm' =>
        {
            matches =>
            {
                country_code => "IL",
                ext_calendar => "ca",
                ext_unicode => "u-ca-hebrew-tz-jeruslm",
                ext_unicode_subtag => "ca-hebrew-tz-jeruslm",
                locale => "he",
                locale_bcp47 => "he-IL",
                locale_extensions => "u-ca-hebrew-tz-jeruslm",
            },
            parse =>
            {
                ca => "hebrew",
                country_code => "IL",
                locale => "he",
                tz => "jeruslm",
                unicode_ext => [qw( ca tz )],
            },
            subs =>
            {
                ca => "hebrew",
                country_code => "IL",
                locale => "he",
                tz => "jeruslm",
            },
        },
    'ja-t-it' =>
        {
            matches =>
            {
                ext_transform => "t-it",
                ext_transform_locale => "it",
                locale => "ja",
                locale_bcp47 => "ja",
                locale_extensions => "t-it",
            },
            parse =>
            {
                locale => "ja",
                transform_ext => [],
                transform_locale => 'it',
            },
            subs =>
            {
                locale => "ja",
                transform_locale => 'it',
            },
        },
    'ja-Kana-t-it' =>
        {
            matches =>
            {
                ext_transform => "t-it",
                ext_transform_locale => "it",
                locale => "ja",
                locale_bcp47 => "ja-Kana",
                locale_extensions => "t-it",
                script => "Kana",
            },
            parse =>
            {
                locale => "ja",
                script => "Kana",
                transform_ext => [],
                transform_locale => 'it',
            },
            subs =>
            {
                locale => "ja",
                script => "Kana",
                transform_locale => 'it',
            },
        },
    'und-Latn-t-und-cyrl' =>
        {
            matches =>
            {
                ext_transform => "t-und-cyrl",
                ext_transform_locale => "und-cyrl",
                locale3 => "und",
                locale_bcp47 => "und-Latn",
                locale_extensions => "t-und-cyrl",
                script => "Latn",
            },
            parse =>
            {
                locale3 => "und",
                script => "Latn",
                transform_ext => [],
                transform_locale => 'und-cyrl',
            },
            subs =>
            {
                locale3 => "und",
                script => "Latn",
                transform_locale => 'und-cyrl',
            },
        },
    'und-Cyrl-t-und-latn-m0-ungegn-2007' =>
        {
            matches =>
            {
                ext_mechanism => "m0",
                ext_transform => "t-und-latn-m0-ungegn-2007",
                ext_transform_locale => "und-latn",
                ext_transform_subtag => "m0-ungegn-2007",
                locale3 => "und",
                locale_bcp47 => "und-Cyrl",
                locale_extensions => "t-und-latn-m0-ungegn-2007",
                script => "Cyrl",
            },
            parse =>
            {
                locale3 => "und",
                m0 => "ungegn-2007",
                script => "Cyrl",
                transform_ext => ["m0"],
                transform_locale => 'und-latn',
            },
            subs =>
            {
                locale3 => "und",
                m0 => "ungegn-2007",
                script => "Cyrl",
                transform_locale => 'und-latn',
            },
        },
    'de-u-co-phonebk-ka-shifted' =>
        {
            matches =>
            {
                collation_options => "ka-shifted",
                ext_collation => "co",
                ext_unicode => "u-co-phonebk-ka-shifted",
                ext_unicode_subtag => "co-phonebk",
                locale => "de",
                locale_bcp47 => "de",
                locale_extensions => "u-co-phonebk-ka-shifted",
            },
            parse =>
            {
                co => "phonebk",
                ka => "shifted",
                locale => "de",
                unicode_ext => [qw( co ka )],
            },
            subs =>
            {
                co => "phonebk",
                ka => "shifted",
                locale => "de",
            },
        },
    'ja-t-de-t0-und' =>
        {
            matches =>
            {
                ext_transform => "t-de-t0-und",
                ext_transform_locale => "de",
                ext_transform_subtag => "t0-und",
                ext_translation => "t0",
                locale => "ja",
                locale_bcp47 => "ja",
                locale_extensions => "t-de-t0-und",
            },
            parse =>
            {
                locale => "ja",
                t0 => "und",
                transform_ext => ["t0"],
                transform_locale => 'de',
            },
            subs =>
            {
                locale => "ja",
                t0 => "und",
                transform_locale => 'de',
            },
        },
    'ja-t-de-t0-und-x0-medical' =>
        {
            matches =>
            {
                ext_transform => "t-de-t0-und-x0-medical",
                ext_transform_locale => "de",
                ext_transform_subtag => "t0-und",
                ext_translation => "t0",
                locale => "ja",
                locale_bcp47 => "ja",
                locale_extensions => "t-de-t0-und-x0-medical",
                transform_options => "x0-medical",
            },
            parse =>
            {
                locale => "ja",
                t0 => "und",
                transform_ext => [qw( t0 x0 )],
                transform_locale => 'de',
                x0 => "medical",
            },
            subs =>
            {
                locale => "ja",
                t0 => "und",
                transform_locale => 'de',
                x0 => "medical",
            },
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
                locale => "ja",
                locale_bcp47 => "ja",
                locale_extensions => "t-de-AT-t0-und-x0-medical-u-ca-japanese-tz-jptyo-nu-jpanfin",
                private_extension => 'x-private-subtag',
                private_subtag => 'private-subtag',
                transform_options => "x0-medical",
            },
            parse =>
            {
                ca => "japanese",
                locale => "ja",
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
                locale => "ja",
                nu => "jpanfin",
                private => "private-subtag",
                t0 => "und",
                transform_locale => 'de-AT',
                tz => "jptyo",
                x0 => "medical",
            },
        },
);

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
                is( "${rv}", $def->{subs}->{ $meth }, "\$locale->${meth}() -> '" . ( $rv // 'undef' ) . "' vs expected '" . ( $def->{subs}->{ $meth } // 'undef' ) . "'" );
            }
        };
    };
}

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

subtest 'transform' => sub
{
    my $locale = Locale::Unicode->new( 'ja' );
    $locale->transform( 'de-AT' );
    isa_ok( $locale->transform, 'Locale::Unicode', '$locale->transform( $string ) -> Locale::Unicode' );

    my $locale2 = Locale::Unicode->new( 'ko-KR' );
    $locale->transform( $locale2 );
    isa_ok( $locale->transform, 'Locale::Unicode', '$locale->transform( $object ) -> Locale::Unicode' );
};

subtest 'chaining' => sub
{
    my $locale = Locale::Unicode->new( 'ja' );
    $locale->transform( 'de-AT' )->tz( 'jptyo' )->ca( 'japanese' );
    is( $locale->transform_locale, 'de-AT', 'transform_locale' );
    is( $locale->tz, 'jptyo', 'tz' );
    is( $locale->ca, 'japanese', 'ca' );
};

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

done_testing();

__END__

