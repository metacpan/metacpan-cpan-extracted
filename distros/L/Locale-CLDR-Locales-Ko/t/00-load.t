#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ko, 'Can use locale file Locale::CLDR::Locales::Ko';
use ok Locale::CLDR::Locales::Ko::Any::Kp, 'Can use locale file Locale::CLDR::Locales::Ko::Any::Kp';
use ok Locale::CLDR::Locales::Ko::Any::Kr, 'Can use locale file Locale::CLDR::Locales::Ko::Any::Kr';
use ok Locale::CLDR::Locales::Ko::Any, 'Can use locale file Locale::CLDR::Locales::Ko::Any';

done_testing();
