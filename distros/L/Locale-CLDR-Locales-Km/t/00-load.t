#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Km, 'Can use locale file Locale::CLDR::Locales::Km';
use ok Locale::CLDR::Locales::Km::Any::Kh, 'Can use locale file Locale::CLDR::Locales::Km::Any::Kh';
use ok Locale::CLDR::Locales::Km::Any, 'Can use locale file Locale::CLDR::Locales::Km::Any';

done_testing();
