#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sma';
use ok 'Locale::CLDR::Locales::Sma::Latn::No';
use ok 'Locale::CLDR::Locales::Sma::Latn::Se';
use ok 'Locale::CLDR::Locales::Sma::Latn';

done_testing();
