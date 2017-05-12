#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Te, 'Can use locale file Locale::CLDR::Locales::Te';
use ok Locale::CLDR::Locales::Te::Any::In, 'Can use locale file Locale::CLDR::Locales::Te::Any::In';
use ok Locale::CLDR::Locales::Te::Any, 'Can use locale file Locale::CLDR::Locales::Te::Any';

done_testing();
