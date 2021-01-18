use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

use Geo::METAR::Deduced;

plan tests => (35) + 1;

my $m = new Geo::METAR::Deduced;

$m->metar(q{KFDY 251450Z 21012G21KT 8SM OVC065 04/M01 A3010 RMK 57014});
is( $m->SITE,   q{KFDY} );
is( $m->DATE,   q{25} );
is( $m->MOD,    q{AUTO} );
is( $m->TEMP_F, q{39.2} );

$m->metar(q{EHLE 261325Z AUTO 27022KT 240V300 3200 -DZ FEW007 SCT010 BKN014 17/15 Q1007 REDZ TEMPO 4500 RADZ BKN014});
is( $m->SITE,   q{EHLE} );
is( $m->DATE,   26 );
is( $m->MOD,    q{AUTO} );
is( $m->drizzle, 1 );

$m->metar(q{EHDL 261325Z AUTO 25014G24KT 210V360 3000 R20/P3000D +SHRA FEW007 SCT011 BKN014 17/16 Q1009 YLO});
is( $m->SITE,   q{EHDL} );
is( $m->DATE,   26 );
is( $m->MOD,    q{AUTO} );
#is( $m->showers, 3 );
#is( $m->rain, 2 );

$m->metar(q{EHLE 261355Z AUTO 27021G31KT 240V300 9000 FEW009 SCT013 BKN016 17/15 Q1008 TEMPO 4500 RADZ});
is( $m->SITE,   q{EHLE} );
is( $m->DATE,   26 );
is( $m->MOD,    q{AUTO} );
is( $m->flight_rule, 2 );

# Made up METARs for testing coverage:
$m->metar(q{EHLE 261355Z AUTO VRB02KT 1000 +RA OVC006 17/15 Q1008});
is( $m->wind_var, 0 );
is( $m->wind_low, undef );
is( $m->wind_high, undef );
is( $m->wind_gust->kn(), 0 );
is( $m->flight_rule, 0 );
is( $m->rain, 3 );

$m->metar(q{EHLE 261355Z AUTO 18002KT 1000 -RA OVC006 17/15 Q1008});
is( $m->wind_var, 0 );
is( $m->rain, 1 );

$m->metar(q{EHLE 261355Z AUTO 18002KT 1000 -DZ OVC006 17/15 Q1008});
is( $m->rain, 0 );
is( $m->DATE,   q{26} );
is( $m->MOD,    q{AUTO} );
is( $m->drizzle, q{1} );

$m->metar(q{EHDL 261325Z AUTO 25014G24KT 210V360 3000 R20/P3000D +RA FEW007 SCT011 BKN014 17/16 Q1009 YLO});
is( $m->SITE,   q{EHDL} );
is( $m->DATE,   q{26} );
is( $m->MOD,    q{AUTO} );
is( $m->rain, q{3} );

$m->metar(q{EHLE 261355Z AUTO 27021G31KT 240V300 9000 FEW009 SCT013 BKN016 17/15 Q1008 TEMPO 4500 RADZ});
is( $m->SITE,   q{EHLE} );
is( $m->DATE,   q{26} );
is( $m->MOD,    q{AUTO} );
is( $m->flight_rule, q{2} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
