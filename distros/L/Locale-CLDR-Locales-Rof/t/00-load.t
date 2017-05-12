#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Rof, 'Can use locale file Locale::CLDR::Locales::Rof';
use ok Locale::CLDR::Locales::Rof::Any::Tz, 'Can use locale file Locale::CLDR::Locales::Rof::Any::Tz';
use ok Locale::CLDR::Locales::Rof::Any, 'Can use locale file Locale::CLDR::Locales::Rof::Any';

done_testing();
