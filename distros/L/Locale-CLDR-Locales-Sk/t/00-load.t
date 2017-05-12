#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Sk, 'Can use locale file Locale::CLDR::Locales::Sk';
use ok Locale::CLDR::Locales::Sk::Any::Sk, 'Can use locale file Locale::CLDR::Locales::Sk::Any::Sk';
use ok Locale::CLDR::Locales::Sk::Any, 'Can use locale file Locale::CLDR::Locales::Sk::Any';

done_testing();
