#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Ga, 'Can use locale file Locale::CLDR::Locales::Ga';
use ok Locale::CLDR::Locales::Ga::Any::Ie, 'Can use locale file Locale::CLDR::Locales::Ga::Any::Ie';
use ok Locale::CLDR::Locales::Ga::Any, 'Can use locale file Locale::CLDR::Locales::Ga::Any';

done_testing();
