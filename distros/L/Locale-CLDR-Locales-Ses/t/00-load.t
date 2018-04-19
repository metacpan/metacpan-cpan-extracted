#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ses, 'Can use locale file Locale::CLDR::Locales::Ses';
use ok Locale::CLDR::Locales::Ses::Any::Ml, 'Can use locale file Locale::CLDR::Locales::Ses::Any::Ml';
use ok Locale::CLDR::Locales::Ses::Any, 'Can use locale file Locale::CLDR::Locales::Ses::Any';

done_testing();
