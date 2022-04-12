#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Kk, 'Can use locale file Locale::CLDR::Locales::Kk';
use ok Locale::CLDR::Locales::Kk::Any::Kz, 'Can use locale file Locale::CLDR::Locales::Kk::Any::Kz';
use ok Locale::CLDR::Locales::Kk::Any, 'Can use locale file Locale::CLDR::Locales::Kk::Any';

done_testing();
