#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Uk, 'Can use locale file Locale::CLDR::Locales::Uk';
use ok Locale::CLDR::Locales::Uk::Any::Ua, 'Can use locale file Locale::CLDR::Locales::Uk::Any::Ua';
use ok Locale::CLDR::Locales::Uk::Any, 'Can use locale file Locale::CLDR::Locales::Uk::Any';

done_testing();
