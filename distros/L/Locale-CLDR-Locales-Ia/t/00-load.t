#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ia, 'Can use locale file Locale::CLDR::Locales::Ia';
use ok Locale::CLDR::Locales::Ia::Any::001, 'Can use locale file Locale::CLDR::Locales::Ia::Any::001';
use ok Locale::CLDR::Locales::Ia::Any, 'Can use locale file Locale::CLDR::Locales::Ia::Any';

done_testing();
