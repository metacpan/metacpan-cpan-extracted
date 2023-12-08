#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Mua;
use ok Locale::CLDR::Locales::Mua::Any::Cm;
use ok Locale::CLDR::Locales::Mua::Any;

done_testing();
