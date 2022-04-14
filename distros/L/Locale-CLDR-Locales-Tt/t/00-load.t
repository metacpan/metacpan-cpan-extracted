#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Tt, 'Can use locale file Locale::CLDR::Locales::Tt';
use ok Locale::CLDR::Locales::Tt::Any::Ru, 'Can use locale file Locale::CLDR::Locales::Tt::Any::Ru';
use ok Locale::CLDR::Locales::Tt::Any, 'Can use locale file Locale::CLDR::Locales::Tt::Any';

done_testing();
