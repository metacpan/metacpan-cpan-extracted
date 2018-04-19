#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Asa, 'Can use locale file Locale::CLDR::Locales::Asa';
use ok Locale::CLDR::Locales::Asa::Any::Tz, 'Can use locale file Locale::CLDR::Locales::Asa::Any::Tz';
use ok Locale::CLDR::Locales::Asa::Any, 'Can use locale file Locale::CLDR::Locales::Asa::Any';

done_testing();
