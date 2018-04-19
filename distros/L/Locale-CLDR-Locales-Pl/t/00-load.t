#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Pl, 'Can use locale file Locale::CLDR::Locales::Pl';
use ok Locale::CLDR::Locales::Pl::Any::Pl, 'Can use locale file Locale::CLDR::Locales::Pl::Any::Pl';
use ok Locale::CLDR::Locales::Pl::Any, 'Can use locale file Locale::CLDR::Locales::Pl::Any';

done_testing();
