#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Om;
use ok Locale::CLDR::Locales::Om::Any::Et;
use ok Locale::CLDR::Locales::Om::Any::Ke;
use ok Locale::CLDR::Locales::Om::Any;

done_testing();
