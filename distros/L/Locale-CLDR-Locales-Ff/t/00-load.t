#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.1, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ff, 'Can use locale file Locale::CLDR::Locales::Ff';
use ok Locale::CLDR::Locales::Ff::Latn, 'Can use locale file Locale::CLDR::Locales::Ff::Latn';
use ok Locale::CLDR::Locales::Ff::Latn::Ne, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Ne';
use ok Locale::CLDR::Locales::Ff::Latn::Bf, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Bf';
use ok Locale::CLDR::Locales::Ff::Latn::Cm, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Cm';
use ok Locale::CLDR::Locales::Ff::Latn::Mr, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Mr';
use ok Locale::CLDR::Locales::Ff::Latn::Gh, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Gh';
use ok Locale::CLDR::Locales::Ff::Latn::Sl, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Sl';
use ok Locale::CLDR::Locales::Ff::Latn::Lr, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Lr';
use ok Locale::CLDR::Locales::Ff::Latn::Gm, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Gm';
use ok Locale::CLDR::Locales::Ff::Latn::Sn, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Sn';
use ok Locale::CLDR::Locales::Ff::Latn::Gn, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Gn';
use ok Locale::CLDR::Locales::Ff::Latn::Gw, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Gw';
use ok Locale::CLDR::Locales::Ff::Latn::Ng, 'Can use locale file Locale::CLDR::Locales::Ff::Latn::Ng';

done_testing();
