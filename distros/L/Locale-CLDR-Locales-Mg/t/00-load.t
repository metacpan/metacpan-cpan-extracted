#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Mg;
use ok Locale::CLDR::Locales::Mg::Any::Mg;
use ok Locale::CLDR::Locales::Mg::Any;

done_testing();
