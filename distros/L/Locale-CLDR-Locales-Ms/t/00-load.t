#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ms, 'Can use locale file Locale::CLDR::Locales::Ms';
use ok Locale::CLDR::Locales::Ms::Any::Bn, 'Can use locale file Locale::CLDR::Locales::Ms::Any::Bn';
use ok Locale::CLDR::Locales::Ms::Any::My, 'Can use locale file Locale::CLDR::Locales::Ms::Any::My';
use ok Locale::CLDR::Locales::Ms::Any::Sg, 'Can use locale file Locale::CLDR::Locales::Ms::Any::Sg';
use ok Locale::CLDR::Locales::Ms::Any, 'Can use locale file Locale::CLDR::Locales::Ms::Any';

done_testing();
