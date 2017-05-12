#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Dsb, 'Can use locale file Locale::CLDR::Locales::Dsb';
use ok Locale::CLDR::Locales::Dsb::Any::De, 'Can use locale file Locale::CLDR::Locales::Dsb::Any::De';
use ok Locale::CLDR::Locales::Dsb::Any, 'Can use locale file Locale::CLDR::Locales::Dsb::Any';

done_testing();
