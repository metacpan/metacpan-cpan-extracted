#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Vo, 'Can use locale file Locale::CLDR::Locales::Vo';
use ok Locale::CLDR::Locales::Vo::Any::001, 'Can use locale file Locale::CLDR::Locales::Vo::Any::001';
use ok Locale::CLDR::Locales::Vo::Any, 'Can use locale file Locale::CLDR::Locales::Vo::Any';

done_testing();
