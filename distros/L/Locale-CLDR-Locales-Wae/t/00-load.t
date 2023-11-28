#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Wae;
use ok Locale::CLDR::Locales::Wae::Any::Ch;
use ok Locale::CLDR::Locales::Wae::Any;

done_testing();
