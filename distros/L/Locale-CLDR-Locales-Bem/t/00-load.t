#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.29.0, Perl 5.018002, D:\strawberry\perl\bin\perl.exe" );
use ok Locale::CLDR::Locales::Bem, 'Can use locale file Locale::CLDR::Locales::Bem';
use ok Locale::CLDR::Locales::Bem::Any::Zm, 'Can use locale file Locale::CLDR::Locales::Bem::Any::Zm';
use ok Locale::CLDR::Locales::Bem::Any, 'Can use locale file Locale::CLDR::Locales::Bem::Any';

done_testing();
