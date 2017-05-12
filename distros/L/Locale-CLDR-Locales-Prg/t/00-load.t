#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Prg, 'Can use locale file Locale::CLDR::Locales::Prg';
use ok Locale::CLDR::Locales::Prg::Any::001, 'Can use locale file Locale::CLDR::Locales::Prg::Any::001';
use ok Locale::CLDR::Locales::Prg::Any, 'Can use locale file Locale::CLDR::Locales::Prg::Any';

done_testing();
