#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::So, 'Can use locale file Locale::CLDR::Locales::So';
use ok Locale::CLDR::Locales::So::Any::Dj, 'Can use locale file Locale::CLDR::Locales::So::Any::Dj';
use ok Locale::CLDR::Locales::So::Any::Et, 'Can use locale file Locale::CLDR::Locales::So::Any::Et';
use ok Locale::CLDR::Locales::So::Any::Ke, 'Can use locale file Locale::CLDR::Locales::So::Any::Ke';
use ok Locale::CLDR::Locales::So::Any::So, 'Can use locale file Locale::CLDR::Locales::So::Any::So';
use ok Locale::CLDR::Locales::So::Any, 'Can use locale file Locale::CLDR::Locales::So::Any';

done_testing();
