#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Prg, 'Can use locale file Locale::CLDR::Locales::Prg';
use ok Locale::CLDR::Locales::Prg::Any::001, 'Can use locale file Locale::CLDR::Locales::Prg::Any::001';
use ok Locale::CLDR::Locales::Prg::Any, 'Can use locale file Locale::CLDR::Locales::Prg::Any';

done_testing();
