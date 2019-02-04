#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Pt, 'Can use locale file Locale::CLDR::Locales::Pt';
use ok Locale::CLDR::Locales::Pt::Any::Ao, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Ao';
use ok Locale::CLDR::Locales::Pt::Any::Br, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Br';
use ok Locale::CLDR::Locales::Pt::Any::Ch, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Ch';
use ok Locale::CLDR::Locales::Pt::Any::Cv, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Cv';
use ok Locale::CLDR::Locales::Pt::Any::Gq, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Gq';
use ok Locale::CLDR::Locales::Pt::Any::Gw, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Gw';
use ok Locale::CLDR::Locales::Pt::Any::Lu, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Lu';
use ok Locale::CLDR::Locales::Pt::Any::Mo, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Mo';
use ok Locale::CLDR::Locales::Pt::Any::Mz, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Mz';
use ok Locale::CLDR::Locales::Pt::Any::Pt, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Pt';
use ok Locale::CLDR::Locales::Pt::Any::St, 'Can use locale file Locale::CLDR::Locales::Pt::Any::St';
use ok Locale::CLDR::Locales::Pt::Any::Tl, 'Can use locale file Locale::CLDR::Locales::Pt::Any::Tl';
use ok Locale::CLDR::Locales::Pt::Any, 'Can use locale file Locale::CLDR::Locales::Pt::Any';

done_testing();
