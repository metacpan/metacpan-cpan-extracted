#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.46.0, Perl $], $^X" );
use ok 'Locale::CLDR::Locales::Es';
use ok 'Locale::CLDR::Locales::Es::Latn::419';
use ok 'Locale::CLDR::Locales::Es::Latn::Ar';
use ok 'Locale::CLDR::Locales::Es::Latn::Bo';
use ok 'Locale::CLDR::Locales::Es::Latn::Br';
use ok 'Locale::CLDR::Locales::Es::Latn::Bz';
use ok 'Locale::CLDR::Locales::Es::Latn::Cl';
use ok 'Locale::CLDR::Locales::Es::Latn::Co';
use ok 'Locale::CLDR::Locales::Es::Latn::Cr';
use ok 'Locale::CLDR::Locales::Es::Latn::Cu';
use ok 'Locale::CLDR::Locales::Es::Latn::Do';
use ok 'Locale::CLDR::Locales::Es::Latn::Ea';
use ok 'Locale::CLDR::Locales::Es::Latn::Ec';
use ok 'Locale::CLDR::Locales::Es::Latn::Es';
use ok 'Locale::CLDR::Locales::Es::Latn::Gq';
use ok 'Locale::CLDR::Locales::Es::Latn::Gt';
use ok 'Locale::CLDR::Locales::Es::Latn::Hn';
use ok 'Locale::CLDR::Locales::Es::Latn::Ic';
use ok 'Locale::CLDR::Locales::Es::Latn::Mx';
use ok 'Locale::CLDR::Locales::Es::Latn::Ni';
use ok 'Locale::CLDR::Locales::Es::Latn::Pa';
use ok 'Locale::CLDR::Locales::Es::Latn::Pe';
use ok 'Locale::CLDR::Locales::Es::Latn::Ph';
use ok 'Locale::CLDR::Locales::Es::Latn::Pr';
use ok 'Locale::CLDR::Locales::Es::Latn::Py';
use ok 'Locale::CLDR::Locales::Es::Latn::Sv';
use ok 'Locale::CLDR::Locales::Es::Latn::Us';
use ok 'Locale::CLDR::Locales::Es::Latn::Uy';
use ok 'Locale::CLDR::Locales::Es::Latn::Ve';
use ok 'Locale::CLDR::Locales::Es::Latn';

done_testing();
