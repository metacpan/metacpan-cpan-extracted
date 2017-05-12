#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Dyo, 'Can use locale file Locale::CLDR::Locales::Dyo';
use ok Locale::CLDR::Locales::Dyo::Any::Sn, 'Can use locale file Locale::CLDR::Locales::Dyo::Any::Sn';
use ok Locale::CLDR::Locales::Dyo::Any, 'Can use locale file Locale::CLDR::Locales::Dyo::Any';

done_testing();
