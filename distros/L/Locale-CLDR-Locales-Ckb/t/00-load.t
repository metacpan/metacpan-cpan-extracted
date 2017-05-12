#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Ckb, 'Can use locale file Locale::CLDR::Locales::Ckb';
use ok Locale::CLDR::Locales::Ckb::Any::Iq, 'Can use locale file Locale::CLDR::Locales::Ckb::Any::Iq';
use ok Locale::CLDR::Locales::Ckb::Any::Ir, 'Can use locale file Locale::CLDR::Locales::Ckb::Any::Ir';
use ok Locale::CLDR::Locales::Ckb::Any, 'Can use locale file Locale::CLDR::Locales::Ckb::Any';

done_testing();
