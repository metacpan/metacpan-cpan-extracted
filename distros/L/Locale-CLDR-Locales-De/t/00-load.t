#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::De';
use ok 'Locale::CLDR::Locales::De::Latn::At';
use ok 'Locale::CLDR::Locales::De::Latn::Be';
use ok 'Locale::CLDR::Locales::De::Latn::Ch';
use ok 'Locale::CLDR::Locales::De::Latn::De';
use ok 'Locale::CLDR::Locales::De::Latn::It';
use ok 'Locale::CLDR::Locales::De::Latn::Li';
use ok 'Locale::CLDR::Locales::De::Latn::Lu';
use ok 'Locale::CLDR::Locales::De::Latn';

done_testing();
