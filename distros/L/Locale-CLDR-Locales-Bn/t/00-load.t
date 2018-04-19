#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Bn, 'Can use locale file Locale::CLDR::Locales::Bn';
use ok Locale::CLDR::Locales::Bn::Any::Bd, 'Can use locale file Locale::CLDR::Locales::Bn::Any::Bd';
use ok Locale::CLDR::Locales::Bn::Any::In, 'Can use locale file Locale::CLDR::Locales::Bn::Any::In';
use ok Locale::CLDR::Locales::Bn::Any, 'Can use locale file Locale::CLDR::Locales::Bn::Any';

done_testing();
