#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Ne, 'Can use locale file Locale::CLDR::Locales::Ne';
use ok Locale::CLDR::Locales::Ne::Any::In, 'Can use locale file Locale::CLDR::Locales::Ne::Any::In';
use ok Locale::CLDR::Locales::Ne::Any::Np, 'Can use locale file Locale::CLDR::Locales::Ne::Any::Np';
use ok Locale::CLDR::Locales::Ne::Any, 'Can use locale file Locale::CLDR::Locales::Ne::Any';

done_testing();
