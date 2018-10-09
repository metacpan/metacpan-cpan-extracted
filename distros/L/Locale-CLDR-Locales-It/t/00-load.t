#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::It, 'Can use locale file Locale::CLDR::Locales::It';
use ok Locale::CLDR::Locales::It::Any::Ch, 'Can use locale file Locale::CLDR::Locales::It::Any::Ch';
use ok Locale::CLDR::Locales::It::Any::It, 'Can use locale file Locale::CLDR::Locales::It::Any::It';
use ok Locale::CLDR::Locales::It::Any::Sm, 'Can use locale file Locale::CLDR::Locales::It::Any::Sm';
use ok Locale::CLDR::Locales::It::Any::Va, 'Can use locale file Locale::CLDR::Locales::It::Any::Va';
use ok Locale::CLDR::Locales::It::Any, 'Can use locale file Locale::CLDR::Locales::It::Any';

done_testing();
