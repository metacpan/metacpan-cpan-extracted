#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Ses, 'Can use locale file Locale::CLDR::Locales::Ses';
use ok Locale::CLDR::Locales::Ses::Any::Ml, 'Can use locale file Locale::CLDR::Locales::Ses::Any::Ml';
use ok Locale::CLDR::Locales::Ses::Any, 'Can use locale file Locale::CLDR::Locales::Ses::Any';

done_testing();
