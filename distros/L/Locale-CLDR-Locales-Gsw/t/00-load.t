#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Gsw, 'Can use locale file Locale::CLDR::Locales::Gsw';
use ok Locale::CLDR::Locales::Gsw::Any::Ch, 'Can use locale file Locale::CLDR::Locales::Gsw::Any::Ch';
use ok Locale::CLDR::Locales::Gsw::Any::Fr, 'Can use locale file Locale::CLDR::Locales::Gsw::Any::Fr';
use ok Locale::CLDR::Locales::Gsw::Any::Li, 'Can use locale file Locale::CLDR::Locales::Gsw::Any::Li';
use ok Locale::CLDR::Locales::Gsw::Any, 'Can use locale file Locale::CLDR::Locales::Gsw::Any';

done_testing();
