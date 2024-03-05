#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Frr';
use ok 'Locale::CLDR::Locales::Frr::Latn::De';
use ok 'Locale::CLDR::Locales::Frr::Latn';

done_testing();
