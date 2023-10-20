#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Prg;
use ok Locale::CLDR::Locales::Prg::Any::001;
use ok Locale::CLDR::Locales::Prg::Any;

done_testing();
