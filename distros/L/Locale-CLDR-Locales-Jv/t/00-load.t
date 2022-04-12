#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Jv, 'Can use locale file Locale::CLDR::Locales::Jv';
use ok Locale::CLDR::Locales::Jv::Any::Id, 'Can use locale file Locale::CLDR::Locales::Jv::Any::Id';
use ok Locale::CLDR::Locales::Jv::Any, 'Can use locale file Locale::CLDR::Locales::Jv::Any';

done_testing();
