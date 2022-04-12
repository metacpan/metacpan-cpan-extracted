#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::As, 'Can use locale file Locale::CLDR::Locales::As';
use ok Locale::CLDR::Locales::As::Any::In, 'Can use locale file Locale::CLDR::Locales::As::Any::In';
use ok Locale::CLDR::Locales::As::Any, 'Can use locale file Locale::CLDR::Locales::As::Any';

done_testing();
