#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG $TEST_ID );
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
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    $TEST_ID = $ENV{TEST_ID} if( exists( $ENV{TEST_ID} ) );
};

BEGIN
{
    use_ok( 'Locale::Unicode::Data' ) || BAIL_OUT( 'Unable to load Locale::Unicode::Data' );
};

use strict;
use warnings;
use utf8;

my $cldr = Locale::Unicode::Data->new;
isa_ok( $cldr, 'Locale::Unicode::Data' );

# See CLDR data in supplemental/plurals.xml
my $tests = 
[
    # 1: other - Representative locale: 'bm'
    { locale => 'bm', value => 0, expect => 'other' },
    { locale => 'bm', value => 1, expect => 'other' },
    { locale => 'bm', value => 2, expect => 'other' },
    { locale => 'bm', value => 15, expect => 'other' },
    { locale => 'bm', value => 100, expect => 'other' },
    { locale => 'bm', value => 1000, expect => 'other' },
    { locale => 'bm', value => 0.5, expect => 'other' },
    { locale => 'bm', value => 1.5, expect => 'other' },

    # 2: one,other - Representative locale: 'am'
    { locale => 'am', value => 0, expect => 'one' },
    { locale => 'am', value => 1, expect => 'one' },
    { locale => 'am', value => 2, expect => 'other' },
    { locale => 'am', value => 10, expect => 'other' },
    { locale => 'am', value => 0.5, expect => 'other' },
    { locale => 'am', value => 1.5, expect => 'other' },

    # 2: one,other - Representative locale: 'ast' (for integer-only 'one')
    { locale => 'ast', value => 1, expect => 'one' },
    { locale => 'ast', value => 2, expect => 'other' },
    { locale => 'ast', value => 1.1, expect => 'other' },
    { locale => 'ast', value => 0, expect => 'other' },

    # 2: one,other - Representative locale: 'si' (with decimal conditions)
    { locale => 'si', value => 0, expect => 'one' },
    { locale => 'si', value => 1, expect => 'one' },
    { locale => 'si', value => 0.1, expect => 'one' },
    { locale => 'si', value => 2, expect => 'other' },
    { locale => 'si', value => 0.2, expect => 'one' },
    { locale => 'si', value => 1.0, expect => 'one' },
    { locale => 'sl', value => 1.5, expect => 'few' },
    { locale => 'si', value => 1.0, expect => 'one' },

    # 2: one,other - Representative locale: 'tzm' (for specific range conditions)
    { locale => 'tzm', value => 0, expect => 'one' },
    { locale => 'tzm', value => 1, expect => 'one' },
    { locale => 'tzm', value => 11, expect => 'one' },
    { locale => 'tzm', value => 99, expect => 'one' },
    { locale => 'tzm', value => 10, expect => 'other' },
    { locale => 'tzm', value => 100, expect => 'other' },

    # 2: one,other - Representative locale: 'da' (with decimal and integer conditions)
    { locale => 'da', value => 1, expect => 'one' },
    { locale => 'da', value => 0.1, expect => 'one' },
    { locale => 'da', value => 2, expect => 'other' },
    { locale => 'da', value => 0.0, expect => 'other' },

    # 2: one,other - Representative locale: 'is' (with complex integer conditions)
    { locale => 'is', value => 1, expect => 'one' },
    { locale => 'is', value => 21, expect => 'one' },
    { locale => 'is', value => 11, expect => 'other' },
    { locale => 'is', value => 2, expect => 'other' },
    { locale => 'is', value => 0.1, expect => 'one' },
    { locale => 'is', value => 1.1, expect => 'other' },

    # 2: one,other - Representative locale: 'mk' (similar to 'is')
    { locale => 'mk', value => 1, expect => 'one' },
    { locale => 'mk', value => 21, expect => 'one' },
    { locale => 'mk', value => 11, expect => 'other' },
    { locale => 'mk', value => 2, expect => 'other' },
    { locale => 'mk', value => 0.1, expect => 'one' },
    { locale => 'mk', value => 1.1, expect => 'other' },

    # 2: one,other - Representative locale: 'ceb' (complex condition with lists)
    { locale => 'ceb', value => 1, expect => 'one' },
    { locale => 'ceb', value => 2, expect => 'one' },
    { locale => 'ceb', value => 3, expect => 'one' },
    { locale => 'ceb', value => 4, expect => 'other' },
    { locale => 'ceb', value => 5, expect => 'one' },
    { locale => 'ceb', value => 6, expect => 'other' },
    { locale => 'ceb', value => 7, expect => 'one' },
    { locale => 'ceb', value => 8, expect => 'one' },
    { locale => 'ceb', value => 9, expect => 'other' },
    { locale => 'ceb', value => 0.4, expect => 'other' },
    { locale => 'ceb', value => 0.5, expect => 'one' },

    # 3: zero,one,other - Representative locale: 'lv'
    { locale => 'lv', value => 0, expect => 'zero' },
    { locale => 'lv', value => 1, expect => 'one' },
    { locale => 'lv', value => 10, expect => 'zero' },
    { locale => 'lv', value => 11, expect => 'zero' },
    { locale => 'lv', value => 21, expect => 'one' },
    { locale => 'lv', value => 0.1, expect => 'one' },
    { locale => 'lv', value => 0.2, expect => 'one' },
    { locale => 'lv', value => 0.0, expect => 'zero' },
    { locale => 'lv', value => 0.01, expect => 'zero' },
    { locale => 'lv', value => 0.001, expect => 'zero' },

    # 3: zero,one,other - Representative locale: 'lag'
    { locale => 'lag', value => 0, expect => 'zero' },
    { locale => 'lag', value => 1, expect => 'one' },
    { locale => 'lag', value => 0.5, expect => 'one' },
    { locale => 'lag', value => 2, expect => 'other' },

    # 3: zero,one,other - Representative locale: 'blo'
    { locale => 'blo', value => 0, expect => 'zero' },
    { locale => 'blo', value => 1, expect => 'one' },
    { locale => 'blo', value => 2, expect => 'other' },

    # 3: one,two,other - Representative locale: 'he'
    { locale => 'he', value => 1, expect => 'one' },
    { locale => 'he', value => 0.5, expect => 'one' },
    { locale => 'he', value => 2, expect => 'two' },
    { locale => 'he', value => 3, expect => 'other' },
    { locale => 'he', value => 1.5, expect => 'one' },

    # 3: one,two,other - Representative locale: 'iu'
    { locale => 'iu', value => 1, expect => 'one' },
    { locale => 'iu', value => 2, expect => 'two' },
    { locale => 'iu', value => 3, expect => 'other' },

    # 3: one,few,other - Representative locale: 'shi'
    { locale => 'shi', value => 0, expect => 'one' },
    { locale => 'shi', value => 1, expect => 'one' },
    { locale => 'shi', value => 2, expect => 'few' },
    { locale => 'shi', value => 10, expect => 'few' },
    { locale => 'shi', value => 11, expect => 'other' },

    # 3: one,few,other - Representative locale: 'ro' (aliased to 'mo')
    { locale => 'ro', value => 1, expect => 'one' },
    { locale => 'ro', value => 0, expect => 'few' },
    { locale => 'ro', value => 2, expect => 'few' },
    { locale => 'ro', value => 1.5, expect => 'few' },
    { locale => 'ro', value => 20, expect => 'other' },
    { locale => 'ro', value => 1.1, expect => 'few' },

    # 3: one,few,other - Representative locale: 'bs' (with more complex rules)
    { locale => 'bs', value => 1, expect => 'one' },
    { locale => 'bs', value => 21, expect => 'one' },
    { locale => 'bs', value => 11, expect => 'other' },
    { locale => 'bs', value => 2, expect => 'few' },
    { locale => 'bs', value => 3, expect => 'few' },
    { locale => 'bs', value => 4, expect => 'few' },
    { locale => 'bs', value => 5, expect => 'other' },
    { locale => 'bs', value => 0.1, expect => 'one' },
    { locale => 'bs', value => 1.1, expect => 'other' },
    { locale => 'bs', value => 0.2, expect => 'few' },
    { locale => 'bs', value => 1.5, expect => 'other' },

    # 3: one,many,other - Representative locale: 'fr'
    { locale => 'fr', value => 0, expect => 'one' },
    { locale => 'fr', value => 1, expect => 'one' },
    { locale => 'fr', value => 2, expect => 'other' },
    { locale => 'fr', value => 1000000, expect => 'many' },
    { locale => 'fr', value => 1.5, expect => 'other' },
    { locale => 'fr', value => 1000000.5, expect => 'many' },
    { locale => 'fr', value => 1.499999, expect => 'many' },

    # 4: one,two,few,other - Representative locale: 'gd'
    { locale => 'gd', value => 1, expect => 'one' },
    { locale => 'gd', value => 11, expect => 'one' },
    { locale => 'gd', value => 2, expect => 'two' },
    { locale => 'gd', value => 12, expect => 'two' },
    { locale => 'gd', value => 3, expect => 'few' },
    { locale => 'gd', value => 10, expect => 'few' },
    { locale => 'gd', value => 13, expect => 'few' },
    { locale => 'gd', value => 19, expect => 'few' },
    { locale => 'gd', value => 20, expect => 'other' },

    # 4: one,two,few,other - Representative locale: 'sl'
    { locale => 'sl', value => 1, expect => 'one' },
    { locale => 'sl', value => 101, expect => 'one' },
    { locale => 'sl', value => 2, expect => 'two' },
    { locale => 'sl', value => 102, expect => 'two' },
    { locale => 'sl', value => 3, expect => 'few' },
    { locale => 'sl', value => 4, expect => 'few' },
    { locale => 'sl', value => 103, expect => 'few' },
    { locale => 'sl', value => 5, expect => 'other' },
    { locale => 'sl', value => 0.5, expect => 'few' },

    # 4: one,two,few,other - Representative locale: 'dsb'
    { locale => 'dsb', value => 1, expect => 'one' },
    { locale => 'dsb', value => 101, expect => 'one' },
    { locale => 'dsb', value => 2, expect => 'two' },
    { locale => 'dsb', value => 102, expect => 'two' },
    { locale => 'dsb', value => 3, expect => 'few' },
    { locale => 'dsb', value => 4, expect => 'few' },
    { locale => 'dsb', value => 103, expect => 'few' },
    { locale => 'dsb', value => 5, expect => 'other' },
    { locale => 'dsb', value => 0.1, expect => 'one' },

    # 4: one,few,many,other - Representative locale: 'cs'
    { locale => 'cs', value => 1, expect => 'one' },
    { locale => 'cs', value => 2, expect => 'few' },
    { locale => 'cs', value => 3, expect => 'few' },
    { locale => 'cs', value => 4, expect => 'few' },
    { locale => 'cs', value => 5, expect => 'other' },
    { locale => 'cs', value => 0.5, expect => 'many' },

    # 4: one,few,many,other - Representative locale: 'pl'
    { locale => 'pl', value => 1, expect => 'one' },
    { locale => 'pl', value => 2, expect => 'few' },
    { locale => 'pl', value => 3, expect => 'few' },
    { locale => 'pl', value => 4, expect => 'few' },
    { locale => 'pl', value => 5, expect => 'many' },
    { locale => 'pl', value => 11, expect => 'many' },
    { locale => 'pl', value => 12, expect => 'many' },
    { locale => 'pl', value => 14, expect => 'many' },
    { locale => 'pl', value => 15, expect => 'many' },
    { locale => 'pl', value => 0.5, expect => 'many' },
    { locale => 'pl', value => 1.5, expect => 'many' },

    # 4: one,few,many,other - Representative locale: 'be'
    { locale => 'be', value => 1, expect => 'one' },
    { locale => 'be', value => 21, expect => 'one' },
    { locale => 'be', value => 2, expect => 'few' },
    { locale => 'be', value => 3, expect => 'few' },
    { locale => 'be', value => 4, expect => 'few' },
    { locale => 'be', value => 5, expect => 'many' },
    { locale => 'be', value => 11, expect => 'many' },
    { locale => 'be', value => 0.5, expect => 'other' },

    # 4: one,few,many,other - Representative locale: 'lt'
    { locale => 'lt', value => 1, expect => 'one' },
    { locale => 'lt', value => 21, expect => 'one' },
    { locale => 'lt', value => 2, expect => 'few' },
    { locale => 'lt', value => 9, expect => 'few' },
    { locale => 'lt', value => 11, expect => 'other' },
    { locale => 'lt', value => 0, expect => 'other' },
    { locale => 'lt', value => 0.5, expect => 'many' },

    # 4: one,few,many,other - Representative locale: 'ru'
    { locale => 'ru', value => 1, expect => 'one' },
    { locale => 'ru', value => 21, expect => 'one' },
    { locale => 'ru', value => 2, expect => 'few' },
    { locale => 'ru', value => 3, expect => 'few' },
    { locale => 'ru', value => 4, expect => 'few' },
    { locale => 'ru', value => 5, expect => 'many' },
    { locale => 'ru', value => 11, expect => 'many' },
    { locale => 'ru', value => 0.5, expect => 'other' },

    # 5: one,two,few,many,other - Representative locale: 'br'
    { locale => 'br', value => 1, expect => 'one' },
    { locale => 'br', value => 21, expect => 'one' },
    { locale => 'br', value => 2, expect => 'two' },
    { locale => 'br', value => 22, expect => 'two' },
    { locale => 'br', value => 3, expect => 'few' },
    { locale => 'br', value => 4, expect => 'few' },
    { locale => 'br', value => 9, expect => 'few' },
    { locale => 'br', value => 1000000, expect => 'many' },
    { locale => 'br', value => 5, expect => 'other' },
    { locale => 'br', value => 0.5, expect => 'other' },
    { locale => 'br', value => 71, expect => 'other' },
    { locale => 'br', value => 1.5, expect => 'other' },

    # 5: one,two,few,many,other - Representative locale: 'mt'
    { locale => 'mt', value => 1, expect => 'one' },
    { locale => 'mt', value => 2, expect => 'two' },
    { locale => 'mt', value => 0, expect => 'few' },
    { locale => 'mt', value => 3, expect => 'few' },
    { locale => 'mt', value => 10, expect => 'few' },
    { locale => 'mt', value => 11, expect => 'many' },
    { locale => 'mt', value => 19, expect => 'many' },
    { locale => 'mt', value => 20, expect => 'other' },
    { locale => 'mt', value => 0.5, expect => 'other' },

    # 5: one,two,few,many,other - Representative locale: 'ga'
    { locale => 'ga', value => 1, expect => 'one' },
    { locale => 'ga', value => 2, expect => 'two' },
    { locale => 'ga', value => 3, expect => 'few' },
    { locale => 'ga', value => 6, expect => 'few' },
    { locale => 'ga', value => 7, expect => 'many' },
    { locale => 'ga', value => 10, expect => 'many' },
    { locale => 'ga', value => 11, expect => 'other' },
    { locale => 'ga', value => 0.5, expect => 'other' },

    # 5: one,two,few,many,other - Representative locale: 'gv'
    { locale => 'gv', value => 1, expect => 'one' },
    { locale => 'gv', value => 11, expect => 'one' },
    { locale => 'gv', value => 2, expect => 'two' },
    { locale => 'gv', value => 12, expect => 'two' },
    { locale => 'gv', value => 0, expect => 'few' },
    { locale => 'gv', value => 20, expect => 'few' },
    { locale => 'gv', value => 40, expect => 'few' },
    { locale => 'gv', value => 3, expect => 'other' },
    { locale => 'gv', value => 0.5, expect => 'many' },

    # 6: zero,one,two,few,many,other - Representative locale: 'kw'
    { locale => 'kw', value => 0, expect => 'zero' },
    { locale => 'kw', value => 1, expect => 'one' },
    { locale => 'kw', value => 2, expect => 'two' },
    { locale => 'kw', value => 3, expect => 'few' },
    { locale => 'kw', value => 21, expect => 'many' },
    { locale => 'kw', value => 83, expect => 'few' },
    { locale => 'kw', value => 100000, expect => 'two' },
    { locale => 'kw', value => 4, expect => 'other' },
    { locale => 'kw', value => 0.5, expect => 'other' },

    # 6: zero,one,two,few,many,other - Representative locale: 'ar'
    { locale => 'ar', value => 0, expect => 'zero' },
    { locale => 'ar', value => 1, expect => 'one' },
    { locale => 'ar', value => 2, expect => 'two' },
    { locale => 'ar', value => 3, expect => 'few' },
    { locale => 'ar', value => 10, expect => 'few' },
    { locale => 'ar', value => 11, expect => 'many' },
    { locale => 'ar', value => 99, expect => 'many' },
    { locale => 'ar', value => 100, expect => 'other' },
    { locale => 'ar', value => 0.5, expect => 'other' },
    { locale => 'ar', value => 1.5, expect => 'other' },

    # 6: zero,one,two,few,many,other - Representative locale: 'cy'
    { locale => 'cy', value => 0, expect => 'zero' },
    { locale => 'cy', value => 1, expect => 'one' },
    { locale => 'cy', value => 2, expect => 'two' },
    { locale => 'cy', value => 3, expect => 'few' },
    { locale => 'cy', value => 6, expect => 'many' },
    { locale => 'cy', value => 7, expect => 'other' },
    { locale => 'cy', value => 0.5, expect => 'other' },
    { locale => 'cy', value => 4, expect => 'other' },
    { locale => 'cy', value => 5, expect => 'other' },
];

my $failed = [];
for( my $i = 0; $i < scalar( @$tests ); $i++ )
{
    if( defined( $TEST_ID ) )
    {
        next unless( $i == $TEST_ID );
        last if( $i > $TEST_ID );
    }
    my $test = $tests->[$i];
    local $SIG{__DIE__} = sub
    {
        diag( "Test No ${i} died: ", join( '', @_ ) );
    };
    my $rv = $cldr->plural_count( @$test{qw( value locale )} );
    SKIP:
    {
        if( !defined( $rv ) )
        {
            diag( "Error testing locale $test->{locale} with value $test->{value}: ", $cldr->error ) if( $DEBUG );
            skip( "Error testing locale $test->{locale} with value $test->{value}: " . $cldr->error, 1 );
        }
        if( !is( $rv => $test->{expect}, "$test->{locale}: $test->{value} -> $test->{expect}" ) )
        {
            push( @$failed, { %$test, test => $i, got => $rv } );
        }
    };
}


done_testing();

__END__

