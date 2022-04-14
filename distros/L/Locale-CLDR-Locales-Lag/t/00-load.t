#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Lag, 'Can use locale file Locale::CLDR::Locales::Lag';
use ok Locale::CLDR::Locales::Lag::Any::Tz, 'Can use locale file Locale::CLDR::Locales::Lag::Any::Tz';
use ok Locale::CLDR::Locales::Lag::Any, 'Can use locale file Locale::CLDR::Locales::Lag::Any';

done_testing();
