#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Se';
use ok 'Locale::CLDR::Locales::Se::Latn::Fi';
use ok 'Locale::CLDR::Locales::Se::Latn::No';
use ok 'Locale::CLDR::Locales::Se::Latn::Se';
use ok 'Locale::CLDR::Locales::Se::Latn';

done_testing();
