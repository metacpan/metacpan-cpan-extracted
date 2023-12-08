#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Bo;
use ok Locale::CLDR::Locales::Bo::Any::Cn;
use ok Locale::CLDR::Locales::Bo::Any::In;
use ok Locale::CLDR::Locales::Bo::Any;

done_testing();
