#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Km;
use ok Locale::CLDR::Locales::Km::Any::Kh;
use ok Locale::CLDR::Locales::Km::Any;

done_testing();
