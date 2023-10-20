#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Sw;
use ok Locale::CLDR::Locales::Sw::Any::Cd;
use ok Locale::CLDR::Locales::Sw::Any::Ke;
use ok Locale::CLDR::Locales::Sw::Any::Tz;
use ok Locale::CLDR::Locales::Sw::Any::Ug;
use ok Locale::CLDR::Locales::Sw::Any;

done_testing();
