#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::It, 'Can use locale file Locale::CLDR::Locales::It';
use ok Locale::CLDR::Locales::It::Any::Ch, 'Can use locale file Locale::CLDR::Locales::It::Any::Ch';
use ok Locale::CLDR::Locales::It::Any::It, 'Can use locale file Locale::CLDR::Locales::It::Any::It';
use ok Locale::CLDR::Locales::It::Any::Sm, 'Can use locale file Locale::CLDR::Locales::It::Any::Sm';
use ok Locale::CLDR::Locales::It::Any, 'Can use locale file Locale::CLDR::Locales::It::Any';

done_testing();
