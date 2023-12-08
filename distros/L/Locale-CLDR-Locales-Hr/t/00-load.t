#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Hr;
use ok Locale::CLDR::Locales::Hr::Any::Ba;
use ok Locale::CLDR::Locales::Hr::Any::Hr;
use ok Locale::CLDR::Locales::Hr::Any;

done_testing();
