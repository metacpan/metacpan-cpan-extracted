#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ar, 'Can use locale file Locale::CLDR::Locales::Ar';
use ok Locale::CLDR::Locales::Ar::Any::001, 'Can use locale file Locale::CLDR::Locales::Ar::Any::001';
use ok Locale::CLDR::Locales::Ar::Any::Ae, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Ae';
use ok Locale::CLDR::Locales::Ar::Any::Bh, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Bh';
use ok Locale::CLDR::Locales::Ar::Any::Dj, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Dj';
use ok Locale::CLDR::Locales::Ar::Any::Dz, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Dz';
use ok Locale::CLDR::Locales::Ar::Any::Eg, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Eg';
use ok Locale::CLDR::Locales::Ar::Any::Eh, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Eh';
use ok Locale::CLDR::Locales::Ar::Any::Er, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Er';
use ok Locale::CLDR::Locales::Ar::Any::Il, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Il';
use ok Locale::CLDR::Locales::Ar::Any::Iq, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Iq';
use ok Locale::CLDR::Locales::Ar::Any::Jo, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Jo';
use ok Locale::CLDR::Locales::Ar::Any::Km, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Km';
use ok Locale::CLDR::Locales::Ar::Any::Kw, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Kw';
use ok Locale::CLDR::Locales::Ar::Any::Lb, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Lb';
use ok Locale::CLDR::Locales::Ar::Any::Ly, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Ly';
use ok Locale::CLDR::Locales::Ar::Any::Ma, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Ma';
use ok Locale::CLDR::Locales::Ar::Any::Mr, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Mr';
use ok Locale::CLDR::Locales::Ar::Any::Om, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Om';
use ok Locale::CLDR::Locales::Ar::Any::Ps, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Ps';
use ok Locale::CLDR::Locales::Ar::Any::Qa, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Qa';
use ok Locale::CLDR::Locales::Ar::Any::Sa, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Sa';
use ok Locale::CLDR::Locales::Ar::Any::Sd, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Sd';
use ok Locale::CLDR::Locales::Ar::Any::So, 'Can use locale file Locale::CLDR::Locales::Ar::Any::So';
use ok Locale::CLDR::Locales::Ar::Any::Ss, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Ss';
use ok Locale::CLDR::Locales::Ar::Any::Sy, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Sy';
use ok Locale::CLDR::Locales::Ar::Any::Td, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Td';
use ok Locale::CLDR::Locales::Ar::Any::Tn, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Tn';
use ok Locale::CLDR::Locales::Ar::Any::Ye, 'Can use locale file Locale::CLDR::Locales::Ar::Any::Ye';
use ok Locale::CLDR::Locales::Ar::Any, 'Can use locale file Locale::CLDR::Locales::Ar::Any';

done_testing();
