#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Eo, 'Can use locale file Locale::CLDR::Locales::Eo';
use ok Locale::CLDR::Locales::Eo::Any::001, 'Can use locale file Locale::CLDR::Locales::Eo::Any::001';
use ok Locale::CLDR::Locales::Eo::Any, 'Can use locale file Locale::CLDR::Locales::Eo::Any';

done_testing();
