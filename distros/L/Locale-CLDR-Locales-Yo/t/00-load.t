#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Yo;
use ok Locale::CLDR::Locales::Yo::Any::Bj;
use ok Locale::CLDR::Locales::Yo::Any::Ng;
use ok Locale::CLDR::Locales::Yo::Any;

done_testing();
