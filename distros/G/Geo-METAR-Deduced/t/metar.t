#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2021, Roland van Ipenburg
use strict;
use warnings;
use utf8;
use 5.014000;

use Test::More;
use Test::NoWarnings;

our $VERSION = 'v1.0.3';

use Geo::METAR::Deduced;

## no critic (ProhibitMagicNumbers)
Test::More::plan 'tests' => (52) + 1;
## use critic

my $m = Geo::METAR::Deduced->new();
$m->debug(1);
$m->metar(
## no critic (ProhibitImplicitNewlines)
    q{EHAM 051355Z 09006G07KT 030V060 9000 -SHSN FEW015 FEW020CB
03/M01 Q1012 NOSIG=},
## use critic
);
## no critic (ProhibitMagicNumbers)
Test::More::is( $m->SITE,         q{EHAM}, q{Site direct from METAR} );
Test::More::is( $m->site,         q{EHAM}, q{Site deduced} );
Test::More::is( $m->DATE,         q{05},   q{Date direct from METAR} );
Test::More::is( $m->date,         5,       q{Date deduced} );
Test::More::is( $m->MOD,          q{AUTO}, q{Modifier direct from METAR} );
Test::More::is( $m->WIND_DIR_DEG, q{090}, q{Wind direction direct from METAR} );
Test::More::is( $m->wind_dir->deg, 90,    q{Wind direction deduced} );
Test::More::is( $m->WIND_VAR_1, q{030},
    q{Wind direction low direct from METAR} );
Test::More::is( $m->wind_low->deg, 30, q{Wind direction low deduced} );
Test::More::is( $m->WIND_VAR_2, q{060},
    q{Wind direction high direct from METAR} );
Test::More::is( $m->wind_high->deg, 60,    q{Wind direction high deduced} );
Test::More::is( $m->WIND_KTS,       q{06}, q{Wind speed direct from METAR} );
Test::More::is( $m->wind_speed->kn, 6,     q{Wind speed deduced} );
Test::More::is( $m->TEMP_C,         q{03}, q{Temperature direct from METAR} );
Test::More::is( $m->temp->C,        3,     q{Temperature deduced} );
Test::More::is( $m->DEW_C,  q{-01}, q{Dew temperature direct from METAR} );
Test::More::is( $m->dew->C, -1,     q{Dew temperature deduced} );

$m->metar(q{KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014});
Test::More::is( $m->SITE,   q{KFDY} );
Test::More::is( $m->DATE,   q{25} );
Test::More::is( $m->MOD,    q{AUTO} );
Test::More::is( $m->TEMP_F, q{39.2} );

$m->metar(
        q{EHLE 261325Z AUTO 27022KT 240V300 3200 -DZ FEW007 SCT010 BKN014 }
      . q{17/15 Q1007 REDZ TEMPO 4500 RADZ BKN014},
);
Test::More::is( $m->SITE,    q{EHLE} );
Test::More::is( $m->DATE,    26 );
Test::More::is( $m->MOD,     q{AUTO} );
Test::More::is( $m->drizzle, 1 );

$m->metar(
        q{EHDL 261325Z AUTO 25014G24KT 210V360 3000 R20/P3000D +SHRA FEW007 }
      . q{SCT011 BKN014 17/16 Q1009 YLO},
);
Test::More::is( $m->SITE, q{EHDL} );
Test::More::is( $m->DATE, 26 );
Test::More::is( $m->MOD,  q{AUTO} );

#Test::More::is( $m->showers, 3 );
#Test::More::is( $m->rain, 2 );

$m->metar(
        q{EHLE 261355Z AUTO 27021G31KT 240V300 9000 FEW009 SCT013 }
      . q{BKN016 17/15 Q1008 TEMPO 4500 RADZ},
);
Test::More::is( $m->SITE,        q{EHLE} );
Test::More::is( $m->DATE,        26 );
Test::More::is( $m->MOD,         q{AUTO} );
Test::More::is( $m->flight_rule, 2 );

# Made up METARs for testing coverage:
$m->metar(q{EHLE 261355Z AUTO VRB02KT 1000 +RA OVC006 17/15 Q1008});
Test::More::is( $m->wind_var,        0 );
Test::More::is( $m->wind_low,        undef );
Test::More::is( $m->wind_high,       undef );
Test::More::is( $m->wind_gust->kn(), 0 );
Test::More::is( $m->flight_rule,     0 );
Test::More::is( $m->rain,            3 );

$m->metar(q{EHLE 261355Z AUTO 18002KT 1000 -RA OVC006 17/15 Q1008});
Test::More::is( $m->wind_var, 0 );
Test::More::is( $m->rain,     1 );

$m->metar(q{EHLE 261355Z AUTO 18002KT 1000 -DZ OVC006 17/15 Q1008});
Test::More::is( $m->rain,    0 );
Test::More::is( $m->DATE,    q{26} );
Test::More::is( $m->MOD,     q{AUTO} );
Test::More::is( $m->drizzle, q{1} );

$m->metar( q{EHDL 261325Z AUTO 25014G24KT 210V360 3000 R20/P3000D +RA }
      . q{FEW007 SCT011 BKN014 17/16 Q1009 YLO} );
Test::More::is( $m->SITE, q{EHDL} );
Test::More::is( $m->DATE, q{26} );
Test::More::is( $m->MOD,  q{AUTO} );
Test::More::is( $m->rain, q{3} );

$m->metar(
        q{EHLE 261355Z AUTO 27021G31KT 240V300 9000 FEW009 SCT013 BKN016 }
      . q{17/15 Q1008 TEMPO 4500 RADZ} );
Test::More::is( $m->SITE,        q{EHLE} );
Test::More::is( $m->DATE,        q{26} );
Test::More::is( $m->MOD,         q{AUTO} );
Test::More::is( $m->flight_rule, q{2} );
## use critic
