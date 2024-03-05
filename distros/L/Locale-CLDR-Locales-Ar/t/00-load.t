#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.44.1, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Ar';
use ok 'Locale::CLDR::Locales::Ar::Arab::001';
use ok 'Locale::CLDR::Locales::Ar::Arab::Ae';
use ok 'Locale::CLDR::Locales::Ar::Arab::Bh';
use ok 'Locale::CLDR::Locales::Ar::Arab::Dj';
use ok 'Locale::CLDR::Locales::Ar::Arab::Dz';
use ok 'Locale::CLDR::Locales::Ar::Arab::Eg';
use ok 'Locale::CLDR::Locales::Ar::Arab::Eh';
use ok 'Locale::CLDR::Locales::Ar::Arab::Er';
use ok 'Locale::CLDR::Locales::Ar::Arab::Il';
use ok 'Locale::CLDR::Locales::Ar::Arab::Iq';
use ok 'Locale::CLDR::Locales::Ar::Arab::Jo';
use ok 'Locale::CLDR::Locales::Ar::Arab::Km';
use ok 'Locale::CLDR::Locales::Ar::Arab::Kw';
use ok 'Locale::CLDR::Locales::Ar::Arab::Lb';
use ok 'Locale::CLDR::Locales::Ar::Arab::Ly';
use ok 'Locale::CLDR::Locales::Ar::Arab::Ma';
use ok 'Locale::CLDR::Locales::Ar::Arab::Mr';
use ok 'Locale::CLDR::Locales::Ar::Arab::Om';
use ok 'Locale::CLDR::Locales::Ar::Arab::Ps';
use ok 'Locale::CLDR::Locales::Ar::Arab::Qa';
use ok 'Locale::CLDR::Locales::Ar::Arab::Sa';
use ok 'Locale::CLDR::Locales::Ar::Arab::Sd';
use ok 'Locale::CLDR::Locales::Ar::Arab::So';
use ok 'Locale::CLDR::Locales::Ar::Arab::Ss';
use ok 'Locale::CLDR::Locales::Ar::Arab::Sy';
use ok 'Locale::CLDR::Locales::Ar::Arab::Td';
use ok 'Locale::CLDR::Locales::Ar::Arab::Tn';
use ok 'Locale::CLDR::Locales::Ar::Arab::Ye';
use ok 'Locale::CLDR::Locales::Ar::Arab';

done_testing();
