#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Si, 'Can use locale file Locale::CLDR::Locales::Si';
use ok Locale::CLDR::Locales::Si::Any::Lk, 'Can use locale file Locale::CLDR::Locales::Si::Any::Lk';
use ok Locale::CLDR::Locales::Si::Any, 'Can use locale file Locale::CLDR::Locales::Si::Any';

done_testing();
