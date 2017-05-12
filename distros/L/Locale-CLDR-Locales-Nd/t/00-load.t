#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Nd, 'Can use locale file Locale::CLDR::Locales::Nd';
use ok Locale::CLDR::Locales::Nd::Any::Zw, 'Can use locale file Locale::CLDR::Locales::Nd::Any::Zw';
use ok Locale::CLDR::Locales::Nd::Any, 'Can use locale file Locale::CLDR::Locales::Nd::Any';

done_testing();
