#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Nnh, 'Can use locale file Locale::CLDR::Locales::Nnh';
use ok Locale::CLDR::Locales::Nnh::Any::Cm, 'Can use locale file Locale::CLDR::Locales::Nnh::Any::Cm';
use ok Locale::CLDR::Locales::Nnh::Any, 'Can use locale file Locale::CLDR::Locales::Nnh::Any';

done_testing();
