#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Kn;
use ok Locale::CLDR::Locales::Kn::Any::In;
use ok Locale::CLDR::Locales::Kn::Any;

done_testing();
