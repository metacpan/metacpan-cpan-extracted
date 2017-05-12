#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Guz, 'Can use locale file Locale::CLDR::Locales::Guz';
use ok Locale::CLDR::Locales::Guz::Any::Ke, 'Can use locale file Locale::CLDR::Locales::Guz::Any::Ke';
use ok Locale::CLDR::Locales::Guz::Any, 'Can use locale file Locale::CLDR::Locales::Guz::Any';

done_testing();
