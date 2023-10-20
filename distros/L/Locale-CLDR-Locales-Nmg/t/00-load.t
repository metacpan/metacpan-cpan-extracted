#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Nmg;
use ok Locale::CLDR::Locales::Nmg::Any::Cm;
use ok Locale::CLDR::Locales::Nmg::Any;

done_testing();
