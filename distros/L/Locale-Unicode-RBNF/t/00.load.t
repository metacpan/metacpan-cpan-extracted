#!perl
##----------------------------------------------------------------------------
## Unicode CLDR Rule-Based Number Format - t/00.load.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'Locale::Unicode::RBNF' ) or BAIL_OUT( 'Cannot load Locale::Unicode::RBNF' );
    use_ok( 'Locale::Unicode::RBNF::CLDR' );
    use_ok( 'Locale::Unicode::RBNF::DecimalFormat' );
    use_ok( 'Locale::Unicode::RBNF::PluralFormat' );
    use_ok( 'Locale::Unicode::RBNF::PluralRules' );
    use_ok( 'Locale::Unicode::RBNF::PP' );
    use_ok( 'Locale::Unicode::RBNF::Rule' );
    use_ok( 'Locale::Unicode::RBNF::RuleSet' );
    use_ok( 'Locale::Unicode::RBNF::Substitution' );
    use_ok( 'Locale::Unicode::RBNF::Util' );
}

diag( "Testing Locale::Unicode::RBNF $Locale::Unicode::RBNF::VERSION, Perl $], $^X" );
diag( "XS loaded: " . ( $Locale::Unicode::RBNF::IsPurePerl ? "no (pure-Perl fallback)" : "yes" ) );

done_testing;

__END__
