#!perl -T

use strict;
use warnings;
use Test::More tests => 99;
use Geo::WeatherNWS;

sub num_close {
    my ( $a, $b ) = @_;

    # are two floating point numbers close enough?
    return ( abs( $a - $b ) < 0.0001 );
}

#------------------------------------------------------------
# Test decoding a static observation (no network required)
#------------------------------------------------------------

my $report1 = new_ok('Geo::WeatherNWS');
my $obs1 =
  "2002/02/25 12:00 NSFA 251200Z 00000KT 50KM FEW024 SCT150 27/25 Q1010";
my $decode1 = $report1->decodeobs($obs1);

is( $decode1->{cloudcover}, 'Partly Cloudy', 'decoded cloud cover' );
is( $decode1->{cloudlevel_arrayref}[0], 'FEW024', 'decoded cloud level 1' );
is( $decode1->{cloudlevel_arrayref}[1], 'SCT150', 'decoded cloud level 2' );
is( $decode1->{code},                   'NSFA',   'decoded code (station)' );
is( $decode1->{conditionstext},    'Fair',   'decoded conditions in text' );
is( $decode1->{day},               '25',     'decoded day' );
is( $decode1->{dewpoint_c},        25,       'decoded dewpoint Celius' );
is( $decode1->{dewpoint_f},        77,       'decoded dewpoint Fahrenheit' );
is( $decode1->{heat_index_c},      31,       'decoded heat index Celius' );
is( $decode1->{heat_index_f},      87,       'decoded heat index Fahrenheit' );
is( $decode1->{obs},               $obs1,    'obs matched original' );
is( $decode1->{pressure_mb},       1010,     'decoded pressure mb' );
is( $decode1->{pressure_mmhg},     758,      'decoded pressure mm Hg' );
is( $decode1->{relative_humidity}, 89,       'decoded relative humidity' );
is( $decode1->{station_type},      'Manual', 'decoded station type' );
is( $decode1->{temperature_c},     27,       'decoded temperature Celius' );
is( $decode1->{temperature_f},     81,       'decoded temperature Fahrenheit' );
is( $decode1->{time},              '1200',   'decoded time' );
is( $decode1->{windchill_c},       undef,    'decoded windchill Celius' );
is( $decode1->{windchill_f},       undef,    'decoded windchill Fahrenheit' );
is( $decode1->{winddirtext},       'Calm',   'decoded wind direction' );
is( $decode1->{winddir},           0,        'decoded wind dir' );
is( $decode1->{windgustkts},       0,        'decoded wind gust knots' );
is( $decode1->{windgustmph},       0,        'decoded wind gust mph' );
is( $decode1->{windgustkmh},       0,        'decoded wind gust kmh' );
is( $decode1->{windspeedkts},      0,        'decoded wind speed knots' );
is( $decode1->{windspeedmph},      0,        'decoded wind speed mph' );
is( $decode1->{windspeedkmh},      0,        'decoded wind speed kmh' );
is( $decode1->{report_date},      '2002/02/25', 'report date' );
is( $decode1->{report_time},      '12:00',      'report time' );


ok( num_close( $decode1->{pressure_inhg}, 29.83 ),
    'decoded pressure inches Hg' );
ok( num_close( $decode1->{pressure_kgcm}, 1.030077628 ),
    'decoded pressure kg cm' );
ok( num_close( $decode1->{pressure_lbin}, 14.65112382 ),
    'decoded pressure lb in' );

is(
    $decode1->{directory},
    '/data/observations/metar/stations',
    'expected directory'
);
is( $decode1->{password}, 'weather@cpan.org', 'expected password' );
is( $decode1->{username}, 'anonymous',        'expected username' );

#------------------------------------------------------------
# Another example
#------------------------------------------------------------

my $report2 = Geo::WeatherNWS::new();
ok( defined($report2), 'Created second object' );

my $obs2 =
'2011/08/10 14:51 KSTL 101451Z 02003KT 10SM FEW080 SCT140 BKN200 24/16 A2991 RMK AO2 SLP115 T02440156 53005 ';
my $decode2 = $report2->decodeobs($obs2);

is( $decode2->{cloudcover}, 'Mostly Cloudy', 'decoded cloud cover' );
is( $decode2->{cloudlevel_arrayref}[0], 'FEW080', 'decoded cloud level 1' );
is( $decode2->{cloudlevel_arrayref}[1], 'SCT140', 'decoded cloud level 2' );
is( $decode2->{cloudlevel_arrayref}[2], 'BKN200', 'decoded cloud level 3' );
is( $decode2->{code},                   'KSTL',   'decoded code (station)' );
is( $decode2->{conditionstext},     'Fair',   'decoded conditions in text' );
is( $decode2->{day},                '10',     'decoded day' );
is( $decode2->{dewpoint_c},         16,       'decoded dewpoint Celius' );
is( $decode2->{dewpoint_f},         61,       'decoded dewpoint Fahrenheit' );
is( $decode2->{heat_index_c},       25,       'decoded heat index Celius' );
is( $decode2->{heat_index_f},       77,       'decoded heat index Fahrenheit' );
is( $decode2->{obs},                $obs2,    'obs matched original' );
is( $decode2->{pressure_mb},        1013,     'decoded pressure mb' );
is( $decode2->{pressure_mmhg},      760,      'decoded pressure mm Hg' );
is( $decode2->{relative_humidity},  61,       'decoded relative humidity' );
is( $decode2->{remark_arrayref}[0], 'RMK',    'decoded remark 1' );
is( $decode2->{remark_arrayref}[1], 'AO2',    'decoded remark 2' );
is( $decode2->{remark_arrayref}[2], '1011.5', 'decoded remark 3' );
is( $decode2->{remark_arrayref}[3], 'T02440156', 'decoded remark 4' );
is( $decode2->{remark_arrayref}[4], '53005',     'decoded remark 5' );
is( $decode2->{station_type},       'Automated', 'decoded station type' );
is( $decode2->{temperature_c},      24,          'decoded temperature Celius' );
is( $decode2->{temperature_f}, 75,      'decoded temperature Fahrenheit' );
is( $decode2->{time},          '1451',  'decoded time' );
is( $decode2->{windchill_c},   undef,   'decoded windchill Celius' );
is( $decode2->{windchill_f},   undef,   'decoded windchill Fahrenheit' );
is( $decode2->{winddirtext},   'North', 'decoded wind direction' );
is( $decode2->{winddir},       20,      'decoded wind dir' );
is( $decode2->{windgustkts},   0,       'decoded wind gust knots' );
is( $decode2->{windgustmph},   0,       'decoded wind gust mph' );
is( $decode2->{windgustkmh},   0,       'decoded wind gust kmh' );
is( $decode2->{windspeedkts},  3,       'decoded wind speed knots' );
is( $decode2->{windspeedmph},  3,       'decoded wind speed mph' );
is( $decode2->{windspeedkmh},  6,       'decoded wind speed kmh' );

ok( num_close( $decode2->{pressure_inhg}, 29.91 ),
    'decoded pressure inches Hg' );
ok( num_close( $decode2->{pressure_kgcm}, 1.032840156 ),
    'decoded pressure kg cm' );
ok( num_close( $decode2->{pressure_lbin}, 14.69041614 ),
    'decoded pressure lb in' );

#------------------------------------------------------------
# Test for Bug #14632 from dstroma
# 
# "Conditions do not get parsed if there is no intensity modified,
# ie -TSRA works, +TSRA works, but TSRA doesn't."
#------------------------------------------------------------

my $obs3_start = "2012/11/24 00:20 KPIT 091955Z COR 22015G25KT 3/4SM R28L/2600FT ";
my $obs3_end = " OVC010CB 18/16 A2992 RMK SLP045 T01820159";
my @obs3_middle = ('TSRA','-TSRA','+TSRA');
my @obs3_description = ('Thunderstorm Rain', 'Light Thunderstorm Rain', 'Heavy Thunderstorm Rain');
for (my $obs3_case=0; $obs3_case<=$#obs3_middle; $obs3_case++) {
    my $abbr3 = $obs3_middle[$obs3_case];
    my $expected3 = $obs3_description[$obs3_case];
    my $obs3 = $obs3_start . $abbr3 . $obs3_end;
    my $report3 = Geo::WeatherNWS::new();
    my $decode3 = $report3->decodeobs($obs3);
    # Check for the ICAO here because unmodified TSRA was put there in error.
    is($decode3->{code}, 'KPIT', "code for $abbr3");
    is($decode3->{conditionstext}, $expected3, "conditionstext for $abbr3");
    is($decode3->{conditions1}, 'Thunderstorm', "conditions1 for $abbr3");
    is($decode3->{conditions2}, 'Rain', "conditions2 for $abbr3");
}

#------------------------------------------------------------
# Make sure freezing fog is handled correctly
#------------------------------------------------------------

my $obs4_start = "2012/11/24 00:20 KPIT 091955Z COR 22015G25KT 3/4SM R28L/2600FT ";
my $obs4_end = " OVC010CB 18/16 A2992 RMK SLP045 T01820159";
my @obs4_middle = ('FZFG','-FZFG','+FZFG');
my @obs4_description = ('Freezing Fog', 'Light Freezing Fog', 'Heavy Freezing Fog');
for (my $obs4_case=0; $obs4_case<=$#obs4_middle; $obs4_case++) {
    my $abbr4 = $obs4_middle[$obs4_case];
    my $expected4 = $obs4_description[$obs4_case];
    my $obs4 = $obs4_start . $abbr4 . $obs4_end;
    my $report4 = Geo::WeatherNWS::new();
    my $decode4 = $report4->decodeobs($obs4);
    # Check for the ICAO here because unmodified FZFG was put there in error.
    is($decode4->{code}, 'KPIT', "code for $abbr4");
    is($decode4->{conditionstext}, $expected4, "conditionstext for $abbr4");
    is($decode4->{conditions1}, 'Freezing', "conditions1 for $abbr4");
    is($decode4->{conditions2}, 'Fog', "conditions2 for $abbr4");
}
