#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Ha, 'Can use locale file Locale::CLDR::Locales::Ha';
use ok Locale::CLDR::Locales::Ha::Any::Gh, 'Can use locale file Locale::CLDR::Locales::Ha::Any::Gh';
use ok Locale::CLDR::Locales::Ha::Any::Ne, 'Can use locale file Locale::CLDR::Locales::Ha::Any::Ne';
use ok Locale::CLDR::Locales::Ha::Any::Ng, 'Can use locale file Locale::CLDR::Locales::Ha::Any::Ng';
use ok Locale::CLDR::Locales::Ha::Any, 'Can use locale file Locale::CLDR::Locales::Ha::Any';

done_testing();
