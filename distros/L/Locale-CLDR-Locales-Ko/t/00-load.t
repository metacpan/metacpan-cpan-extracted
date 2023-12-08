#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ko;
use ok Locale::CLDR::Locales::Ko::Any::Kp;
use ok Locale::CLDR::Locales::Ko::Any::Kr;
use ok Locale::CLDR::Locales::Ko::Any;

done_testing();
