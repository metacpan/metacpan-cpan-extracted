#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Asa, 'Can use locale file Locale::CLDR::Locales::Asa';
use ok Locale::CLDR::Locales::Asa::Any::Tz, 'Can use locale file Locale::CLDR::Locales::Asa::Any::Tz';
use ok Locale::CLDR::Locales::Asa::Any, 'Can use locale file Locale::CLDR::Locales::Asa::Any';

done_testing();
