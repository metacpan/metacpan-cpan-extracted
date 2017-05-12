#!/usr/bin/perl

use GD::Text::Arc;
use strict;
use warnings;
use Cwd;
use Test::More qw(no_plan);

my $image = GD::Image->new(600,500);

my $white = $image->colorAllocate(255,255,255);
my $gray =  $image->colorAllocate(75,75,75);
my $boldfont = getcwd . "/Adventure.ttf";
my $text = "here's a line.";

my $radius = 150;
my $centerX = 120;
my $centerY = 118;
my $size = 12;

# round 1: new with parameters

my $ta = GD::Text::Arc->new($image, 
                            colour => $gray,
                            ptsize => $size,
                            font => $boldfont,
                            radius => $radius,
                            center_x => $centerX,
                            center_y => $centerY,
                            text => $text, 
                            orientation => 'clockwise',
                            align => 'left',
                            angle => 1
                            );

ok( defined $ta,             "new( <parameters> ) returned something");
isa_ok( $ta, "GD::Text::Arc");
ok( $ta->draw,                            "  draw returned something");
is( $ta->get('colour'), $gray,            "  colour");
is( $ta->get('color'), $gray,             "  color");
is( $ta->get('ptsize'), $size,            "  ptsize");
is( $ta->get('font'), $boldfont,          "  font");
is( $ta->get('radius'), $radius,          "  radius");
is( $ta->get('center_x'), $centerX,       "  center_x");
is( $ta->get('center_y'), $centerY,       "  center_y");
is( $ta->get('text'), $text,              "  text");
is( $ta->get('orientation'), 'clockwise', "  orientation");
is( $ta->get('align'), 'left',            "  align");
is( $ta->get('angle'), 1,                 "  angle 1");

$ta->set('angle', 3.14);
is( $ta->get('angle'), 3.14,              "  angle 2");

$ta->set('angle', 'foo');
is( $ta->get('angle'), 3.14,              "  angle 3 was not a number; it's still angle 2");

# round 2: new without parameters

$ta = GD::Text::Arc->new($image);

ok( defined $ta,                     "new() returned something");
isa_ok( $ta, "GD::Text::Arc");
isnt( $ta->draw,0,                        "  draw returned FALSE");
is( $ta->get('colour'), $gray,            "  colour");
is( $ta->get('color'), $gray,             "  color");
is( $ta->get('ptsize'), 10,               "  ptsize");
is( $ta->get('font'), "",                 "  font");
is( $ta->get('radius'), 250,              "  radius");
is( $ta->get('center_x'), 300,            "  center_x");
is( $ta->get('center_y'), 250,            "  center_y");
is( $ta->get('text'), "",                 "  text");
is( $ta->get('orientation'), 'clockwise', " orientation");
is( $ta->get('align'), 'left',            "  align");
is( $ta->get('angle'), 0,                 "  angle 1");


# round 3: setting parameters

$ta->set('colour', $gray);
$ta->set('ptsize', $size);
$ta->set('font',   $boldfont);
$ta->set('radius', $radius);
$ta->set('center_x', $centerX);
$ta->set('center_y', $centerY);
$ta->set('text', $text);
$ta->set('orientation', 'counterclockwise');
$ta->set('align', 'right');
$ta->set('angle', 1);

ok( $ta->draw,                  "  draw returned something");
is( $ta->get('colour'), $gray,                   "  colour");
is( $ta->get('color'), $gray,                    "  color");
is( $ta->get('ptsize'), $size,                   "  ptsize");
is( $ta->get('font'), $boldfont,                 "  font");
is( $ta->get('radius'), $radius,                 "  radius");
is( $ta->get('center_x'), $centerX,              "  center_x");
is( $ta->get('center_y'), $centerY,              "  center_y");
is( $ta->get('text'), $text,                     "  text");   
is( $ta->get('orientation'), 'counterclockwise', " orientation");
is( $ta->get('align'), 'right',                  "  align");
is( $ta->get('angle'), 1,                        "  angle 1");

# round 4: inherited methods

$ta = GD::Text::Arc->new($image);
$ta->set_font($boldfont);
is( $ta->get('font'), $boldfont,                 "inherited: set_font");

$ta->gdGiantFont;
is( $ta->get('font'), $boldfont,                 "  still: set_font");

$ta->set_text($text);
is( $ta->get('text'), $text,                     "  text");

# round 5: true color image (without parameters)
# testing that color is set to (0,0,1)...

$image = GD::Image->new(600,500,1);

$white = $image->colorAllocate(255,255,255);
$gray =  $image->colorAllocate(75,75,75);

$ta = GD::Text::Arc->new($image);

ok( defined $ta,                     "new() returned something");
isa_ok( $ta, "GD::Text::Arc");
isnt( $ta->draw,0,                        "  draw returned FALSE");
is( $ta->get('colour'), 1,            "  colour");
is( $ta->get('color'), 1,             "  color");
is( $ta->get('ptsize'), 10,               "  ptsize");
is( $ta->get('font'), "",                 "  font");
is( $ta->get('radius'), 250,              "  radius");
is( $ta->get('center_x'), 300,            "  center_x");
is( $ta->get('center_y'), 250,            "  center_y");
is( $ta->get('text'), "",                 "  text");
is( $ta->get('orientation'), 'clockwise', " orientation");
is( $ta->get('align'), 'left',            "  align");
is( $ta->get('angle'), 0,                 "  angle 1");
