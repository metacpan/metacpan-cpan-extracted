#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ca, 'Can use locale file Locale::CLDR::Locales::Ca';
use ok Locale::CLDR::Locales::Ca::Any::Ad, 'Can use locale file Locale::CLDR::Locales::Ca::Any::Ad';
use ok Locale::CLDR::Locales::Ca::Any::Es::Valencia, 'Can use locale file Locale::CLDR::Locales::Ca::Any::Es::Valencia';
use ok Locale::CLDR::Locales::Ca::Any::Es, 'Can use locale file Locale::CLDR::Locales::Ca::Any::Es';
use ok Locale::CLDR::Locales::Ca::Any::Fr, 'Can use locale file Locale::CLDR::Locales::Ca::Any::Fr';
use ok Locale::CLDR::Locales::Ca::Any::It, 'Can use locale file Locale::CLDR::Locales::Ca::Any::It';
use ok Locale::CLDR::Locales::Ca::Any, 'Can use locale file Locale::CLDR::Locales::Ca::Any';

done_testing();
