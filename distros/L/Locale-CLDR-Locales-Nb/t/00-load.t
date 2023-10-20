#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Nb;
use ok Locale::CLDR::Locales::Nb::Any::No;
use ok Locale::CLDR::Locales::Nb::Any::Sj;
use ok Locale::CLDR::Locales::Nb::Any;

done_testing();
