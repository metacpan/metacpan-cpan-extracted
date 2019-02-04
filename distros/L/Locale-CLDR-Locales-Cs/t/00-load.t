#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Cs, 'Can use locale file Locale::CLDR::Locales::Cs';
use ok Locale::CLDR::Locales::Cs::Any::Cz, 'Can use locale file Locale::CLDR::Locales::Cs::Any::Cz';
use ok Locale::CLDR::Locales::Cs::Any, 'Can use locale file Locale::CLDR::Locales::Cs::Any';

done_testing();
