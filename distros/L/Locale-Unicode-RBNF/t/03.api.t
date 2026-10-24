#!perl
##----------------------------------------------------------------------------
## Unicode CLDR Rule-Based Number Format - t/03.api.t
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
use utf8;

BEGIN
{
    use_ok( 'Locale::Unicode::RBNF' ) || BAIL_OUT( 'Unable to load Locale::Unicode::RBNF' );
};

# The errors these tests expect are also reported as warnings by Locale::Unicode::RBNF, which are
# not shown. The warnings category is only registered once the module is loaded at run time, so
# "no warnings" cannot be used here.
$SIG{__WARN__} = sub
{
    warn( @_ ) unless( $_[0] =~ / at \S*Locale\/Unicode\/RBNF\.pm line \d+/ );
};
my $cldr = File::Spec->catdir( 't', 'cldr' );

# NOTE: errors
subtest 'errors' => sub
{
    my $fmt = Locale::Unicode::RBNF->new( locale => 'fr', type => 'nonsense', cldr => $cldr );
    ok( !defined( $fmt ), 'unknown type' );
    like( Locale::Unicode::RBNF->error, qr/unknown rule type/, 'error message' );
    $fmt = Locale::Unicode::RBNF->new( locale => 'fr', cldr => File::Spec->catdir( 't', 'nowhere' ) );
    ok( !defined( $fmt ), 'missing CLDR directory' );
    $fmt = Locale::Unicode::RBNF->new( rules => '%main: 0: zero; 1: =%missing=;' );
    ok( !defined( $fmt ), 'reference to an unknown rule set' );
    like( Locale::Unicode::RBNF->error, qr/no rule set named '%missing'/, 'error message' );
    $fmt = Locale::Unicode::RBNF->new( rules => '%main: 10: ten; 5: five;' );
    ok( !defined( $fmt ), 'rules out of order' );
    $fmt = Locale::Unicode::RBNF->new( locale => 'fr', cldr => $cldr );
    ok( !defined( $fmt->format( 1, '%%et-un' ) ), 'private rule set cannot be used' );
    like( $fmt->error, qr/internal rule set/, 'error message' );
    ok( !defined( $fmt->format( 'abc' ) ), 'not a number' );
    ok( !defined( $fmt->format( 1, '%nope' ) ), 'unknown rule set' );
};

# NOTE: exceptions
subtest 'exceptions' => sub
{
    my $fmt = Locale::Unicode::RBNF->new( locale => 'fr', type => 'nonsense', cldr => $cldr );
    my $err = Locale::Unicode::RBNF->error;
    isa_ok( $err, 'Locale::Unicode::RBNF::Exception', 'error object' );
    like( $err->message, qr/^U_ILLEGAL_ARGUMENT_ERROR: unknown rule type/, 'message' );
    my $r = Locale::Unicode::RBNF->rule_sets_from_description( '' );
    ok( !defined( $r ), 'error as a class method' );
    like( Locale::Unicode::RBNF->error->message, qr/empty rule description/, 'class method error message' );
    my $nf = Locale::Unicode::RBNF->new( locale => 'fr', cldr => $cldr );
    my $chain = eval{ $nf->format( 'abc' )->length };
    ok( !$@ && !defined( $chain ), 'a failed call in object context returns a null object' );
    $fmt = Locale::Unicode::RBNF->new( locale => 'fr', cldr => $cldr, fatal => 1 );
    ok( $fmt->fatal, 'fatal option' );
    eval { $fmt->format( 'abc' ) };
    isa_ok( $@, 'Locale::Unicode::RBNF::Exception', 'fatal error dies with an exception' );
    {
        no warnings 'once';
        local $Locale::Unicode::RBNF::FATAL_EXCEPTIONS = 1;
        eval { Locale::Unicode::RBNF->rule_sets_from_description( '' ) };
        isa_ok( $@, 'Locale::Unicode::RBNF::Exception', 'fatal class method error' );
        local $Locale::Unicode::RBNF::FATAL_EXCEPTIONS = 0;
        ok( !Locale::Unicode::RBNF->fatal, 'fatal as a class method returns the global default' );
        Locale::Unicode::RBNF->fatal(1);
        is( $Locale::Unicode::RBNF::FATAL_EXCEPTIONS, 1, 'fatal as a class method sets the global default' );
        ok( Locale::Unicode::RBNF->new( locale => 'fr', cldr => $cldr )->fatal, 'new objects inherit it' );
    }
    my $e = Locale::Unicode::RBNF::Exception->new( 'some ', 'message' );
    is( $e->message, 'some message', 'message from several arguments' );
    $e = Locale::Unicode::RBNF::Exception->new( 'single message' );
    is( $e->message, 'single message', 'message from a single argument' );
    my $p = $e->PROPAGATE( 'some_file', 42 );
    is( $p->line, 42, 'propagated line' );
    is( $e->line == 42 ? 1 : 0, 0, 'original exception unchanged' );
};

# NOTE: locales
subtest 'locales' => sub
{
    foreach my $def ( [ 'fr_CH', 'fr-CH', 'fr-CH' ], [ 'fr-ch', 'fr-CH', 'fr-CH' ], [ 'FR-CH', 'fr-CH', 'fr-CH' ], [ 'en-US-POSIX', 'en-US-posix', 'en' ], [ 'root', 'root', 'root' ], [ undef, 'root', 'root' ] )
    {
        my( $in, $locale, $valid ) = @$def;
        my $fmt = Locale::Unicode::RBNF->new( locale => $in, cldr => $cldr );
        ok( $fmt, 'locale ' . ( $in // 'undef' ) ) || do{ diag( Locale::Unicode::RBNF->error ); next; };
        isa_ok( $fmt->locale, 'Locale::Unicode' );
        is( $fmt->locale, $locale, 'locale ' . ( $in // 'undef' ) . ' becomes ' . $locale );
        is( $fmt->valid_locale, $valid, 'valid locale ' . $valid );
    }
    my $fmt = Locale::Unicode::RBNF->new( locale => 'fr-CH', cldr => $cldr );
    is( $fmt->format( 71 ), 'septante-et-un', 'BCP 47 locale finds the CLDR file fr_CH' );
    require Locale::Unicode;
    $fmt = Locale::Unicode::RBNF->new( locale => Locale::Unicode->new( 'fr-CH' ), cldr => $cldr );
    is( $fmt->locale, 'fr-CH', 'Locale::Unicode object accepted' );
    $fmt = Locale::Unicode::RBNF->new( locale => 'ja-JP-u-nu-hanidec', cldr => $cldr, rules => '%main: 0: =#,##0=;' );
    is( $fmt->locale, 'ja-JP-u-nu-hanidec', 'extension kept in the locale' );
    is( $fmt->numbering_system, 'hanidec', 'numbering system from the extension' );
    is( ( Locale::Unicode::RBNF::CLDR->canonical_locale( 'zh-yue-HK' ) )[0], 'yue_HK', 'extended language subtag used as the language' );
    is( ( Locale::Unicode::RBNF::CLDR->canonical_locale( 'en-US-POSIX' ) )[0], 'en_US_POSIX', 'variant in upper case, as in CLDR file names' );
    ok( !defined( Locale::Unicode::RBNF->new( locale => 'x-private', cldr => $cldr ) ), 'locale without language refused' );
    like( Locale::Unicode::RBNF->error->message, qr/no language subtag/, 'error message' );
    ok( !defined( Locale::Unicode::RBNF->new( locale => 'fr_CH@currency=EUR', cldr => $cldr ) ), 'ICU keyword syntax refused' );
    like( Locale::Unicode::RBNF->error->message, qr/^U_ILLEGAL_ARGUMENT_ERROR: invalid locale/, 'error message' );
};

# NOTE: rule sets
subtest 'rule sets' => sub
{
    my $fmt = Locale::Unicode::RBNF->new( locale => 'en', cldr => $cldr );
    my $names = $fmt->rule_set_names;
    ok( scalar( grep( $_ eq '%spellout-ordinal', @$names ) ), 'public rule set listed' );
    ok( !scalar( grep( /^%%/, @$names ) ), 'no private rule set listed' );
    is( $fmt->default_rule_set, '%spellout-numbering', 'default rule set' );
    ok( $fmt->default_rule_set( '%spellout-ordinal' ), 'change default rule set' );
    is( $fmt->format( 3 ), 'third', 'format with new default' );
    ok( $fmt->default_rule_set( '' ), 'restore default rule set' );
    is( $fmt->format( 3 ), 'three', 'format with original default' );
    ok( !$fmt->default_rule_set( '%%private' ), 'private default rule set refused' );
    like( $fmt->rules, qr/^%spellout-numbering-year:\n/m, 'rules description' );
    my $copy = Locale::Unicode::RBNF->new( locale => 'en', rules => $fmt->rules );
    ok( $copy, 'rules description compiles' ) || diag( Locale::Unicode::RBNF->error );
    is( $copy->format( 1234567, '%spellout-numbering' ), $fmt->format( 1234567, '%spellout-numbering' ), 'rules description is equivalent' );
};

# NOTE: number paths
subtest 'number paths' => sub
{
    my $fmt = Locale::Unicode::RBNF->new( locale => 'en', cldr => $cldr );
    is( $fmt->format( '9223372036854775807' ), '9,223,372,036,854,775,807', 'int64 maximum, through the =#,##0= rule' );
    is( $fmt->format( '-9223372036854775808' ), '-9,223,372,036,854,775,808', 'int64 minimum uses the decimal format' );
    is( $fmt->format( '123456789012345678901234567890' ), '123,456,789,012,345,678,901,234,567,890', 'beyond int64 uses the decimal format' );
    is( $fmt->format( 9**9**9 ), 'infinity', 'infinity' );
    is( $fmt->format( -9**9**9 ), 'minus infinity', 'negative infinity' );
    is( $fmt->format( 9**9**9 - 9**9**9 ), 'not a number', 'NaN' );
    is( $fmt->format( 2.0 ), 'two', 'integral number takes the integer path' );
    is( $fmt->format_double( 2.0 ), 'two', 'integral number with the double path' );
};

# NOTE: rounding
subtest 'rounding' => sub
{
    my $fmt = Locale::Unicode::RBNF->new( locale => 'en', cldr => $cldr, rounding_mode => 'half_even', max_fraction_digits => 2 );
    is( $fmt->format( 2.345 ), 'two point three four', 'half even' );
    $fmt->rounding_mode( 'half_up' );
    is( $fmt->format( 2.345 ), 'two point three five', 'half up' );
    $fmt->rounding_mode( 'floor' );
    is( $fmt->format( -2.341 ), 'minus two point three five', 'floor' );
    $fmt->rounding_mode( 'unnecessary' );
    is( $fmt->format( 2.345 ), 'two point three four five', 'no rounding' );
    ok( !$fmt->rounding_mode( 'sideways' ), 'unknown rounding mode' );
};

# NOTE: capitalization
subtest 'capitalization' => sub
{
    my $fmt = Locale::Unicode::RBNF->new( locale => 'fr', cldr => $cldr, capitalization => 'beginning_of_sentence' );
    is( $fmt->format( 21 ), 'Vingt-et-un', 'beginning of sentence' );
    $fmt->capitalization( 'middle_of_sentence' );
    is( $fmt->format( 21 ), 'vingt-et-un', 'middle of sentence' );
    $fmt->capitalization( 'none' );
    is( $fmt->format( 21 ), 'vingt-et-un', 'none' );
    ok( !$fmt->capitalization( 'shouting' ), 'unknown context' );
};

# NOTE: localizations
subtest 'localizations' => sub
{
    my $fmt = Locale::Unicode::RBNF->new(
        locale          => 'en',
        rules           => '%main: 0: zero; 1: one; 2: two; %alt: 0: nil; 1: =%main=;',
        localizations   => '<<%alt, %main>, <en, Alternative, Main>, <fr_CA, Autre, Principal>>',
    );
    ok( $fmt, 'object with localizations' ) || diag( Locale::Unicode::RBNF->error );
    is( $fmt->default_rule_set, '%alt', 'first localised rule set is the default' );
    is( $fmt->format( 0 ), 'nil', 'format with the localised default' );
    is_deeply( $fmt->rule_set_names, [ '%alt', '%main' ], 'rule set names from the localizations' );
    is_deeply( $fmt->rule_set_display_name_locales, [ 'en', 'fr_CA' ], 'display name locales' );
    is( $fmt->rule_set_display_name( '%main', 'en_GB' ), 'Main', 'fallback to en' );
    is( $fmt->rule_set_display_name( 0, 'fr_CA' ), 'Autre', 'by index' );
    is( $fmt->rule_set_display_name( '%main', 'ja' ), '%main', 'no localisation falls back on the name' );
    my $bad = Locale::Unicode::RBNF->new( rules => '%main: 0: zero;', localizations => '<<%main>, <en, Main, Extra>>' );
    ok( !defined( $bad ), 'each locale needs one name per rule set' );
};

# NOTE: symbols
subtest 'symbols' => sub
{
    my $fmt = Locale::Unicode::RBNF->new( locale => 'en', cldr => $cldr, rules => '%main: -x: minus >>; x.x: << dot >>; 0: =#,##0=;' );
    is( $fmt->format( 1234567 ), '1,234,567', 'locale grouping' );
    ok( $fmt->symbols({ group => "\x{2009}" }), 'change symbols' );
    is( $fmt->format( 1234567 ), "1\x{2009}234\x{2009}567", 'new grouping separator' );
    my $fr = Locale::Unicode::RBNF->new( locale => 'fr', cldr => $cldr, rules => '%main: 0: =#,##0.00=;' );
    is( $fr->format_double( 1234.5 ), "1\x{202F}234,50", 'French symbols' );
    my $ja = Locale::Unicode::RBNF->new( locale => 'ja-u-nu-hanidec', cldr => $cldr, rules => '%main: 0: =#,##0=;' );
    is( $ja->numbering_system, 'hanidec', 'numbering system from the locale extension' );
    is( $ja->format( 2026 ), "\x{4E8C},\x{3007}\x{4E8C}\x{516D}", 'numbering system digits' );
};

# NOTE: legacy CLDR format
subtest 'legacy CLDR format' => sub
{
    my $fmt = Locale::Unicode::RBNF->new( locale => 'xx', cldr => File::Spec->catdir( 't', 'legacy' ) );
    ok( $fmt, 'legacy rules load' ) || diag( Locale::Unicode::RBNF->error );
    is( $fmt->format( 23 ), 'twenty-three', 'arrows' );
    is( $fmt->format( 1200 ), 'twelve hundred', 'radix attribute' );
    is( $fmt->format( 2300 ), 'two thousand three hundred', 'rule after the radix rule' );
    is( $fmt->format( -3 ), 'minus three', 'negative rule' );
    is( scalar( $fmt->parse( 'twelve hundred three' ) ), 1203, 'parse' );
    is_deeply( $fmt->rule_set_names, [ '%spellout-numbering' ], 'private rule set' );
};

# NOTE: parse positions
subtest 'parse positions' => sub
{
    my $fmt = Locale::Unicode::RBNF->new( locale => 'en', cldr => $cldr );
    my( $v, $i, $e ) = $fmt->parse( 'xx twenty-one yy', 3 );
    is( $v, 21, 'value from a start index' );
    is( $i, 13, 'index' );
    is( $e, -1, 'no error' );
    ( $v, $i, $e ) = $fmt->parse( 'nothing here' );
    ok( !defined( $v ), 'nothing parsed' );
    is( $i, 0, 'index unchanged' );
    is( scalar( $fmt->parse( 'blah' ) ), undef, 'scalar context' );
};

done_testing();

__END__
