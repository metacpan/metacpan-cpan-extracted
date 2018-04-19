#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.32.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Or, 'Can use locale file Locale::CLDR::Locales::Or';
use ok Locale::CLDR::Locales::Or::Any::In, 'Can use locale file Locale::CLDR::Locales::Or::Any::In';
use ok Locale::CLDR::Locales::Or::Any, 'Can use locale file Locale::CLDR::Locales::Or::Any';

done_testing();
