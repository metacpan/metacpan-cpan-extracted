#!perl -T
use Test::More;
use Test::Exception;
use ok( 'Locale::CLDR' );
my $locale;

diag( "Testing Locale::CLDR v0.34.4, Perl $], $^X" );
use ok Locale::CLDR::Locales::Ar;
use ok Locale::CLDR::Locales::Ar::Any::001;
use ok Locale::CLDR::Locales::Ar::Any::Ae;
use ok Locale::CLDR::Locales::Ar::Any::Bh;
use ok Locale::CLDR::Locales::Ar::Any::Dj;
use ok Locale::CLDR::Locales::Ar::Any::Dz;
use ok Locale::CLDR::Locales::Ar::Any::Eg;
use ok Locale::CLDR::Locales::Ar::Any::Eh;
use ok Locale::CLDR::Locales::Ar::Any::Er;
use ok Locale::CLDR::Locales::Ar::Any::Il;
use ok Locale::CLDR::Locales::Ar::Any::Iq;
use ok Locale::CLDR::Locales::Ar::Any::Jo;
use ok Locale::CLDR::Locales::Ar::Any::Km;
use ok Locale::CLDR::Locales::Ar::Any::Kw;
use ok Locale::CLDR::Locales::Ar::Any::Lb;
use ok Locale::CLDR::Locales::Ar::Any::Ly;
use ok Locale::CLDR::Locales::Ar::Any::Ma;
use ok Locale::CLDR::Locales::Ar::Any::Mr;
use ok Locale::CLDR::Locales::Ar::Any::Om;
use ok Locale::CLDR::Locales::Ar::Any::Ps;
use ok Locale::CLDR::Locales::Ar::Any::Qa;
use ok Locale::CLDR::Locales::Ar::Any::Sa;
use ok Locale::CLDR::Locales::Ar::Any::Sd;
use ok Locale::CLDR::Locales::Ar::Any::So;
use ok Locale::CLDR::Locales::Ar::Any::Ss;
use ok Locale::CLDR::Locales::Ar::Any::Sy;
use ok Locale::CLDR::Locales::Ar::Any::Td;
use ok Locale::CLDR::Locales::Ar::Any::Tn;
use ok Locale::CLDR::Locales::Ar::Any::Ye;
use ok Locale::CLDR::Locales::Ar::Any;

done_testing();
