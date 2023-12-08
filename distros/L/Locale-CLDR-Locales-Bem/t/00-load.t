#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Bem;
use ok Locale::CLDR::Locales::Bem::Any::Zm;
use ok Locale::CLDR::Locales::Bem::Any;

done_testing();
