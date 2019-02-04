#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Kde, 'Can use locale file Locale::CLDR::Locales::Kde';
use ok Locale::CLDR::Locales::Kde::Any::Tz, 'Can use locale file Locale::CLDR::Locales::Kde::Any::Tz';
use ok Locale::CLDR::Locales::Kde::Any, 'Can use locale file Locale::CLDR::Locales::Kde::Any';

done_testing();
