#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Bg, 'Can use locale file Locale::CLDR::Locales::Bg';
use ok Locale::CLDR::Locales::Bg::Any::Bg, 'Can use locale file Locale::CLDR::Locales::Bg::Any::Bg';
use ok Locale::CLDR::Locales::Bg::Any, 'Can use locale file Locale::CLDR::Locales::Bg::Any';

done_testing();
