#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Bn;
use ok Locale::CLDR::Locales::Bn::Any::Bd;
use ok Locale::CLDR::Locales::Bn::Any::In;
use ok Locale::CLDR::Locales::Bn::Any;

done_testing();
