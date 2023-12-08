#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ga;
use ok Locale::CLDR::Locales::Ga::Any::Ie;
use ok Locale::CLDR::Locales::Ga::Any;

done_testing();
