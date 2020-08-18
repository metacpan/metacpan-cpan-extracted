use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

require Geo::METAR::Deduced;
my $m = Geo::METAR::Deduced->new();
my $METAR;

plan tests => 1 + 20;

$METAR =
'EHRD 261925Z AUTO 30003G20 260V330 9999 TS FEW015CB BKN049 22/19 Q1009 BECMG NSW';
$m->metar($METAR);
is( $m->site(),                            q{EHRD},      q{Site} );
is( $m->date(),                            26,           q{Date} );
is( $m->time(),                            q{19:25 UTC}, q{Time} );
is( $m->mode(),                            q{AUTO},      q{Modifier} );
is( $m->wind_dir()->deg(),                 300,          q{Wind dir} );
is( $m->wind_dir_eng(),                    q{Northwest}, q{Wind dir name} );
is( $m->wind_dir_abb(),                    q{NW},        q{Wind dir abbr} );
is( $m->wind_speed()->kn(),                3,            q{Wind speed} );
is( $m->wind_gust()->kn(),                 20,           q{Wind gust} );
is( $m->wind_var(),                        1,            q{Wind varying} );
is( $m->wind_low()->deg(),                 260,          q{Wind var low} );
is( $m->wind_high()->deg(),                330,          q{Wind var high} );
is( $m->visibility()->m(),                 9999,         q{Visibility} );
is( $m->thunderstorm(),                    2,            q{Thunderstorm} );
is( $m->ceiling()->ft(),                   4900,         q{Ceiling} );
is( $m->flight_rule(),                     3,            q{Flight rule} );
is( $m->temp()->C(),                       22,           q{Temp} );
is( $m->dew()->C(),                        19,           q{Dew} );
is( sprintf( q{%.0f}, $m->alt()->inHg() ), 30,           q{Altimeter} );
is( $m->pressure()->pa(),                  100900,       q{Pressure} );

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
