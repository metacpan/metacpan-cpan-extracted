#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Eu, 'Can use locale file Locale::CLDR::Locales::Eu';
use ok Locale::CLDR::Locales::Eu::Any::Es, 'Can use locale file Locale::CLDR::Locales::Eu::Any::Es';
use ok Locale::CLDR::Locales::Eu::Any, 'Can use locale file Locale::CLDR::Locales::Eu::Any';

done_testing();
