#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.2, Perl $], $^X" );
use ok Locale::CLDR::Locales::Si;
use ok Locale::CLDR::Locales::Si::Any::Lk;
use ok Locale::CLDR::Locales::Si::Any;

done_testing();
