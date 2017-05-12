#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Rw, 'Can use locale file Locale::CLDR::Locales::Rw';
use ok Locale::CLDR::Locales::Rw::Any::Rw, 'Can use locale file Locale::CLDR::Locales::Rw::Any::Rw';
use ok Locale::CLDR::Locales::Rw::Any, 'Can use locale file Locale::CLDR::Locales::Rw::Any';

done_testing();
