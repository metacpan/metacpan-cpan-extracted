#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.3, Perl $], $^X" );
use ok Locale::CLDR::Locales::Es;
use ok Locale::CLDR::Locales::Es::Any::419;
use ok Locale::CLDR::Locales::Es::Any::Ar;
use ok Locale::CLDR::Locales::Es::Any::Bo;
use ok Locale::CLDR::Locales::Es::Any::Br;
use ok Locale::CLDR::Locales::Es::Any::Bz;
use ok Locale::CLDR::Locales::Es::Any::Cl;
use ok Locale::CLDR::Locales::Es::Any::Co;
use ok Locale::CLDR::Locales::Es::Any::Cr;
use ok Locale::CLDR::Locales::Es::Any::Cu;
use ok Locale::CLDR::Locales::Es::Any::Do;
use ok Locale::CLDR::Locales::Es::Any::Ea;
use ok Locale::CLDR::Locales::Es::Any::Ec;
use ok Locale::CLDR::Locales::Es::Any::Es;
use ok Locale::CLDR::Locales::Es::Any::Gq;
use ok Locale::CLDR::Locales::Es::Any::Gt;
use ok Locale::CLDR::Locales::Es::Any::Hn;
use ok Locale::CLDR::Locales::Es::Any::Ic;
use ok Locale::CLDR::Locales::Es::Any::Mx;
use ok Locale::CLDR::Locales::Es::Any::Ni;
use ok Locale::CLDR::Locales::Es::Any::Pa;
use ok Locale::CLDR::Locales::Es::Any::Pe;
use ok Locale::CLDR::Locales::Es::Any::Ph;
use ok Locale::CLDR::Locales::Es::Any::Pr;
use ok Locale::CLDR::Locales::Es::Any::Py;
use ok Locale::CLDR::Locales::Es::Any::Sv;
use ok Locale::CLDR::Locales::Es::Any::Us;
use ok Locale::CLDR::Locales::Es::Any::Uy;
use ok Locale::CLDR::Locales::Es::Any::Ve;
use ok Locale::CLDR::Locales::Es::Any;

done_testing();
