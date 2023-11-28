#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Lo;
use ok Locale::CLDR::Locales::Lo::Any::La;
use ok Locale::CLDR::Locales::Lo::Any;

done_testing();
