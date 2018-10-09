#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ka, 'Can use locale file Locale::CLDR::Locales::Ka';
use ok Locale::CLDR::Locales::Ka::Any::Ge, 'Can use locale file Locale::CLDR::Locales::Ka::Any::Ge';
use ok Locale::CLDR::Locales::Ka::Any, 'Can use locale file Locale::CLDR::Locales::Ka::Any';

done_testing();
