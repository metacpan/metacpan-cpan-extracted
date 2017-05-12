#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Nyn, 'Can use locale file Locale::CLDR::Locales::Nyn';
use ok Locale::CLDR::Locales::Nyn::Any::Ug, 'Can use locale file Locale::CLDR::Locales::Nyn::Any::Ug';
use ok Locale::CLDR::Locales::Nyn::Any, 'Can use locale file Locale::CLDR::Locales::Nyn::Any';

done_testing();
