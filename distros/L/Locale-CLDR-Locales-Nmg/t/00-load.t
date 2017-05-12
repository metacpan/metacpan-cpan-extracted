#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Nmg, 'Can use locale file Locale::CLDR::Locales::Nmg';
use ok Locale::CLDR::Locales::Nmg::Any::Cm, 'Can use locale file Locale::CLDR::Locales::Nmg::Any::Cm';
use ok Locale::CLDR::Locales::Nmg::Any, 'Can use locale file Locale::CLDR::Locales::Nmg::Any';

done_testing();
