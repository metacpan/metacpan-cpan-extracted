#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Is;
use ok Locale::CLDR::Locales::Is::Any::Is;
use ok Locale::CLDR::Locales::Is::Any;

done_testing();
