#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Pt';
use ok 'Locale::CLDR::Locales::Pt::Latn::Ao';
use ok 'Locale::CLDR::Locales::Pt::Latn::Br';
use ok 'Locale::CLDR::Locales::Pt::Latn::Ch';
use ok 'Locale::CLDR::Locales::Pt::Latn::Cv';
use ok 'Locale::CLDR::Locales::Pt::Latn::Gq';
use ok 'Locale::CLDR::Locales::Pt::Latn::Gw';
use ok 'Locale::CLDR::Locales::Pt::Latn::Lu';
use ok 'Locale::CLDR::Locales::Pt::Latn::Mo';
use ok 'Locale::CLDR::Locales::Pt::Latn::Mz';
use ok 'Locale::CLDR::Locales::Pt::Latn::Pt';
use ok 'Locale::CLDR::Locales::Pt::Latn::St';
use ok 'Locale::CLDR::Locales::Pt::Latn::Tl';
use ok 'Locale::CLDR::Locales::Pt::Latn';

done_testing();
