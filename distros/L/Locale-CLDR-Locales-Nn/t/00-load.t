#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Nn;
use ok Locale::CLDR::Locales::Nn::Any::No;
use ok Locale::CLDR::Locales::Nn::Any;

done_testing();
