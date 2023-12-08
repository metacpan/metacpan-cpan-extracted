#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::So;
use ok Locale::CLDR::Locales::So::Any::Dj;
use ok Locale::CLDR::Locales::So::Any::Et;
use ok Locale::CLDR::Locales::So::Any::Ke;
use ok Locale::CLDR::Locales::So::Any::So;
use ok Locale::CLDR::Locales::So::Any;

done_testing();
