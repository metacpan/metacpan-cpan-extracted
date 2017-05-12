#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Ksf, 'Can use locale file Locale::CLDR::Locales::Ksf';
use ok Locale::CLDR::Locales::Ksf::Any::Cm, 'Can use locale file Locale::CLDR::Locales::Ksf::Any::Cm';
use ok Locale::CLDR::Locales::Ksf::Any, 'Can use locale file Locale::CLDR::Locales::Ksf::Any';

done_testing();
