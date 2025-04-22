#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib qw( ./lib );
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Locale::Intl' ) || BAIL_OUT( "Cannot load Locale::Intl" );
};

use strict;
use warnings;

my $loc = Locale::Intl->new( 'en' );
isa_ok( $loc, 'Locale::Intl' );

# To generate this list:
# perl -lnE '/^sub (?!new|[A-Z]|_)/ and say "can_ok( \$loc, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/Locale/Intl.pm
can_ok( $loc, 'baseName' );
can_ok( $loc, 'calendar' );
can_ok( $loc, 'caseFirst' );
can_ok( $loc, 'collation' );
can_ok( $loc, 'getAllCalendars' );
can_ok( $loc, 'getAllNumberingSystems' );
can_ok( $loc, 'getAllTimeZones' );
can_ok( $loc, 'getCalendars' );
can_ok( $loc, 'getCollations' );
can_ok( $loc, 'getHourCycles' );
can_ok( $loc, 'getNumberingSystems' );
can_ok( $loc, 'getTextInfo' );
can_ok( $loc, 'getTimeZones' );
can_ok( $loc, 'getWeekInfo' );
can_ok( $loc, 'hourCycle' );
can_ok( $loc, 'language' );
can_ok( $loc, 'maximise' );
can_ok( $loc, 'maximize' );
can_ok( $loc, 'minimise' );
can_ok( $loc, 'minimize' );
can_ok( $loc, 'numberingSystem' );
can_ok( $loc, 'numeric' );
can_ok( $loc, 'region' );
can_ok( $loc, 'script' );
can_ok( $loc, 'toString' );

subtest 'baseName' => sub
{
    my @tests = (
        {
            test => 'gsw-u-sd-chzh',
            expects => 'gsw',
        },
        {
            test => 'he-IL-u-ca-hebrew-tz-jeruslm',
            expects => 'he-IL',
        },
        {
            test => 'ja-t-it',
            expects => 'ja',
        },
        {
            test => 'ja-Kana-t-it',
            expects => 'ja-Kana',
        },
        {
            test => 'und-Latn-t-und-cyrl',
            expects => 'und-Latn',
        },
    );
    
    foreach my $def ( @tests )
    {
        my $l = Locale::Intl->new( $def->{test} );
        isa_ok( $l => 'Locale::Intl' );
        SKIP:
        {
            if( !defined( $l ) )
            {
                skip( "Failed instantiating object for test locale '$def->{test}': " . Locale::Intl->error, 1 );
            }
            is( $l->baseName, $def->{expects}, "baseName for '$def->{test}' -> '$def->{expects}'" );
        };
    }
};

subtest 'calendar' => sub
{
    my @tests = (
        {
            test => 'he-IL-u-ca-hebrew-tz-jeruslm',
            expects => 'hebrew',
        },
        {
            test => 'ja-u-ca-japanese',
            expects => 'japanese',
        },
    );
    
    foreach my $def ( @tests )
    {
        my $l = Locale::Intl->new( $def->{test} );
        isa_ok( $l => 'Locale::Intl' );
        SKIP:
        {
            if( !defined( $l ) )
            {
                skip( "Failed instantiating object for test locale '$def->{test}': " . Locale::Intl->error, 1 );
            }
            is( $l->calendar, $def->{expects}, "calendar for '$def->{test}' -> '$def->{expects}'" );
        };
    }
};

subtest 'caseFirst' => sub
{
    my @tests = (
        {
            test => 'fr-Latn-FR-u-kf-upper',
            expects => 'upper',
        },
        {
            test => 'en-Latn-US',
            opts => { caseFirst => 'lower' },
            expects => 'lower',
        },
        {
            test => 'ja-JP-u-co-standard-kf-lower',
            opts => { caseFirst => undef },
            expects => undef,
        },
    );
    
    foreach my $def ( @tests )
    {
        my $l = Locale::Intl->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        isa_ok( $l => 'Locale::Intl' );
        SKIP:
        {
            if( !defined( $l ) )
            {
                skip( "Failed instantiating object for test locale '$def->{test}': " . Locale::Intl->error, 1 );
            }
            diag( "Locale for '$def->{test}' stringifies to '$l'" ) if( $DEBUG );
            is( $l->caseFirst, $def->{expects}, "caseFirst for '$def->{test}' -> '" . ( $def->{expects} // 'undef' ) . "'" );
        };
    }
};

subtest 'getAllCalendars' => sub
{
    my $a = Locale::Intl->getAllCalendars;
    is( ref( $a ) => 'ARRAY', 'getAllCalendars() returns an array' );
    diag( "getAllCalendars() returns ", scalar( @$a ), " calendar(s)" ) if( $DEBUG );
    ok( scalar( @$a ) > 0, 'getAllCalendars() returns calendars data' );
};

subtest 'getAllNumberingSystems' => sub
{
    my $a = Locale::Intl->getAllNumberingSystems;
    is( ref( $a ) => 'ARRAY', 'getAllNumberingSystems() returns an array' );
    diag( "getAllNumberingSystems() returns ", scalar( @$a ), " numbering system(s)" ) if( $DEBUG );
    ok( scalar( @$a ) > 0, 'getAllNumberingSystems() returns numbering system data' );
};

subtest 'getAllTimeZones' => sub
{
    my $a = Locale::Intl->getAllTimeZones;
    is( ref( $a ) => 'ARRAY', 'getAllTimeZones() returns an array' );
    diag( "getAllTimeZones() returns ", scalar( @$a ), " time zone(s)" ) if( $DEBUG );
    ok( scalar( @$a ) > 0, 'getAllTimeZones() returns time zone data' );
};

subtest 'getCalendars' => sub
{
    my @tests =
    (
        {
            test => 'ja-JP',
            expects => [qw( gregorian japanese )],
        },
        {
            test => 'ja',
            expects => [qw( gregorian japanese )],
        },
        {
            test => 'he',
            expects => [qw( gregorian hebrew islamic islamic-civil islamic-tbla )],
        },
        {
            test => 'en',
            expects => [qw( gregorian )],
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test} );
        my $a = $loc->getCalendars;
        is( ref( $a ) => 'ARRAY', "[$def->{test}] -> getCalendars() returns an array" );
        SKIP:
        {
            if( !defined( $a ) )
            {
                skip( "Failed to get an array for '$def->{test}': " . $loc->error, 1 );
            }
            diag( "[$def->{test}] -> getCalendars() returns ", scalar( @$a ), " calendar(s)" ) if( $DEBUG );
            ok( scalar( @$a ) > 0, "[$def->{test}] -> getCalendars() returns calendar identifiers data" );
            is( "@$a", "@{$def->{expects}}", "[$def->{test}] -> getCalendars() contains: '" . join( "', '", @{$def->{expects}} ) . "'" );
        };
    }
};

subtest 'getCollations' => sub
{
    my @tests =
    (
        {
            test => 'ja',
            expects => [qw( private-kana standard unihan )],
        },
        {
            test => 'zh',
            expects => [qw( private-pinyin pinyin stroke zhuyin unihan )],
        },
        {
            test => 'en',
            expects => [qw( standard search eor private-unihan emoji )],
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test} );
        my $a = $loc->getCollations;
        is( ref( $a ) => 'ARRAY', "[$def->{test}] -> getCollations() returns an array" );
        SKIP:
        {
            if( !defined( $a ) )
            {
                skip( "Failed to get an array for '$def->{test}': " . $loc->error, 1 );
            }
            diag( "[$def->{test}] -> getCollations() returns ", scalar( @$a ), " collation(s)" ) if( $DEBUG );
            ok( scalar( @$a ) > 0, "[$def->{test}] -> getCollations() returns collation identifiers data" );
            is( "@$a", "@{$def->{expects}}", "[$def->{test}] -> getCollations() contains: '" . join( "', '", @{$def->{expects}} ) . "'" );
        };
    }
};

subtest 'getHourCycles' => sub
{
    my @tests =
    (
        {
            test => 'ja-JP',
            expects => [qw( h23 )],
        },
        {
            test => 'ar-EG',
            expects => [qw( h12 )],
        },
        {
            test => 'fr-FR-u-hc-h23',
            expects => [qw( h23 )],
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test} );
        my $a = $loc->getHourCycles;
        is( ref( $a ) => 'ARRAY', "[$def->{test}] -> getHourCycles() returns an array" );
        SKIP:
        {
            if( !defined( $a ) )
            {
                skip( "Failed to get an array for '$def->{test}': " . $loc->error, 1 );
            }
            diag( "[$def->{test}] -> getHourCycles() returns ", scalar( @$a ), " hour cycle(s)" ) if( $DEBUG );
            ok( scalar( @$a ) > 0, "[$def->{test}] -> getHourCycles() returns hour cycles data" );
            is( "@$a", "@{$def->{expects}}", "[$def->{test}] -> getHourCycles() contains: '" . join( "', '", @{$def->{expects}} ) . "'" );
        };
    }
};

subtest 'getNumberingSystems' => sub
{
    my @tests =
    (
        {
            test => 'ja',
            expects => [qw( latn )],
        },
        {
            test => 'ar-EG',
            expects => [qw( arab )],
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test} );
        my $a = $loc->getNumberingSystems;
        is( ref( $a ) => 'ARRAY', "[$def->{test}] -> getNumberingSystems() returns an array" );
        SKIP:
        {
            if( !defined( $a ) )
            {
                skip( "Failed to get an array for '$def->{test}': " . $loc->error, 1 );
            }
            diag( "[$def->{test}] -> getNumberingSystems() returns ", scalar( @$a ), " numbering system(s)" ) if( $DEBUG );
            ok( scalar( @$a ) > 0, "[$def->{test}] -> getNumberingSystems() returns numbering systems data" );
            is( "@$a", "@{$def->{expects}}", "[$def->{test}] -> getNumberingSystems() contains: '" . join( "', '", @{$def->{expects}} ) . "'" );
        };
    }
};

subtest 'getTextInfo' => sub
{
    my @tests =
    (
        {
            test => 'ja',
            expects => 'ltr',
        },
        {
            test => 'ar',
            expects => 'rtl',
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test} );
        my $layout = $loc->getTextInfo;
        ok( defined( $layout ), "[$def->{test}] -> getTextInfo() returns a string" );
        SKIP:
        {
            if( !defined( $layout ) )
            {
                skip( "Failed to get a scalar object object for '$def->{test}': " . $loc->error, 1 );
            }
            diag( "[$def->{test}] -> getTextInfo() returns '", ( $layout // 'undef' ), "'" ) if( $DEBUG );
            is( $layout, $def->{expects}, "[$def->{test}] -> getTextInfo() returned: '" . ( $layout // 'undef' ) . "'" );
        };
    }
};

subtest 'getTimeZones' => sub
{
    my @tests =
    (
        {
            test => 'ja-JP',
            expects => [qw( Asia/Tokyo)],
        },
        {
            test => 'ar-EG',
            expects => [qw( Africa/Cairo )],
        },
        {
            test => 'ar',
            expects => [qw( Africa/Cairo )],
        },
        {
            test => 'de-DE',
            expects => [qw( Europe/Berlin Europe/Busingen )],
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test} );
        my $a = $loc->getTimeZones;
        is( ref( $a ) => 'ARRAY', "[$def->{test}] -> getTimeZones() returns an array" );
        SKIP:
        {
            if( !defined( $a ) )
            {
                skip( "Failed to get an array for '$def->{test}': " . $loc->error, 1 );
            }
            diag( "[$def->{test}] -> getTimeZones() returns ", scalar( @$a ), " time zone(s)" ) if( $DEBUG );
            ok( scalar( @$a ) > 0, "[$def->{test}] -> getTimeZones() returns time zone data" );
            is( "@$a", "@{$def->{expects}}", "[$def->{test}] -> getTimeZones() contains: '" . join( "', '", @{$def->{expects}} ) . "'" );
        };
    }
};

subtest 'getWeekInfo' => sub
{
    my @tests =
    (
        {
            test => 'he',
            expects => { firstDay => 7, weekend => [5, 6], minimalDays => 1 },
        },
        {
            test => 'af',
            expects => { firstDay => 7, weekend => [6, 7], minimalDays => 1 },
        },
        {
            test => 'en-GB',
            expects => { firstDay => 1, weekend => [6, 7], minimalDays => 4 },
        },
        {
            test => 'ms-BN',
            expects => { firstDay => 1, weekend => [6, 7], minimalDays => 1 },
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test} );
        my $ref = $loc->getWeekInfo;
        is( ref( $ref ) => 'HASH', "[$def->{test}] -> getWeekInfo() returns an hash reference" );
        SKIP:
        {
            if( !defined( $ref ) )
            {
                skip( "Failed to get an hash reference for '$def->{test}': " . $loc->error, 1 );
            }
            is_deeply( $ref, $def->{expects}, "[$def->{test}] -> getWeekInfo()" );
        };
    }
};

subtest 'hourCycle' => sub
{
    my @tests =
    (
        {
            test => 'fr-FR-u-hc-h23',
            expects => 'h23',
        },
        {
            test => 'en-US',
            expects => 'h12',
            opts => { hourCycle => 'h12' },
        },
        {
            test => 'ja',
            expects => undef,
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        my $hc = $loc->hourCycle;
        SKIP:
        {
            diag( "[$def->{test}] -> hourCycle returns '", ( $hc // 'undef' ), "'" ) if( $DEBUG );
            is( $hc, $def->{expects}, "[$def->{test}] -> hourCycle returned: '" . ( $hc // 'undef' ) . "'" );
            if( !defined( $hc ) )
            {
                skip( "No hour cycle set for '"  . ( $def->{test} // 'undef' ) . "'", 1 );
            }
            ok( defined( $hc ), "[$def->{test}] -> hourCycle returns a string" );
        };
    }
};

subtest 'language' => sub
{
    my @tests =
    (
        {
            test => 'en-Latn-US',
            expects => 'en',
        },
        {
            test => 'en-Latn-US',
            expects => 'es',
            opts => { language => 'es' },
        },
        # Weird, but just to test
        {
            test => 'ja-Kana',
            expects => undef,
            opts => { language => undef },
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        my $lang = $loc->language;
        SKIP:
        {
            diag( "[$def->{test}] -> language returns '", ( $lang // 'undef' ), "'" ) if( $DEBUG );
            is( $lang, $def->{expects}, "[$def->{test}] -> language returned: '" . ( $lang // 'undef' ) . "'" );
            if( !defined( $lang ) )
            {
                skip( "No language set for '"  . ( $def->{test} // 'undef' ) . "'", 1 );
            }
            ok( defined( $lang ), "[$def->{test}] -> language returns a string" );
        };
    }
};

subtest 'maximize' => sub
{
    my @tests =
    (
        {
            test => 'en',
            expects => 'en-Latn-US',
        },
        {
            test => 'ja',
            expects => 'ja-Jpan-JP',
        },
        {
            test => 'ko',
            expects => 'ko-Kore-KR',
        },
        {
            test => 'ar',
            expects => 'ar-Arab-EG',
        },
        {
            test => 'fr',
            expects => 'fr-Latn-FR-u-ca-gregory-hc-h12',
            opts => { hourCycle => 'h12', calendar => 'gregory' },
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        my $full = $loc->maximize;
        isa_ok( $full => 'Locale::Intl', "[$def->{test}] -> maximize() returns an Locale::Intl object" );
        SKIP:
        {
            if( !defined( $full ) )
            {
                skip( "Failed to get an Locale::Intl object for '$def->{test}': " . ( $loc->error // 'undef' ), 1 );
            }
            diag( "[$def->{test}] -> maximize returns '", ( $full // 'undef' ), "'" ) if( $DEBUG );
            is( $full, $def->{expects}, "[$def->{test}] -> maximize returned: '" . ( $full // 'undef' ) . "'" );
        };
    }
};

subtest 'minimize' => sub
{
    my @tests =
    (
        {
            test => 'en-Latn-US',
            expects => 'en',
        },
        {
            test => 'ja-Jpan-JP',
            expects => 'ja',
        },
        {
            test => 'ko-Kore-KR',
            expects => 'ko',
        },
        {
            test => 'ar-Arab-EG',
            expects => 'ar',
        },
        {
            test => 'fr-Latn-FR',
            expects => 'fr-u-ca-gregory-hc-h12',
            opts => { hourCycle => 'h12', calendar => 'gregory' },
        },
        {
            test => 'und-Latn',
            expects => 'en',
        },
        {
            test => 'zh-Hant-FR',
            expects => 'zh-Hant-FR',
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        my $full = $loc->minimize;
        isa_ok( $full => 'Locale::Intl', "[$def->{test}] -> minimize() returns an Locale::Intl object" );
        SKIP:
        {
            if( !defined( $full ) )
            {
                skip( "Failed to get an Locale::Intl object for '$def->{test}': " . ( $loc->error // 'undef' ), 1 );
            }
            diag( "[$def->{test}] -> minimize returns '", ( $full // 'undef' ), "'" ) if( $DEBUG );
            is( $full, $def->{expects}, "[$def->{test}] -> minimize returned: '" . ( $full // 'undef' ) . "'" );
        };
    }
};

subtest 'numberingSystem' => sub
{
    my @tests =
    (
        {
            test => 'fr-Latn-FR-u-nu-mong',
            expects => 'mong',
        },
        {
            test => 'ja',
            expects => undef,
        },
        {
            test => 'en-Latn-US',
            expects => 'latn',
            opts => { numberingSystem => "latn" },
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        my $num = $loc->numberingSystem;
        SKIP:
        {
            diag( "[$def->{test}] -> numberingSystem returns '", ( $num // 'undef' ), "'" ) if( $DEBUG );
            is( $num, $def->{expects}, "[$def->{test}] -> numberingSystem returned: '" . ( $num // 'undef' ) . "'" );
            if( !defined( $num ) )
            {
                skip( "No numbering system set for '"  . ( $def->{test} // 'undef' ) . "'", 1 );
            }
            ok( defined( $num ), "[$def->{test}] -> numberingSystem returns a string" );
        };
    }
};

subtest 'numeric' => sub
{
    my @tests =
    (
        {
            test => 'fr-Latn-FR-u-kn-false',
            expects => 0,
        },
        {
            test => 'ja',
            expects => undef,
        },
        {
            test => 'en-Latn-US',
            expects => 1,
            opts => { numeric => 1 },
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        my $bool = $loc->numeric;
        SKIP:
        {
            diag( "[$def->{test}] -> numeric returns '", ( $bool // 'undef' ), "'" ) if( $DEBUG );
            is( $bool, $def->{expects}, "[$def->{test}] -> numeric returned: '" . ( $bool // 'undef' ) . "'" );
            if( !defined( $bool ) )
            {
                skip( "No numeric boolean set for '"  . ( $def->{test} // 'undef' ) . "'", 1 );
            }
            isa_ok( $bool => 'Locale::Intl::Boolean', "[$def->{test}] -> numeric returns a boolean object" );
        };
    }
};

subtest 'region' => sub
{
    my @tests =
    (
        {
            test => 'en-Latn-US',
            expects => 'US',
        },
        {
            test => 'fr-Latn-150',
            expects => '150',
        },
        {
            test => 'en-US',
            expects => 'GB',
            opts => { region => "GB" },
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        my $rg = $loc->region;
        SKIP:
        {
            diag( "[$def->{test}] -> region returns '", ( $rg // 'undef' ), "'" ) if( $DEBUG );
            is( $rg, $def->{expects}, "[$def->{test}] -> region returned: '" . ( $rg // 'undef' ) . "'" );
            if( !defined( $rg ) )
            {
                skip( "No region set for '"  . ( $def->{test} // 'undef' ) . "'", 1 );
            }
            ok( defined( $rg ), "[$def->{test}] -> region returns a string" );
        };
    }
};

subtest 'toString' => sub
{
    my @tests =
    (
        {
            test => 'fr-Latn-FR',
            expects => 'fr-Latn-FR-u-ca-gregory-hc-h12',
            opts => { calendar => 'gregory', hourCycle => 'h12' },
        },
        {
            test => 'ko-Kore-KR',
            expects => 'ko-Kore-KR-u-kf-upper-kn',
            opts => { numeric => 'true', caseFirst => 'upper' },
        },
        {
            test => 'en-US',
            expects => 'en-GB',
            opts => { region => "GB" },
        },
    );
    local $" = ' ';
    foreach my $def ( @tests )
    {
        my $loc = Locale::Intl->new( $def->{test}, ( exists( $def->{opts} ) ? ( %{$def->{opts}} ) : () ) );
        my $str = $loc->toString;
        diag( "[$def->{test}] -> toString returns '", ( $str // 'undef' ), "'" ) if( $DEBUG );
        is( $str, $def->{expects}, "[$def->{test}] -> toString returned: '" . ( $str // 'undef' ) . "'" );
    }
};

done_testing();

__END__

