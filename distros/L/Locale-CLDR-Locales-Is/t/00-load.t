#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Is, 'Can use locale file Locale::CLDR::Locales::Is';
use ok Locale::CLDR::Locales::Is::Any::Is, 'Can use locale file Locale::CLDR::Locales::Is::Any::Is';
use ok Locale::CLDR::Locales::Is::Any, 'Can use locale file Locale::CLDR::Locales::Is::Any';

done_testing();
