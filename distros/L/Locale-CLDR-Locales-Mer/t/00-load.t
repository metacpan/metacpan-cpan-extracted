#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Mer;
use ok Locale::CLDR::Locales::Mer::Any::Ke;
use ok Locale::CLDR::Locales::Mer::Any;

done_testing();
