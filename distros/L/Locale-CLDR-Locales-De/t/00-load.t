#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::De;
use ok Locale::CLDR::Locales::De::Any::At;
use ok Locale::CLDR::Locales::De::Any::Be;
use ok Locale::CLDR::Locales::De::Any::Ch;
use ok Locale::CLDR::Locales::De::Any::De;
use ok Locale::CLDR::Locales::De::Any::It;
use ok Locale::CLDR::Locales::De::Any::Li;
use ok Locale::CLDR::Locales::De::Any::Lu;
use ok Locale::CLDR::Locales::De::Any;

done_testing();
