#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Fa;
use ok Locale::CLDR::Locales::Fa::Any::Af;
use ok Locale::CLDR::Locales::Fa::Any::Ir;
use ok Locale::CLDR::Locales::Fa::Any;

done_testing();
