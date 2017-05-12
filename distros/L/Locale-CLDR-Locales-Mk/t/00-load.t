#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Mk, 'Can use locale file Locale::CLDR::Locales::Mk';
use ok Locale::CLDR::Locales::Mk::Any::Mk, 'Can use locale file Locale::CLDR::Locales::Mk::Any::Mk';
use ok Locale::CLDR::Locales::Mk::Any, 'Can use locale file Locale::CLDR::Locales::Mk::Any';

done_testing();
