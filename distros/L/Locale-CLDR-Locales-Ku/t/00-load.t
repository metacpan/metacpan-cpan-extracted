#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ku, 'Can use locale file Locale::CLDR::Locales::Ku';
use ok Locale::CLDR::Locales::Ku::Any::Tr, 'Can use locale file Locale::CLDR::Locales::Ku::Any::Tr';
use ok Locale::CLDR::Locales::Ku::Any, 'Can use locale file Locale::CLDR::Locales::Ku::Any';

done_testing();
