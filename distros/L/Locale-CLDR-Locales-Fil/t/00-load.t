#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Fil, 'Can use locale file Locale::CLDR::Locales::Fil';
use ok Locale::CLDR::Locales::Fil::Any::Ph, 'Can use locale file Locale::CLDR::Locales::Fil::Any::Ph';
use ok Locale::CLDR::Locales::Fil::Any, 'Can use locale file Locale::CLDR::Locales::Fil::Any';

done_testing();
