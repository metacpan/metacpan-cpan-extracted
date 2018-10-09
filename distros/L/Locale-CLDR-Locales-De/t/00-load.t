#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::De, 'Can use locale file Locale::CLDR::Locales::De';
use ok Locale::CLDR::Locales::De::Any::At, 'Can use locale file Locale::CLDR::Locales::De::Any::At';
use ok Locale::CLDR::Locales::De::Any::Be, 'Can use locale file Locale::CLDR::Locales::De::Any::Be';
use ok Locale::CLDR::Locales::De::Any::Ch, 'Can use locale file Locale::CLDR::Locales::De::Any::Ch';
use ok Locale::CLDR::Locales::De::Any::De, 'Can use locale file Locale::CLDR::Locales::De::Any::De';
use ok Locale::CLDR::Locales::De::Any::It, 'Can use locale file Locale::CLDR::Locales::De::Any::It';
use ok Locale::CLDR::Locales::De::Any::Li, 'Can use locale file Locale::CLDR::Locales::De::Any::Li';
use ok Locale::CLDR::Locales::De::Any::Lu, 'Can use locale file Locale::CLDR::Locales::De::Any::Lu';
use ok Locale::CLDR::Locales::De::Any, 'Can use locale file Locale::CLDR::Locales::De::Any';

done_testing();
