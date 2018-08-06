#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Sah, 'Can use locale file Locale::CLDR::Locales::Sah';
use ok Locale::CLDR::Locales::Sah::Any::Ru, 'Can use locale file Locale::CLDR::Locales::Sah::Any::Ru';
use ok Locale::CLDR::Locales::Sah::Any, 'Can use locale file Locale::CLDR::Locales::Sah::Any';

done_testing();
