#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Nb';
use ok 'Locale::CLDR::Locales::Nb::Latn::No';
use ok 'Locale::CLDR::Locales::Nb::Latn::Sj';
use ok 'Locale::CLDR::Locales::Nb::Latn';

done_testing();
