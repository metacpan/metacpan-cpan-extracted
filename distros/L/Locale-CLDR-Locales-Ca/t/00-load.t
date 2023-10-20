#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ca;
use ok Locale::CLDR::Locales::Ca::Any::Ad;
use ok Locale::CLDR::Locales::Ca::Any::Es::Valencia;
use ok Locale::CLDR::Locales::Ca::Any::Es;
use ok Locale::CLDR::Locales::Ca::Any::Fr;
use ok Locale::CLDR::Locales::Ca::Any::It;
use ok Locale::CLDR::Locales::Ca::Any;

done_testing();
