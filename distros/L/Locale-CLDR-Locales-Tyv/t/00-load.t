#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Tyv';
use ok 'Locale::CLDR::Locales::Tyv::Cyrl::Ru';
use ok 'Locale::CLDR::Locales::Tyv::Cyrl';

done_testing();
