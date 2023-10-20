#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Tr;
use ok Locale::CLDR::Locales::Tr::Any::Cy;
use ok Locale::CLDR::Locales::Tr::Any::Tr;
use ok Locale::CLDR::Locales::Tr::Any;

done_testing();
