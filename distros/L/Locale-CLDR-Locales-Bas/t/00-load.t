#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Bas, 'Can use locale file Locale::CLDR::Locales::Bas';
use ok Locale::CLDR::Locales::Bas::Any::Cm, 'Can use locale file Locale::CLDR::Locales::Bas::Any::Cm';
use ok Locale::CLDR::Locales::Bas::Any, 'Can use locale file Locale::CLDR::Locales::Bas::Any';

done_testing();
