#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Hi;
use ok Locale::CLDR::Locales::Hi::Any::In;
use ok Locale::CLDR::Locales::Hi::Any;

done_testing();
