#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ti, 'Can use locale file Locale::CLDR::Locales::Ti';
use ok Locale::CLDR::Locales::Ti::Any::Er, 'Can use locale file Locale::CLDR::Locales::Ti::Any::Er';
use ok Locale::CLDR::Locales::Ti::Any::Et, 'Can use locale file Locale::CLDR::Locales::Ti::Any::Et';
use ok Locale::CLDR::Locales::Ti::Any, 'Can use locale file Locale::CLDR::Locales::Ti::Any';

done_testing();
