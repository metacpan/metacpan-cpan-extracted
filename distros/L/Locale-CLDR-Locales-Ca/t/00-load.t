#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ca';
use ok 'Locale::CLDR::Locales::Ca::Latn::Ad';
use ok 'Locale::CLDR::Locales::Ca::Latn::Es::Valencia';
use ok 'Locale::CLDR::Locales::Ca::Latn::Es';
use ok 'Locale::CLDR::Locales::Ca::Latn::Fr';
use ok 'Locale::CLDR::Locales::Ca::Latn::It';
use ok 'Locale::CLDR::Locales::Ca::Latn';

done_testing();
