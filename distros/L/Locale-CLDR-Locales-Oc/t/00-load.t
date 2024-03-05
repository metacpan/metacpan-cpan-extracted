#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Oc';
use ok 'Locale::CLDR::Locales::Oc::Latn::Es';
use ok 'Locale::CLDR::Locales::Oc::Latn::Fr';
use ok 'Locale::CLDR::Locales::Oc::Latn';

done_testing();
