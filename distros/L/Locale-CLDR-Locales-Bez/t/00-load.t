#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Bez, 'Can use locale file Locale::CLDR::Locales::Bez';
use ok Locale::CLDR::Locales::Bez::Any::Tz, 'Can use locale file Locale::CLDR::Locales::Bez::Any::Tz';
use ok Locale::CLDR::Locales::Bez::Any, 'Can use locale file Locale::CLDR::Locales::Bez::Any';

done_testing();
