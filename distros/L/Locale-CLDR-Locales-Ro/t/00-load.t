#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Ro, 'Can use locale file Locale::CLDR::Locales::Ro';
use ok Locale::CLDR::Locales::Ro::Any::Md, 'Can use locale file Locale::CLDR::Locales::Ro::Any::Md';
use ok Locale::CLDR::Locales::Ro::Any::Ro, 'Can use locale file Locale::CLDR::Locales::Ro::Any::Ro';
use ok Locale::CLDR::Locales::Ro::Any, 'Can use locale file Locale::CLDR::Locales::Ro::Any';

done_testing();
