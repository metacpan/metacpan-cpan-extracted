#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Lkt;
use ok Locale::CLDR::Locales::Lkt::Any::Us;
use ok Locale::CLDR::Locales::Lkt::Any;

done_testing();
