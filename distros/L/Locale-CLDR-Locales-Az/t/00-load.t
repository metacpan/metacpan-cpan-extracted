#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Az';
use ok 'Locale::CLDR::Locales::Az::Arab::Iq';
use ok 'Locale::CLDR::Locales::Az::Arab::Ir';
use ok 'Locale::CLDR::Locales::Az::Arab::Tr';
use ok 'Locale::CLDR::Locales::Az::Arab';
use ok 'Locale::CLDR::Locales::Az::Cyrl::Az';
use ok 'Locale::CLDR::Locales::Az::Cyrl';
use ok 'Locale::CLDR::Locales::Az::Latn::Az';
use ok 'Locale::CLDR::Locales::Az::Latn';

done_testing();
