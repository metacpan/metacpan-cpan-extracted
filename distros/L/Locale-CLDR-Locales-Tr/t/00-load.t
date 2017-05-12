#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Tr, 'Can use locale file Locale::CLDR::Locales::Tr';
use ok Locale::CLDR::Locales::Tr::Any::Cy, 'Can use locale file Locale::CLDR::Locales::Tr::Any::Cy';
use ok Locale::CLDR::Locales::Tr::Any::Tr, 'Can use locale file Locale::CLDR::Locales::Tr::Any::Tr';
use ok Locale::CLDR::Locales::Tr::Any, 'Can use locale file Locale::CLDR::Locales::Tr::Any';

done_testing();
