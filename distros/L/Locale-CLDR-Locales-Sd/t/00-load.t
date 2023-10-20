#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Sd;
use ok Locale::CLDR::Locales::Sd::Any::Pk;
use ok Locale::CLDR::Locales::Sd::Any;

done_testing();
