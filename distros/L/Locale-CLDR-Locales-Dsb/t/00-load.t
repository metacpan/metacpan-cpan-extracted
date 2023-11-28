#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Dsb;
use ok Locale::CLDR::Locales::Dsb::Any::De;
use ok Locale::CLDR::Locales::Dsb::Any;

done_testing();
