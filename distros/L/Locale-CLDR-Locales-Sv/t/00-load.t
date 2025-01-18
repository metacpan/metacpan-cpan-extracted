#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Sv';
use ok 'Locale::CLDR::Locales::Sv::Latn::Ax';
use ok 'Locale::CLDR::Locales::Sv::Latn::Fi';
use ok 'Locale::CLDR::Locales::Sv::Latn::Se';
use ok 'Locale::CLDR::Locales::Sv::Latn';

done_testing();
