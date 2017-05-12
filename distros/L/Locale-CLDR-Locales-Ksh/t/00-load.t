#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Ksh, 'Can use locale file Locale::CLDR::Locales::Ksh';
use ok Locale::CLDR::Locales::Ksh::Any::De, 'Can use locale file Locale::CLDR::Locales::Ksh::Any::De';
use ok Locale::CLDR::Locales::Ksh::Any, 'Can use locale file Locale::CLDR::Locales::Ksh::Any';

done_testing();
