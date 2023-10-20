#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Khq;
use ok Locale::CLDR::Locales::Khq::Any::Ml;
use ok Locale::CLDR::Locales::Khq::Any;

done_testing();
