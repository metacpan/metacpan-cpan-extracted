#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ak, 'Can use locale file Locale::CLDR::Locales::Ak';
use ok Locale::CLDR::Locales::Ak::Any::Gh, 'Can use locale file Locale::CLDR::Locales::Ak::Any::Gh';
use ok Locale::CLDR::Locales::Ak::Any, 'Can use locale file Locale::CLDR::Locales::Ak::Any';

done_testing();
