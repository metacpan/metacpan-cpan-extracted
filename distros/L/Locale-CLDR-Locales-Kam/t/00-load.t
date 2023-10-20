#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Kam;
use ok Locale::CLDR::Locales::Kam::Any::Ke;
use ok Locale::CLDR::Locales::Kam::Any;

done_testing();
