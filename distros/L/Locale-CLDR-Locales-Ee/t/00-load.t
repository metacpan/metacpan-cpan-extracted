#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ee;
use ok Locale::CLDR::Locales::Ee::Any::Gh;
use ok Locale::CLDR::Locales::Ee::Any::Tg;
use ok Locale::CLDR::Locales::Ee::Any;

done_testing();
