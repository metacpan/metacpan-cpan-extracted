#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Os;
use ok Locale::CLDR::Locales::Os::Any::Ge;
use ok Locale::CLDR::Locales::Os::Any::Ru;
use ok Locale::CLDR::Locales::Os::Any;

done_testing();
