#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ro;
use ok Locale::CLDR::Locales::Ro::Any::Md;
use ok Locale::CLDR::Locales::Ro::Any::Ro;
use ok Locale::CLDR::Locales::Ro::Any;

done_testing();
