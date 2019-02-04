#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ur, 'Can use locale file Locale::CLDR::Locales::Ur';
use ok Locale::CLDR::Locales::Ur::Any::In, 'Can use locale file Locale::CLDR::Locales::Ur::Any::In';
use ok Locale::CLDR::Locales::Ur::Any::Pk, 'Can use locale file Locale::CLDR::Locales::Ur::Any::Pk';
use ok Locale::CLDR::Locales::Ur::Any, 'Can use locale file Locale::CLDR::Locales::Ur::Any';

done_testing();
