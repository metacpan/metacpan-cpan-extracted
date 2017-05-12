#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Nnh, 'Can use locale file Locale::CLDR::Locales::Nnh';
use ok Locale::CLDR::Locales::Nnh::Any::Cm, 'Can use locale file Locale::CLDR::Locales::Nnh::Any::Cm';
use ok Locale::CLDR::Locales::Nnh::Any, 'Can use locale file Locale::CLDR::Locales::Nnh::Any';

done_testing();
