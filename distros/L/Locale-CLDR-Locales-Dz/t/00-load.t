#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Dz, 'Can use locale file Locale::CLDR::Locales::Dz';
use ok Locale::CLDR::Locales::Dz::Any::Bt, 'Can use locale file Locale::CLDR::Locales::Dz::Any::Bt';
use ok Locale::CLDR::Locales::Dz::Any, 'Can use locale file Locale::CLDR::Locales::Dz::Any';

done_testing();
