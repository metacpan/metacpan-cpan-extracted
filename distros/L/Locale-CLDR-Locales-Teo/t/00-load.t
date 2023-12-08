#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Teo;
use ok Locale::CLDR::Locales::Teo::Any::Ke;
use ok Locale::CLDR::Locales::Teo::Any::Ug;
use ok Locale::CLDR::Locales::Teo::Any;

done_testing();
