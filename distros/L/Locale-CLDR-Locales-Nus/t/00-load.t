#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Nus;
use ok Locale::CLDR::Locales::Nus::Any::Ss;
use ok Locale::CLDR::Locales::Nus::Any;

done_testing();
