#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Pa, 'Can use locale file Locale::CLDR::Locales::Pa';
use ok Locale::CLDR::Locales::Pa::Guru::In, 'Can use locale file Locale::CLDR::Locales::Pa::Guru::In';
use ok Locale::CLDR::Locales::Pa::Arab, 'Can use locale file Locale::CLDR::Locales::Pa::Arab';
use ok Locale::CLDR::Locales::Pa::Guru, 'Can use locale file Locale::CLDR::Locales::Pa::Guru';
use ok Locale::CLDR::Locales::Pa::Arab::Pk, 'Can use locale file Locale::CLDR::Locales::Pa::Arab::Pk';

done_testing();
