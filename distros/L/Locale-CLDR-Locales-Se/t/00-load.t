#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Se, 'Can use locale file Locale::CLDR::Locales::Se';
use ok Locale::CLDR::Locales::Se::Any::Fi, 'Can use locale file Locale::CLDR::Locales::Se::Any::Fi';
use ok Locale::CLDR::Locales::Se::Any::No, 'Can use locale file Locale::CLDR::Locales::Se::Any::No';
use ok Locale::CLDR::Locales::Se::Any::Se, 'Can use locale file Locale::CLDR::Locales::Se::Any::Se';
use ok Locale::CLDR::Locales::Se::Any, 'Can use locale file Locale::CLDR::Locales::Se::Any';

done_testing();
