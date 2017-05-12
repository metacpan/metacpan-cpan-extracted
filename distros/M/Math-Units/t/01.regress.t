#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Math::Units;

my %good_results = (
    '100@ton@tonne'                           => 90.718474,      #--R--
    '10@ton@lb'                               => 20000,          #--R--
    '10@tonf@lbf'                             => 20000,          #--R--
    '50@N@lbf'                                => 11.24044715,    #--R--
    '9990@N@tonf'                             => 1.122920671,    #--R--
    '2000@rpm@Hz'                             => 33.33333333,    #--R--
    '2000@rpm@cycle/min'                      => 2000,           #--R--
    '2000@rpm@deg/sec'                        => 12000,          #--R--
    '87@jerk@N/kg sec'                        => 26.5176,        #--R--
    '123@jerk@N/kg sec'                       => 37.4904,        #--R--
    '12000@jerk@lbf/ton sec'                  => 745942.8041,    #--R--
    '123@meters per second per second@yd/s/s' => 134.5144357,    #--R--
    '123@5^2/m^2@25 m^-1/m'                   => 123,            #--R--
    '220@K@F'                                 => -63.67,         #--R--
    '20@C@F'                                  => 68,             #--R--
    '2@Cd@Fd'                                 => 3.6,            #--R--
    '1@m/Cd@in/Fd'                            => 21.87226597,    #--R--
    '1@m@in'                                  => 39.37007874,    #--R--
    '50@hectare@ft^2'                         => 5381955.208,    #--R--
    '1@m/s@ft/s'                              => 3.280839895,    #--R--
    '100@ft/sec@ft/min'                       => 6000,           #--R--
    '100@km/hr@mi/hr'                         => 62.13711922,    #--R--
    '1@Pa/Hz@Pa/kHz'                          => 1000,           #--R--
    '1@N@lb in/s^2'                           => 86.79616621,    #--R--
    '2789@in m@are'                           => 0.708406,       #--R--
    '1@hp@m N/s'                              => 745.6998716,    #--R--
    '1@m m@ft yd'                             => 3.587970139,    #--R--
    '1@l@qt'                                  => 1.056688209,    #--R--
    '8@ft lbf/s@W'                            => 10.84654359,    #--R--
    '89@kg/m m@lb/in ft'                      => 1.519053065,    #--R--
    '167@N@lbf'                               => 37.5430935,     #--R--
    '278@N^2@lbf^2'                           => 14.04985893,    #--R--
    '1@25 barrel^2@floz^2'                    => 722534400,      #--R--
    '0.1@F^-1@C^-1'                           => 32.18,          #--R--
    '1@m s^-1@ft s^-1'                        => 3.280839895,    #--R--
    '1@l@qt'                                  => 1.056688209,    #--R--
    '1@m^3@gal'                               => 264.1720524,    #--R--
    '100@in^3@qt'                             => 1.731601732,    #--R--
    '7001@cc@qt'                              => 7.397874154,    #--R--
    '1@m^6@l^2'                               => 1000000,        #--R--
    '786@m in@ft yd'                          => 71.63167104,    #--R--
    '786@m in@ft yd'                          => 71.63167104,    #--R--
    '1@lbf@N'                                 => 4.448221615,    #--R--
    '10@m/Cd@m/Fd'                            => 5.555555556,    #--R--
    '55550@angstroms@microns'                 => 5.555,          #--R--
    '5000000000000@angstroms@in'              => 19685.03937,    #--R--
    '9000@Hz@kHz'                             => 9,              #--R--
    '1@gal@in^3'                              => 231,            #--R--
    '10@gal@pnt^3'                            => 862202880,      #--R--
    '100@pnt^2@mm^2'                          => 12.44521605,    #--R--
    '9000000000@pnt@km'                       => 3175,           #--R--
    '100@ft@m'                                => 30.48,          #--R--
    '100@km/hr@mi/hr'                         => 62.13711922,    #--R--
    '100@ft/sec@ft/min'                       => 6000,           #--R--
    '100@ft/sec@m/sec'                        => 30.48,          #--R--
    '100@feet per second squared@ft/min^2'    => 360000,         #--R--
    '100@ft/sec@m/sec'                        => 30.48,          #--R--
    '1@N^2@g^2 km^2/s^4'                      => 1,              #--R--
    '17@N@lb in/s^2'                          => 1475.534826,    #--R--
    '212@F@C'                                 => 100,            #--R--
    '32@F@C'                                  => 0,              #--R--
    '70@F@C'                                  => 21.11111111,    #--R--
    '98.6@F@C'                                => 37,             #--R--
    '1e+20@cubic microns@cubic inches'        => 6102374.409,    #--R--
    '980@microns@milliinches'                 => 38.58267717,    #--R--
    '9700@microns@milli-inches'               => 381.8897638,    #--R--
    '8976@microns@m-in'                       => 353.3858268,    #--R--
    '4500@cc@l'                               => 4.5,            #--R--
    '500@in^3@l'                              => 8.193532,       #--R--
    '500@in^3@qt'                             => 8.658008658,    #--R--
    '17896@m^2/m m^3@in in/in^4'              => 11.54578336     #--R--
);

sub doit ($$$) {
    my ( $in_v, $in_u, $out_u ) = @_;

    my $good_v = $good_results{"$in_v\@$in_u\@$out_u"};
    my $out_v = Math::Units::convert( $in_v, $in_u, $out_u );

    ok( abs( $good_v - $out_v ) < 0.001, "$in_v $in_u -> $out_v $out_u" );
}

# The three common types of errors:
#
#eval {
#    doit(123, "(m/s)^2", "(in/s)^2");	# incorrect syntax
#};
#
#print $@;
#
#eval {
#    doit(123, "m", "m^2");		# incompatible units
#    doit(123, "in ft", "m yd ft");
#};
#
#print $@;
#
#eval {
#    doit(123, "foo", "m^2");		# unknown units
#};
#
#print $@;

for ( 1 .. 3 ) {

    doit( 100,  "ton",  "tonne" );
    doit( 10,   "ton",  "lb" );
    doit( 10,   "tonf", "lbf" );
    doit( 50,   "N",    "lbf" );
    doit( 9990, "N",    "tonf" );

    doit( 2000, "rpm", "Hz" );
    doit( 2000, "rpm", "cycle/min" );
    doit( 2000, "rpm", "deg/sec" );

    doit( 87,    "jerk", "N/kg sec" );
    doit( 123,   'jerk', 'N/kg sec' );
    doit( 12000, 'jerk', 'lbf/ton sec' );

    doit( 123,   "meters per second per second", "yd/s/s" );
    doit( 123,   "5^2/m^2",                      "25 m^-1/m" );
    doit( 220,   "K",                            "F" );
    doit( 20,    "C",                            "F" );
    doit( 2,     "Cd",                           "Fd" );
    doit( 1,     "m/Cd",                         "in/Fd" );
    doit( 1,     "m",                            "in" );
    doit( 50,    "hectare",                      "ft^2" );
    doit( 1,     "m/s",                          "ft/s" );
    doit( 100,   "ft/sec",                       "ft/min" );
    doit( 100,   "km/hr",                        "mi/hr" );
    doit( 1,     "Pa/Hz",                        "Pa/kHz" );
    doit( 1,     "N",                            "lb in/s^2" );
    doit( 2789,  "in m",                         "are" );
    doit( 1,     "hp",                           "m N/s" );
    doit( 1,     "m m",                          "ft yd" );
    doit( 1,     "l",                            "qt" );
    doit( 8,     "ft lbf/s",                     "W" );
    doit( 89,    "kg/m m",                       "lb/in ft" );
    doit( 167,   "N",                            "lbf" );
    doit( 278,   "N^2",                          "lbf^2" );
    doit( 1,     "25 barrel^2",                  "floz^2" );
    doit( 0.1,   "F^-1",                         "C^-1" );
    doit( 1,     "m s^-1",                       "ft s^-1" );
    doit( 1,     "l",                            "qt" );
    doit( 1,     "m^3",                          "gal" );
    doit( 100,   "in^3",                         "qt" );
    doit( 7001,  "cc",                           "qt" );
    doit( 1,     "m^6",                          "l^2" );
    doit( 786,   "m in",                         "ft yd" );
    doit( 786,   "m in",                         "ft yd" );
    doit( 1,     "lbf",                          "N" );
    doit( 10,    "m/Cd",                         "m/Fd" );
    doit( 55550, "angstroms",                    "microns" );
    doit( 5e12,  "angstroms",                    "in" );
    doit( 9000,  "Hz",                           "kHz" );
    doit( 1,     "gal",                          "in^3" );
    doit( 10,    "gal",                          "pnt^3" );
    doit( 100,   "pnt^2",                        "mm^2" );
    doit( 9e9,   "pnt",                          "km" );
    doit( 100,   "ft",                           "m" );
    doit( 100,   "km/hr",                        "mi/hr" );
    doit( 100,   "ft/sec",                       "ft/min" );
    doit( 100,   "ft/sec",                       "m/sec" );
    doit( 100,   "feet per second squared",      "ft/min^2" );
    doit( 100,   "ft/sec",                       "m/sec" );
    doit( 1,     "N^2",                          "g^2 km^2/s^4" );
    doit( 17,    "N",                            "lb in/s^2" );
    doit( 212,   "F",                            "C" );
    doit( 32,    "F",                            "C" );
    doit( 70,    "F",                            "C" );
    doit( 98.6,  "F",                            "C" );
    doit( 1e20,  "cubic microns",                "cubic inches" );
    doit( 980,   "microns",                      "milliinches" );
    doit( 9700,  "microns",                      "milli-inches" );
    doit( 8976,  "microns",                      "m-in" );
    doit( 4500,  "cc",                           "l" );
    doit( 500,   "in^3",                         "l" );
    doit( 500,   "in^3",                         "qt" );
    doit( 17896, "m^2/m m^3",                    "in in/in^4" );

}
