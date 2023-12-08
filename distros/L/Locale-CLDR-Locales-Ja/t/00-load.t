#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ja;
use ok Locale::CLDR::Locales::Ja::Any::Jp;
use ok Locale::CLDR::Locales::Ja::Any;

done_testing();
