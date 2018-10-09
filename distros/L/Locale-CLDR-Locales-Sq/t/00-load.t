#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Sq, 'Can use locale file Locale::CLDR::Locales::Sq';
use ok Locale::CLDR::Locales::Sq::Any::Al, 'Can use locale file Locale::CLDR::Locales::Sq::Any::Al';
use ok Locale::CLDR::Locales::Sq::Any::Mk, 'Can use locale file Locale::CLDR::Locales::Sq::Any::Mk';
use ok Locale::CLDR::Locales::Sq::Any::Xk, 'Can use locale file Locale::CLDR::Locales::Sq::Any::Xk';
use ok Locale::CLDR::Locales::Sq::Any, 'Can use locale file Locale::CLDR::Locales::Sq::Any';

done_testing();
