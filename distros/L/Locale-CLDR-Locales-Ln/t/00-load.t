#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ln, 'Can use locale file Locale::CLDR::Locales::Ln';
use ok Locale::CLDR::Locales::Ln::Any::Cg, 'Can use locale file Locale::CLDR::Locales::Ln::Any::Cg';
use ok Locale::CLDR::Locales::Ln::Any::Cf, 'Can use locale file Locale::CLDR::Locales::Ln::Any::Cf';
use ok Locale::CLDR::Locales::Ln::Any::Ao, 'Can use locale file Locale::CLDR::Locales::Ln::Any::Ao';
use ok Locale::CLDR::Locales::Ln::Any::Cd, 'Can use locale file Locale::CLDR::Locales::Ln::Any::Cd';
use ok Locale::CLDR::Locales::Ln::Any, 'Can use locale file Locale::CLDR::Locales::Ln::Any';

done_testing();
