#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Bm, 'Can use locale file Locale::CLDR::Locales::Bm';
use ok Locale::CLDR::Locales::Bm::Any::Ml, 'Can use locale file Locale::CLDR::Locales::Bm::Any::Ml';
use ok Locale::CLDR::Locales::Bm::Any, 'Can use locale file Locale::CLDR::Locales::Bm::Any';

done_testing();
