#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $AUTHOR_TESTING $DEBUG $CLDR_VERSION );
    use utf8;
    use version;
    use Config;
    use Test::More;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
    }
    elsif( $^O eq 'openbsd' && ( $^V >= v5.12.0 && $^V <= v5.12.5 ) )
    {
        plan skip_all => 'Weird memory bug out of my control on OpenBSD for v5.12.0 to 5';
    }
    our $DEBUG          = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    our $AUTHOR_TESTING = $DEBUG;
    our $CLDR_VERSION   = '48.2';
};

BEGIN
{
    use_ok( 'Locale::Unicode::Data' ) || BAIL_OUT( 'Unable to load Locale::Unicode::Data' );
};

use strict;
use warnings;
use utf8;

sub is_unbounded_array_scan
{
    my( $def ) = @_;
    return(0) unless( ref( $def ) eq 'HASH' );
    return(0) unless( exists( $def->{expect} ) && !ref( $def->{expect} ) && $def->{expect} eq 'array' );
    return(0) unless( exists( $def->{args} ) && ref( $def->{args} ) eq 'ARRAY' );
    return( scalar( @{$def->{args}} ) ? 0 : 1 );
}

local $Locale::Unicode::Data::DEBUG = $DEBUG;
my $cldr = Locale::Unicode::Data->new;
isa_ok( $cldr, 'Locale::Unicode::Data' );

# NOTE: can_ok checks for all new methods added in v1.9.0
can_ok( $cldr, 'person_name_derive_order' );
can_ok( $cldr, 'person_name_format' );
can_ok( $cldr, 'person_name_formats' );
can_ok( $cldr, 'person_name_initial_pattern' );
can_ok( $cldr, 'person_name_initial_patterns' );
can_ok( $cldr, 'person_name_order_locale' );
can_ok( $cldr, 'person_name_order_locales' );
can_ok( $cldr, 'person_name_sample' );
can_ok( $cldr, 'person_name_samples' );
can_ok( $cldr, 'person_name_space_replacement' );

my $tests =
{
    # NOTE: person_name_formats
    # Source: main/ja.xml, main/en.xml, main/root.xml -> stored as locale 'und'
    person_name_formats =>
    [
        # Exact lookup: Japanese surnameFirst long referring formal
        {
            method  => 'person_name_format',
            args    => [qw( locale ja name_order surnameFirst name_length long name_usage referring name_formality formal )],
            expect  =>
            {
                locale          => 'ja',
                name_order      => 'surnameFirst',
                name_length     => 'long',
                name_usage      => 'referring',
                name_formality  => 'formal',
                alt             => undef,
                name_pattern    => '{surname} {given2} {given}{title}',
            },
        },
        # English givenFirst long referring formal
        {
            method  => 'person_name_format',
            args    => [qw( locale en name_order givenFirst name_length long name_usage referring name_formality formal )],
            expect  =>
            {
                locale          => 'en',
                name_order      => 'givenFirst',
                name_length     => 'long',
                name_usage      => 'referring',
                name_formality  => 'formal',
                alt             => undef,
                name_pattern    => '{title} {given} {given2} {surname} {generation}, {credentials}',
            },
        },
        # The 'und' locale (root.xml) - givenFirst long referring formal
        {
            method  => 'person_name_format',
            args    => [qw( locale und name_order givenFirst name_length long name_usage referring name_formality formal )],
            expect  =>
            {
                locale          => 'und',
                name_order      => 'givenFirst',
                name_length     => 'long',
                name_usage      => 'referring',
                name_formality  => 'formal',
                alt             => undef,
                name_pattern    => '{title} {given} {given2} {surname} {surname2} {credentials}',
            },
        },
        # English surnameFirst long referring formal
        {
            method  => 'person_name_format',
            args    => [qw( locale en name_order surnameFirst name_length long name_usage referring name_formality formal )],
            expect  =>
            {
                locale          => 'en',
                name_order      => 'surnameFirst',
                name_length     => 'long',
                name_usage      => 'referring',
                name_formality  => 'formal',
                alt             => undef,
                name_pattern    => '{surname} {title} {given} {given2} {generation}, {credentials}',
            },
        },
        # Filter by locale only
        {
            method  => 'person_name_formats',
            args    => [locale => 'ja'],
            expect  => 'array',
        },
        # Filter by locale and order
        {
            method  => 'person_name_formats',
            args    => [locale => 'ja', name_order => 'surnameFirst'],
            expect  => 'array',
        },
        # Filter by locale and length
        {
            method  => 'person_name_formats',
            args    => [locale => 'en', name_length => 'short'],
            expect  => 'array',
        },
        # Filter by locale, order, and usage
        {
            method  => 'person_name_formats',
            args    => [locale => 'ja', name_order => 'givenFirst', name_usage => 'monogram'],
            expect  => 'array',
        },
        # Unbounded scan - author only
        {
            method  => 'person_name_formats',
            args    => [],
            expect  => 'array',
        },
    ],

    # NOTE: person_name_initial_patterns
    # Source: main/en.xml (initial='{0}.', initialSequence='{0}{1}')
    #         main/root.xml stored as 'und' (initial='{0}.', initialSequence='{0} {1}')
    person_name_initial_patterns =>
    [
        # English initial pattern
        {
            method  => 'person_name_initial_pattern',
            args    => [locale => 'en', pattern_type => 'initial'],
            expect  =>
            {
                locale          => 'en',
                pattern_type    => 'initial',
                pattern_value   => '{0}.',
                is_draft        => 0,
            },
        },
        # English initialSequence - no space between initials (en-specific)
        {
            method  => 'person_name_initial_pattern',
            args    => [locale => 'en', pattern_type => 'initialSequence'],
            expect  =>
            {
                locale          => 'en',
                pattern_type    => 'initialSequence',
                pattern_value   => '{0}{1}',
                is_draft        => 0,
            },
        },
        # The 'und' root defaults: initialSequence uses a space separator
        {
            method  => 'person_name_initial_pattern',
            args    => [locale => 'und', pattern_type => 'initialSequence'],
            expect  =>
            {
                locale          => 'und',
                pattern_type    => 'initialSequence',
                pattern_value   => '{0} {1}',
                is_draft        => 0,
            },
        },
        # Filter: all initial patterns for English
        {
            method  => 'person_name_initial_patterns',
            args    => [locale => 'en'],
            expect  => 'array',
        },
        # Unbounded scan - author only
        {
            method  => 'person_name_initial_patterns',
            args    => [],
            expect  => 'array',
        },
    ],

    # NOTE: person_name_order_locales
    # Source: main/ja.xml -> surnameFirst: 'hu ja km ko mn vi yue zh'
    #         main/en.xml -> givenFirst: 'und en', surnameFirst: 'ja ko vi yue zh'
    person_name_order_locales =>
    [
        # Japanese locale treats Korean names as surnameFirst
        {
            method  => 'person_name_order_locale',
            args    => [locale => 'ja', name_locale => 'ko'],
            expect  =>
            {
                locale      => 'ja',
                name_locale => 'ko',
                name_order  => 'surnameFirst',
                is_draft    => 0,
            },
        },
        # English locale treats Korean names as surnameFirst
        {
            method  => 'person_name_order_locale',
            args    => [locale => 'en', name_locale => 'ko'],
            expect  =>
            {
                locale      => 'en',
                name_locale => 'ko',
                name_order  => 'surnameFirst',
                is_draft    => 0,
            },
        },
        # English locale: 'und' catch-all -> givenFirst
        {
            method  => 'person_name_order_locale',
            args    => [locale => 'en', name_locale => 'und'],
            expect  =>
            {
                locale      => 'en',
                name_locale => 'und',
                name_order  => 'givenFirst',
                is_draft    => 0,
            },
        },
        # Japanese locale treats Hungarian names as surnameFirst
        {
            method  => 'person_name_order_locale',
            args    => [locale => 'ja', name_locale => 'hu'],
            expect  =>
            {
                locale      => 'ja',
                name_locale => 'hu',
                name_order  => 'surnameFirst',
                is_draft    => 0,
            },
        },
        # Filter: all order-locale entries for Japanese
        {
            method  => 'person_name_order_locales',
            args    => [locale => 'ja'],
            expect  => 'array',
        },
        # Filter: all surnameFirst entries for English
        {
            method  => 'person_name_order_locales',
            args    => [locale => 'en', name_order => 'surnameFirst'],
            expect  => 'array',
        },
        # Unbounded scan - author only
        {
            method  => 'person_name_order_locales',
            args    => [],
            expect  => 'array',
        },
    ],

    # NOTE: person_name_samples
    # Source: main/ja.xml nativeFull and foreignGS
    #         main/en.xml nativeFull and foreignGS
    person_name_samples =>
    [
        # Japanese nativeFull given field
        {
            method  => 'person_name_sample',
            args    => [locale => 'ja', sample_type => 'nativeFull', field_type => 'given'],
            expect  =>
            {
                locale          => 'ja',
                sample_type     => 'nativeFull',
                field_type      => 'given',
                field_value     => '恵子',
            },
        },
        # Japanese nativeFull surname-core field
        {
            method  => 'person_name_sample',
            args    => [locale => 'ja', sample_type => 'nativeFull', field_type => 'surname-core'],
            expect  =>
            {
                locale          => 'ja',
                sample_type     => 'nativeFull',
                field_type      => 'surname-core',
                field_value     => '佐藤',
            },
        },
        # Japanese nativeFull: surname-prefix is explicitly absent (CLDR convention '∅∅∅')
        {
            method  => 'person_name_sample',
            args    => [locale => 'ja', sample_type => 'nativeFull', field_type => 'surname-prefix'],
            expect  =>
            {
                locale          => 'ja',
                sample_type     => 'nativeFull',
                field_type      => 'surname-prefix',
                field_value     => '∅∅∅',
            },
        },
        # Japanese foreignGS given field (katakana)
        {
            method  => 'person_name_sample',
            args    => [locale => 'ja', sample_type => 'foreignGS', field_type => 'given'],
            expect  =>
            {
                locale          => 'ja',
                sample_type     => 'foreignGS',
                field_type      => 'given',
                field_value     => 'アルベルト',
            },
        },
        # English nativeFull given field
        {
            method  => 'person_name_sample',
            args    => [locale => 'en', sample_type => 'nativeFull', field_type => 'given'],
            expect  =>
            {
                locale          => 'en',
                sample_type     => 'nativeFull',
                field_type      => 'given',
                field_value     => 'Bertram Wilberforce',
            },
        },
        # English foreignGS: a German name rendered in English
        {
            method  => 'person_name_sample',
            args    => [locale => 'en', sample_type => 'foreignGS', field_type => 'surname'],
            expect  =>
            {
                locale          => 'en',
                sample_type     => 'foreignGS',
                field_type      => 'surname',
                field_value     => 'Müller',
            },
        },
        # Filter: all samples for a Japanese nativeFull
        {
            method  => 'person_name_samples',
            args    => [locale => 'ja', sample_type => 'nativeFull'],
            expect  => 'array',
        },
        # Filter: all samples for Japanese locale
        {
            method  => 'person_name_samples',
            args    => [locale => 'ja'],
            expect  => 'array',
        },
        # Unbounded scan - author only
        {
            method  => 'person_name_samples',
            args    => [],
            expect  => 'array',
        },
    ],

    # NOTE: locales_info person name properties
    # Source: main/ja.xml nativeSpaceReplacement='', foreignSpaceReplacement='・'
    #         main/en.xml parameterDefault formality='informal', length='medium'
    person_name_locales_info =>
    [
        # Japanese native space replacement: empty string (no separator for native names)
        {
            method  => 'locales_info',
            args    => [locale => 'ja', property => 'person_name_native_space'],
            expect  =>
            {
                locale      => 'ja',
                property    => 'person_name_native_space',
                value       => '',
            },
        },
        # Japanese foreign space replacement: middle dot
        {
            method  => 'locales_info',
            args    => [locale => 'ja', property => 'person_name_foreign_space'],
            expect  =>
            {
                locale      => 'ja',
                property    => 'person_name_foreign_space',
                value       => '・',
            },
        },
        # English default formality
        {
            method  => 'locales_info',
            args    => [locale => 'en', property => 'person_name_default_formality'],
            expect  =>
            {
                locale      => 'en',
                property    => 'person_name_default_formality',
                value       => 'informal',
            },
        },
        # English default length
        {
            method  => 'locales_info',
            args    => [locale => 'en', property => 'person_name_default_length'],
            expect  =>
            {
                locale      => 'en',
                property    => 'person_name_default_length',
                value       => 'medium',
            },
        },
    ],
};

# NOTE: core tests
foreach my $test_name ( sort( keys( %$tests ) ) )
{
    subtest $test_name => sub
    {
        my $test_data = $tests->{ $test_name };
        foreach my $def ( @$test_data )
        {
            if( !$AUTHOR_TESTING && is_unbounded_array_scan( $def ) )
            {
                note( "Skipping unbounded $def->{method}() scan outside AUTHOR_TESTING" );
                next;
            }

            foreach my $param ( qw( method args expect ) )
            {
                if( !exists( $def->{ $param } ) )
                {
                    die( "Missing parameter \"${param}\" in test configuration for \"${test_name}\"." );
                }
            }

            SKIP:
            {
                can_ok( $cldr, $def->{method} );
                my $code = $cldr->can( $def->{method} );
                if( !$code )
                {
                    skip( "Unsupported method \"$def->{method}\" in Locale::Unicode::Data", 1 );
                }
                my $rv = $code->( $cldr, @{$def->{args}} );
                ok( ( defined( $rv ) || ( !defined( $rv ) && !$cldr->error ) ), "Calling $def->{method} with " . ( scalar( @{$def->{args}} ) ? "arguments '" . join( "', '", map( $_ // 'undef', @{$def->{args}} ) ) . "'" : 'no argument' ) );
                if( !defined( $rv ) && $cldr->error )
                {
                    diag( "Error occurred calling $def->{method}: ", $cldr->error );
                    skip( "Error with $def->{method}", 1 );
                }
                my $expect = $def->{expect};
                if( ref( $expect ) eq 'HASH' )
                {
                    is( ref( $rv ) => 'HASH', "$def->{method}() -> \$rv is an hash" );
                    if( ref( $rv ) ne 'HASH' )
                    {
                        skip( "Data returned by $def->{method} is not an hash reference.", 1 );
                    }
                    foreach my $prop ( sort( keys( %$expect ) ) )
                    {
                        ok( exists( $rv->{ $prop } ), "$def->{method}() -> \$rv->{ ${prop} } exists." );
                        if( !exists( $rv->{ $prop } ) )
                        {
                            next;
                        }
                        if( ref( $expect->{ $prop } ) )
                        {
                            is( ref( $rv->{ $prop } ) => ref( $expect->{ $prop } ), "Value for $def->{method}() -> \$rv->{ ${prop} } is an " . lc( ref( $expect->{ $prop } ) ) . " reference." );
                            if( ref( $rv->{ $prop } ) )
                            {
                                is_deeply( $rv->{ $prop }, $expect->{ $prop }, "Content for $def->{method}() -> \$rv->{ ${prop} } matches" );
                            }
                        }
                        else
                        {
                            is( $rv->{ $prop } => $expect->{ $prop }, "Value for $def->{method}() -> \$rv->{ ${prop} } matches" );
                        }
                    }
                }
                elsif( !ref( $expect ) )
                {
                    is( lc( ref( $rv ) // '' ) => $expect, "$def->{method} returned " . ( $expect // 'undef' ) );
                }
            };
        }
    };
}

# NOTE: person_name_derive_order
# Tests cover: explicit match, und fallback, CJK match, and the givenFirst default.
subtest 'person_name_derive_order' => sub
{
    # Japanese formatting locale: Korean names -> surnameFirst (explicit in ja nameOrderLocales)
    my $order = $cldr->person_name_derive_order(
        formatting_locale   => 'ja',
        name_locale         => 'ko',
    );
    is( $order => 'surnameFirst', 'ja formatting ko name -> surnameFirst' );

    # Japanese formatting locale: French names -> givenFirst (falls through to 'und')
    $order = $cldr->person_name_derive_order(
        formatting_locale   => 'ja',
        name_locale         => 'fr',
    );
    # 'und' in ja.xml is NOT present (ja only lists surnameFirst locales).
    # Root 'und' locale has 'und' -> givenFirst, but the method looks up the
    # formatting_locale's own nameOrderLocales table, not root. So fr does not
    # match any entry in ja and there is no 'und' entry either: default givenFirst.
    is( $order => 'givenFirst', 'ja formatting fr name -> givenFirst (default)' );

    # English formatting locale: Korean names -> surnameFirst (explicit in en nameOrderLocales)
    $order = $cldr->person_name_derive_order(
        formatting_locale   => 'en',
        name_locale         => 'ko',
    );
    is( $order => 'surnameFirst', 'en formatting ko name -> surnameFirst' );

    $order = $cldr->person_name_derive_order(
        formatting_locale => 'ja-JP',
        name_locale       => 'ko',
    );
    is( $order => 'surnameFirst', 'ja-JP formatting ko name -> surnameFirst via ja inheritance' );

    $order = $cldr->person_name_derive_order(
        formatting_locale => 'en-US',
        name_locale       => 'ko',
    );
    is( $order => 'surnameFirst', 'en-US formatting ko name -> surnameFirst via en inheritance' );

    # English formatting locale: French names -> givenFirst ('und' in en -> givenFirst)
    $order = $cldr->person_name_derive_order(
        formatting_locale   => 'en',
        name_locale         => 'fr',
    );
    is( $order => 'givenFirst', 'en formatting fr name -> givenFirst (via und)' );

    # English formatting locale: English names -> givenFirst (explicit 'en' in en nameOrderLocales)
    $order = $cldr->person_name_derive_order(
        formatting_locale   => 'en',
        name_locale         => 'en',
    );
    is( $order => 'givenFirst', 'en formatting en name -> givenFirst' );
};

# NOTE: person_name_space_replacement
# Tests cover: Japanese native (empty), Japanese foreign (middle dot),
# CJK equivalence (zh formatting yue name -> native), and the default SPACE fallback.
subtest 'person_name_space_replacement' => sub
{
    # Japanese formatting a Japanese name: native -> empty string
    my $sep = $cldr->person_name_space_replacement(
        formatting_locale   => 'ja',
        name_locale         => 'ja',
    );
    is( $sep => '', 'ja formatting ja -> native space replacement is empty string' );

    # Japanese formatting a German name: foreign -> '・'
    $sep = $cldr->person_name_space_replacement(
        formatting_locale   => 'ja',
        name_locale         => 'de',
    );
    is( $sep => '・', 'ja formatting de -> foreign space replacement is KATAKANA MIDDLE DOT' );

    # Japanese formatting a Chinese name: both in CJK group -> native -> empty string
    $sep = $cldr->person_name_space_replacement(
        formatting_locale   => 'ja',
        name_locale         => 'zh',
    );
    is( $sep => '', 'ja formatting zh -> native space replacement (CJK group match)' );

    # Japanese formatting a Cantonese name: both in CJK group -> native -> empty string
    $sep = $cldr->person_name_space_replacement(
        formatting_locale   => 'ja',
        name_locale         => 'yue',
    );
    is( $sep => '', 'ja formatting yue -> native space replacement (CJK group match)' );

    $sep = $cldr->person_name_space_replacement(
        formatting_locale => 'ja-JP',
        name_locale       => 'ja-JP',
    );
    is( $sep => '', 'ja-JP formatting ja-JP -> native space replacement inherited from ja' );

    $sep = $cldr->person_name_space_replacement(
        formatting_locale => 'ja-JP',
        name_locale       => 'de-DE',
    );
    is( $sep => '・', 'ja-JP formatting de-DE -> foreign space replacement inherited from ja' );

    # English formatting a French name: no explicit entry -> default SPACE
    $sep = $cldr->person_name_space_replacement(
        formatting_locale   => 'en',
        name_locale         => 'fr',
    );
    is( $sep => ' ', 'en formatting fr -> default SPACE (no locales_info entry)' );

    # English formatting an English name: same base language -> native; no entry -> default SPACE
    $sep = $cldr->person_name_space_replacement(
        formatting_locale   => 'en',
        name_locale         => 'en',
    );
    is( $sep => ' ', 'en formatting en -> native SPACE (default)' );

    # Chinese formatting a German name: foreign -> '·' (MIDDLE DOT, different from KATAKANA)
    $sep = $cldr->person_name_space_replacement(
        formatting_locale   => 'zh',
        name_locale         => 'de',
    );
    is( $sep => '·', 'zh formatting de -> foreign space replacement is MIDDLE DOT' );
};

done_testing();

__END__
