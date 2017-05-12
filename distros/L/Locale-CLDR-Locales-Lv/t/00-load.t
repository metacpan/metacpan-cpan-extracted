#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Lv, 'Can use locale file Locale::CLDR::Locales::Lv';
use ok Locale::CLDR::Locales::Lv::Any::Lv, 'Can use locale file Locale::CLDR::Locales::Lv::Any::Lv';
use ok Locale::CLDR::Locales::Lv::Any, 'Can use locale file Locale::CLDR::Locales::Lv::Any';

done_testing();
