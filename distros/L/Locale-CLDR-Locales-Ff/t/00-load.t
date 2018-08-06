#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ff, 'Can use locale file Locale::CLDR::Locales::Ff';
use ok Locale::CLDR::Locales::Ff::Any::Cm, 'Can use locale file Locale::CLDR::Locales::Ff::Any::Cm';
use ok Locale::CLDR::Locales::Ff::Any::Gn, 'Can use locale file Locale::CLDR::Locales::Ff::Any::Gn';
use ok Locale::CLDR::Locales::Ff::Any::Mr, 'Can use locale file Locale::CLDR::Locales::Ff::Any::Mr';
use ok Locale::CLDR::Locales::Ff::Any::Sn, 'Can use locale file Locale::CLDR::Locales::Ff::Any::Sn';
use ok Locale::CLDR::Locales::Ff::Any, 'Can use locale file Locale::CLDR::Locales::Ff::Any';

done_testing();
