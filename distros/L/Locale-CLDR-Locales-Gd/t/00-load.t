#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Gd, 'Can use locale file Locale::CLDR::Locales::Gd';
use ok Locale::CLDR::Locales::Gd::Any::Gb, 'Can use locale file Locale::CLDR::Locales::Gd::Any::Gb';
use ok Locale::CLDR::Locales::Gd::Any, 'Can use locale file Locale::CLDR::Locales::Gd::Any';

done_testing();
