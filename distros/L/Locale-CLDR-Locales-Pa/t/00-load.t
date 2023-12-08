#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Pa;
use ok Locale::CLDR::Locales::Pa::Arab::Pk;
use ok Locale::CLDR::Locales::Pa::Arab;
use ok Locale::CLDR::Locales::Pa::Guru::In;
use ok Locale::CLDR::Locales::Pa::Guru;

done_testing();
