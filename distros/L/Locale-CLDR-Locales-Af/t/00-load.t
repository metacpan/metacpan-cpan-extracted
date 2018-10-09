#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Af, 'Can use locale file Locale::CLDR::Locales::Af';
use ok Locale::CLDR::Locales::Af::Any::Na, 'Can use locale file Locale::CLDR::Locales::Af::Any::Na';
use ok Locale::CLDR::Locales::Af::Any::Za, 'Can use locale file Locale::CLDR::Locales::Af::Any::Za';
use ok Locale::CLDR::Locales::Af::Any, 'Can use locale file Locale::CLDR::Locales::Af::Any';

done_testing();
