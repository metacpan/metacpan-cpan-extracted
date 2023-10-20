#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Asa;
use ok Locale::CLDR::Locales::Asa::Any::Tz;
use ok Locale::CLDR::Locales::Asa::Any;

done_testing();
