#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ff';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Bf';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Cm';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Gh';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Gm';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Gn';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Gw';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Lr';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Mr';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Ne';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Ng';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Sl';
use ok 'Locale::CLDR::Locales::Ff::Adlm::Sn';
use ok 'Locale::CLDR::Locales::Ff::Adlm';
use ok 'Locale::CLDR::Locales::Ff::Latn::Bf';
use ok 'Locale::CLDR::Locales::Ff::Latn::Cm';
use ok 'Locale::CLDR::Locales::Ff::Latn::Gh';
use ok 'Locale::CLDR::Locales::Ff::Latn::Gm';
use ok 'Locale::CLDR::Locales::Ff::Latn::Gn';
use ok 'Locale::CLDR::Locales::Ff::Latn::Gw';
use ok 'Locale::CLDR::Locales::Ff::Latn::Lr';
use ok 'Locale::CLDR::Locales::Ff::Latn::Mr';
use ok 'Locale::CLDR::Locales::Ff::Latn::Ne';
use ok 'Locale::CLDR::Locales::Ff::Latn::Ng';
use ok 'Locale::CLDR::Locales::Ff::Latn::Sl';
use ok 'Locale::CLDR::Locales::Ff::Latn::Sn';
use ok 'Locale::CLDR::Locales::Ff::Latn';

done_testing();
