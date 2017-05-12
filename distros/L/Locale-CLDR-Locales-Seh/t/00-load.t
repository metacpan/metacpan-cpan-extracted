#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Seh, 'Can use locale file Locale::CLDR::Locales::Seh';
use ok Locale::CLDR::Locales::Seh::Any::Mz, 'Can use locale file Locale::CLDR::Locales::Seh::Any::Mz';
use ok Locale::CLDR::Locales::Seh::Any, 'Can use locale file Locale::CLDR::Locales::Seh::Any';

done_testing();
