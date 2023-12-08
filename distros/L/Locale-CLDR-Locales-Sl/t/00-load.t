#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Sl;
use ok Locale::CLDR::Locales::Sl::Any::Si;
use ok Locale::CLDR::Locales::Sl::Any;

done_testing();
