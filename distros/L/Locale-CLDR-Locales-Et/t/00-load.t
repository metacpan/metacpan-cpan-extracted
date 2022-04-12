#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Et, 'Can use locale file Locale::CLDR::Locales::Et';
use ok Locale::CLDR::Locales::Et::Any::Ee, 'Can use locale file Locale::CLDR::Locales::Et::Any::Ee';
use ok Locale::CLDR::Locales::Et::Any, 'Can use locale file Locale::CLDR::Locales::Et::Any';

done_testing();
