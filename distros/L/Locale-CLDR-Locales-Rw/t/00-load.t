#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Rw;
use ok Locale::CLDR::Locales::Rw::Any::Rw;
use ok Locale::CLDR::Locales::Rw::Any;

done_testing();
