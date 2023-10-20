#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Be;
use ok Locale::CLDR::Locales::Be::Any::By;
use ok Locale::CLDR::Locales::Be::Any;

done_testing();
