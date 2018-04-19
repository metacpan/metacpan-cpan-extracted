#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ewo, 'Can use locale file Locale::CLDR::Locales::Ewo';
use ok Locale::CLDR::Locales::Ewo::Any::Cm, 'Can use locale file Locale::CLDR::Locales::Ewo::Any::Cm';
use ok Locale::CLDR::Locales::Ewo::Any, 'Can use locale file Locale::CLDR::Locales::Ewo::Any';

done_testing();
