#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ky, 'Can use locale file Locale::CLDR::Locales::Ky';
use ok Locale::CLDR::Locales::Ky::Any::Kg, 'Can use locale file Locale::CLDR::Locales::Ky::Any::Kg';
use ok Locale::CLDR::Locales::Ky::Any, 'Can use locale file Locale::CLDR::Locales::Ky::Any';

done_testing();
