#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Lb;
use ok Locale::CLDR::Locales::Lb::Any::Lu;
use ok Locale::CLDR::Locales::Lb::Any;

done_testing();
