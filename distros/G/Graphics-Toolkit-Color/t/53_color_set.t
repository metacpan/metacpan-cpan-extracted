#!/usr/bin/perl
#
use v5.12;
use warnings;
use Test::More tests => 44;
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

@g = $red->complement(3);
is( int @g,                                                 3,   "requested amount of complementary colors");
is( $g[0]->saturation,                      $g[1]->saturation,   "saturation is equal on complementary circle");
is( $g[1]->saturation,                      $g[2]->saturation,   "saturation is equal on complementary circle 2");
is( $g[0]->lightness,                        $g[1]->lightness,   "lightness is equal on complementary circle");
is( $g[1]->lightness,                        $g[2]->lightness,   "lightness is equal on complementary circle 2");
is( $g[0]->name,                                        'red',   "complementary circle starts with C1");
is( $g[1]->name,                                       'lime',   "complementary gos on to green");
is( $g[2]->name,                                       'blue',   "complementary circle ends with blue");

@g = Graphics::Toolkit::Color->new(15,12,13)->complement(3);
is( $g[0]->saturation,                       $g[1]->saturation,  "saturation is equal on complementary circle of random color");
is( $g[1]->saturation,                       $g[2]->saturation,  "saturation is equal on complementary circle 2");
is( $g[0]->lightness,                        $g[1]->lightness,   "lightness is equal on complementary circle of random color");
is( $g[1]->lightness,                        $g[2]->lightness,   "lightness is equal on complementary circle 2");

@g = Graphics::Toolkit::Color->new(15,12,13)->complement(4, 12, 20);
is( int @g,                                                 4,   "requested amount of complementary colors");
is( $g[1]->saturation,                       $g[3]->saturation,  "saturation is equal on opposing sides of skewed circle");
is( $g[1]->lightness,                        $g[3]->lightness,   "lightness is equal on opposing sides of skewed circle");
is( $g[1]->saturation-6,                     $g[0]->saturation,  "saturation moves on skewed circle as predicted fore ");
is( $g[1]->saturation+6,                     $g[2]->saturation,  "saturation moves on skewed circle as predicted back");
is( $g[1]->lightness-10,                     $g[0]->lightness,   "lightness moves on skewed circle as predicted fore");
is( $g[1]->lightness+10,                     $g[2]->lightness,   "lightness moves on skewed circle as predicted back");

@g = Graphics::Toolkit::Color->new(15,12,13)->complement(4, 512, 520);
is( abs($g[0]->saturation-$g[2]->saturation) < 100,         1,   "cut too large saturnation skews");
is( abs($g[0]->lightness-$g[2]->lightness) < 100,           1,   "cut too large lightness skews");

@g = Graphics::Toolkit::Color->new(15,12,13)->complement(5, 10, 20);
is( $g[1]->saturation,                      $g[4]->saturation,   "saturation is equal on opposing sides of odd and skewed circle 1");
is( $g[2]->saturation,                      $g[3]->saturation,   "saturation is equal on opposing sides of odd and skewed circle 2");
is( $g[1]->lightness,                       $g[4]->lightness,    "lightness is equal on opposing sides of odd and skewed circle 1");
is( $g[2]->lightness,                       $g[3]->lightness,    "lightness is equal on opposing sides of odd and skewed circle 2");
is( $g[1]->saturation-4,                    $g[0]->saturation,   "saturation moves on odd and skewed circle as predicted fore ");
is( $g[1]->saturation+4,                    $g[2]->saturation,   "saturation moves on odd and skewed circle as predicted back");
is( $g[1]->lightness -8,                    $g[0]->lightness,    "lightness moves on odd and skewed circle as predicted fore");
is( $g[1]->lightness +8,                    $g[2]->lightness,    "lightness moves on odd and skewed circle as predicted back");


exit 0;
