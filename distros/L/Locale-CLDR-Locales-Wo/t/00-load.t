#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Wo;
use ok Locale::CLDR::Locales::Wo::Any::Sn;
use ok Locale::CLDR::Locales::Wo::Any;

done_testing();
