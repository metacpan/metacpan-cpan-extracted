#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Uk;
use ok Locale::CLDR::Locales::Uk::Any::Ua;
use ok Locale::CLDR::Locales::Uk::Any;

done_testing();
