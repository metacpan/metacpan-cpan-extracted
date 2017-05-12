#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Sv, 'Can use locale file Locale::CLDR::Locales::Sv';
use ok Locale::CLDR::Locales::Sv::Any::Ax, 'Can use locale file Locale::CLDR::Locales::Sv::Any::Ax';
use ok Locale::CLDR::Locales::Sv::Any::Fi, 'Can use locale file Locale::CLDR::Locales::Sv::Any::Fi';
use ok Locale::CLDR::Locales::Sv::Any::Se, 'Can use locale file Locale::CLDR::Locales::Sv::Any::Se';
use ok Locale::CLDR::Locales::Sv::Any, 'Can use locale file Locale::CLDR::Locales::Sv::Any';

done_testing();
