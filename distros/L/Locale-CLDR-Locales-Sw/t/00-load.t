#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Sw, 'Can use locale file Locale::CLDR::Locales::Sw';
use ok Locale::CLDR::Locales::Sw::Any::Cd, 'Can use locale file Locale::CLDR::Locales::Sw::Any::Cd';
use ok Locale::CLDR::Locales::Sw::Any::Ke, 'Can use locale file Locale::CLDR::Locales::Sw::Any::Ke';
use ok Locale::CLDR::Locales::Sw::Any::Tz, 'Can use locale file Locale::CLDR::Locales::Sw::Any::Tz';
use ok Locale::CLDR::Locales::Sw::Any::Ug, 'Can use locale file Locale::CLDR::Locales::Sw::Any::Ug';
use ok Locale::CLDR::Locales::Sw::Any, 'Can use locale file Locale::CLDR::Locales::Sw::Any';

done_testing();
