#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Brx, 'Can use locale file Locale::CLDR::Locales::Brx';
use ok Locale::CLDR::Locales::Brx::Any::In, 'Can use locale file Locale::CLDR::Locales::Brx::Any::In';
use ok Locale::CLDR::Locales::Brx::Any, 'Can use locale file Locale::CLDR::Locales::Brx::Any';

done_testing();
