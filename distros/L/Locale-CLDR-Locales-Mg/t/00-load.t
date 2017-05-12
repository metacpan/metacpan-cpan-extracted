#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Mg, 'Can use locale file Locale::CLDR::Locales::Mg';
use ok Locale::CLDR::Locales::Mg::Any::Mg, 'Can use locale file Locale::CLDR::Locales::Mg::Any::Mg';
use ok Locale::CLDR::Locales::Mg::Any, 'Can use locale file Locale::CLDR::Locales::Mg::Any';

done_testing();
