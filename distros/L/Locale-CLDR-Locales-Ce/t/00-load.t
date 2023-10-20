#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ce;
use ok Locale::CLDR::Locales::Ce::Any::Ru;
use ok Locale::CLDR::Locales::Ce::Any;

done_testing();
