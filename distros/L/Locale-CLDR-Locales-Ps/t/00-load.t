#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Ps, 'Can use locale file Locale::CLDR::Locales::Ps';
use ok Locale::CLDR::Locales::Ps::Any::Af, 'Can use locale file Locale::CLDR::Locales::Ps::Any::Af';
use ok Locale::CLDR::Locales::Ps::Any, 'Can use locale file Locale::CLDR::Locales::Ps::Any';

done_testing();
