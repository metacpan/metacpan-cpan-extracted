#!/usr/bin/perl
#
use v5.12;
use warnings;
use Test::More tests => 62;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color qw/color/;

my $red = Graphics::Toolkit::Color->new('#FF0000');
my $white = Graphics::Toolkit::Color->new('white');
my $black = Graphics::Toolkit::Color->new('black');


is( $black->gradient( to => $white, steps => 1 )->name, 'black','shortest gradient is $self');
my @g = $black->gradient_to( $white, 2 );
is( int @g,                                                2,   'gradient with length 2 has only boundary cases');
is( $g[0]->name,                                     'black',   'gradient with length 2 starts on left boundary');
is( $g[1]->name,                                     'white',   'gradient with length 2 ends on right boundary');
@g = $black->gradient_to( $white, 6 );
is( int @g,                                                6,   'gradient has right length = 6');
is( $g[1]->name,                                     'gray20',  'grey20 is between black and white');
is( $g[2]->name,                                     'gray40',  'grey40 is between black and white');
@g = $black->gradient_to( $white, 3, 0 );
is( int @g,                                                3,   'gradient has right length = 3');
is( $g[1]->name,                                     'gray',    'gray aka grey50  is between black and white in none linear gradient');
@g = $black->gradient_to( $white, 3, -1.4 );
is( $g[1]->name,                                     'gray75',  'grey75 is between black and white in none linear gradient');
@g = $red->gradient( to=>'#0000FF', steps => 3, in => 'RGB' );
is( $g[1]->name,                                    'purple',   'purple is between red and blue in RGB');

@g = $black->complement();
is( int @g,                                                 1,   "default is one complementary color");
is( $black->complementary()->name,                    'black',   "black has no complementary color");
is( $white->complementary()->name,                    'white',   "white has no complementary color");
is( $red->complementary()->name,                       'aqua',   "aqua is complementary to red");

@g = $red->complement(steps => 3);
is( int @g,                                                 3,   "requested amount of complementary colors");
is( ($g[0]->values('HSL'))[1],      ($g[1]->values('HSL'))[1],   "saturation is equal on complementary circle");
is( ($g[1]->values('HSL'))[1],      ($g[2]->values('HSL'))[1],   "saturation is equal on complementary circle 2");
is( ($g[0]->values('HSL'))[2],      ($g[1]->values('HSL'))[2],   "lightness is equal on complementary circle");
is( ($g[1]->values('HSL'))[2],      ($g[2]->values('HSL'))[2],   "lightness is equal on complementary circle 2");
is( $g[0]->name,                                        'red',   "complementary circle starts with C1");
is( $g[1]->name,                                       'lime',   "complementary gos on to green");
is( $g[2]->name,                                       'blue',   "complementary circle ends with blue");

@g = Graphics::Toolkit::Color->new(15,12,13)->complement( steps =>  3);
my @hsl0 = $g[0]->values('HSL');
my @hsl1 = $g[1]->values('HSL');
my @hsl2 = $g[2]->values('HSL');
is( $hsl0[1],                                $hsl1[1],   "saturation is equal on complementary circle of random color");
is( $hsl1[1],                                $hsl2[1],   "saturation is equal on complementary circle 2");
is( $hsl0[2],                                $hsl1[2],   "lightness is equal on complementary circle of random color");
is( $hsl1[2],                                $hsl2[2],   "lightness is equal on complementary circle 2");

@g = Graphics::Toolkit::Color->new(15,12,13)->complement( steps => 4, s => 12, l => 20 );

is( int @g,                                                 4,   "requested amount of complementary colors");
is( ($g[1]->values('HSL'))[0]+270,   ($g[0]->values('HSL'))[0],  "first hue value has expected 90 degree angle");
is( ($g[2]->values('HSL'))[0]+180,   ($g[0]->values('HSL'))[0],  "second hue value has expected 180 degree angle");
is( ($g[3]->values('HSL'))[0]+ 90,   ($g[0]->values('HSL'))[0],  "third hue value has expected 270 degree angle");
is( ($g[0]->values('HSL'))[1],       ($g[2]->values('HSL'))[1],  "tilted saturation still undisturbed on positions 0 and 2");
is( ($g[0]->values('HSL'))[2],       ($g[2]->values('HSL'))[2],  "tilted lightness still undisturbed on positions 0 and 2");
is( ($g[1]->values('HSL'))[1]-12,    ($g[0]->values('HSL'))[1],  "saturation om Dmax has expected value");
is( ($g[1]->values('HSL'))[2]-20,    ($g[0]->values('HSL'))[2],  "lightness om Dmax has expected value");
is( ($g[3]->values('HSL'))[1],                               0,  "saturation om Dmin got to absolute minimum");
is( ($g[3]->values('HSL'))[2],                               0,  "lightness om Dmin got to absolute minimum");


@g = Graphics::Toolkit::Color->new(15,12,13)->complement( steps => 7, hue_tilt => 40,
                                                                      saturation_tilt => { s => 5, h => -30 },
                                                                      lightness_tilt => { l =>  20, h => 50 });
is( int @g,                                                 7,   "requested amount of complementary colors");
my @hsl = map {[$g[$_]->values('HSL')]} 0 .. 6;
is( int @g,                                                 7,   "amount is right");
is( $hsl[3][0] < 200,         1,   "first three colors are before Dmax");
is( $hsl[4][0] > 200,         1,   "second three colors are after Dmax");
is( $hsl[0][0],             340,   "C1 hue did not move");
is( $hsl[1][0],              38,   "second color hue is correct");
is( $hsl[2][0],             108,   "third color hue is correct");
is( $hsl[3][0],             173,   "fourth color hue is correct");
is( $hsl[4][0],             224,   "5. color hue is correct");
is( $hsl[5][0],             262,   "6. color hue is correct");
is( $hsl[6][0],             295,   "7. color hue is correct");

is( $hsl[0][1],              13,   "saturation of 1. color");
is( $hsl[1][1],              16,   "saturation of 2. color");
is( $hsl[2][1],              14,   "saturation of 3. color");
is( $hsl[3][1],              11,   "saturation of 4. color");
is( $hsl[4][1],               8,   "saturation of 5. color");
is( $hsl[5][1],               7,   "saturation of 6. color");
is( $hsl[6][1],              10,   "saturation of 7. color");

is( $hsl[0][2],               0,   "C1 hue did not move");
is( $hsl[1][2],               5,   "second color hue is correct");
is( $hsl[2][2],              17,   "third color hue is correct");
is( $hsl[3][2],              22,   "fourth color hue is correct");
is( $hsl[4][2],              10,   "5. color hue is correct");
is( $hsl[5][2],               0,   "6. color hue is correct");
is( $hsl[6][2],               0,   "7. color hue is correct");

exit 0;
