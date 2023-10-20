#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ug;
use ok Locale::CLDR::Locales::Ug::Any::Cn;
use ok Locale::CLDR::Locales::Ug::Any;

done_testing();
