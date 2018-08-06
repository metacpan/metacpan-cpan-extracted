#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.33.0, Perl $], $^X" );
use ok Locale::CLDR::Locales::Es, 'Can use locale file Locale::CLDR::Locales::Es';
use ok Locale::CLDR::Locales::Es::Any::419, 'Can use locale file Locale::CLDR::Locales::Es::Any::419';
use ok Locale::CLDR::Locales::Es::Any::Ar, 'Can use locale file Locale::CLDR::Locales::Es::Any::Ar';
use ok Locale::CLDR::Locales::Es::Any::Bo, 'Can use locale file Locale::CLDR::Locales::Es::Any::Bo';
use ok Locale::CLDR::Locales::Es::Any::Br, 'Can use locale file Locale::CLDR::Locales::Es::Any::Br';
use ok Locale::CLDR::Locales::Es::Any::Bz, 'Can use locale file Locale::CLDR::Locales::Es::Any::Bz';
use ok Locale::CLDR::Locales::Es::Any::Cl, 'Can use locale file Locale::CLDR::Locales::Es::Any::Cl';
use ok Locale::CLDR::Locales::Es::Any::Co, 'Can use locale file Locale::CLDR::Locales::Es::Any::Co';
use ok Locale::CLDR::Locales::Es::Any::Cr, 'Can use locale file Locale::CLDR::Locales::Es::Any::Cr';
use ok Locale::CLDR::Locales::Es::Any::Cu, 'Can use locale file Locale::CLDR::Locales::Es::Any::Cu';
use ok Locale::CLDR::Locales::Es::Any::Do, 'Can use locale file Locale::CLDR::Locales::Es::Any::Do';
use ok Locale::CLDR::Locales::Es::Any::Ea, 'Can use locale file Locale::CLDR::Locales::Es::Any::Ea';
use ok Locale::CLDR::Locales::Es::Any::Ec, 'Can use locale file Locale::CLDR::Locales::Es::Any::Ec';
use ok Locale::CLDR::Locales::Es::Any::Es, 'Can use locale file Locale::CLDR::Locales::Es::Any::Es';
use ok Locale::CLDR::Locales::Es::Any::Gq, 'Can use locale file Locale::CLDR::Locales::Es::Any::Gq';
use ok Locale::CLDR::Locales::Es::Any::Gt, 'Can use locale file Locale::CLDR::Locales::Es::Any::Gt';
use ok Locale::CLDR::Locales::Es::Any::Hn, 'Can use locale file Locale::CLDR::Locales::Es::Any::Hn';
use ok Locale::CLDR::Locales::Es::Any::Ic, 'Can use locale file Locale::CLDR::Locales::Es::Any::Ic';
use ok Locale::CLDR::Locales::Es::Any::Mx, 'Can use locale file Locale::CLDR::Locales::Es::Any::Mx';
use ok Locale::CLDR::Locales::Es::Any::Ni, 'Can use locale file Locale::CLDR::Locales::Es::Any::Ni';
use ok Locale::CLDR::Locales::Es::Any::Pa, 'Can use locale file Locale::CLDR::Locales::Es::Any::Pa';
use ok Locale::CLDR::Locales::Es::Any::Pe, 'Can use locale file Locale::CLDR::Locales::Es::Any::Pe';
use ok Locale::CLDR::Locales::Es::Any::Ph, 'Can use locale file Locale::CLDR::Locales::Es::Any::Ph';
use ok Locale::CLDR::Locales::Es::Any::Pr, 'Can use locale file Locale::CLDR::Locales::Es::Any::Pr';
use ok Locale::CLDR::Locales::Es::Any::Py, 'Can use locale file Locale::CLDR::Locales::Es::Any::Py';
use ok Locale::CLDR::Locales::Es::Any::Sv, 'Can use locale file Locale::CLDR::Locales::Es::Any::Sv';
use ok Locale::CLDR::Locales::Es::Any::Us, 'Can use locale file Locale::CLDR::Locales::Es::Any::Us';
use ok Locale::CLDR::Locales::Es::Any::Uy, 'Can use locale file Locale::CLDR::Locales::Es::Any::Uy';
use ok Locale::CLDR::Locales::Es::Any::Ve, 'Can use locale file Locale::CLDR::Locales::Es::Any::Ve';
use ok Locale::CLDR::Locales::Es::Any, 'Can use locale file Locale::CLDR::Locales::Es::Any';

done_testing();
