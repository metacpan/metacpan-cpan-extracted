#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Br, 'Can use locale file Locale::CLDR::Locales::Br';
use ok Locale::CLDR::Locales::Br::Any::Fr, 'Can use locale file Locale::CLDR::Locales::Br::Any::Fr';
use ok Locale::CLDR::Locales::Br::Any, 'Can use locale file Locale::CLDR::Locales::Br::Any';

done_testing();
