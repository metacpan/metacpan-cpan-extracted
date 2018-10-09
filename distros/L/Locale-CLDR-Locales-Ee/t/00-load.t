#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ee, 'Can use locale file Locale::CLDR::Locales::Ee';
use ok Locale::CLDR::Locales::Ee::Any::Gh, 'Can use locale file Locale::CLDR::Locales::Ee::Any::Gh';
use ok Locale::CLDR::Locales::Ee::Any::Tg, 'Can use locale file Locale::CLDR::Locales::Ee::Any::Tg';
use ok Locale::CLDR::Locales::Ee::Any, 'Can use locale file Locale::CLDR::Locales::Ee::Any';

done_testing();
