#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Mas;
use ok Locale::CLDR::Locales::Mas::Any::Ke;
use ok Locale::CLDR::Locales::Mas::Any::Tz;
use ok Locale::CLDR::Locales::Mas::Any;

done_testing();
