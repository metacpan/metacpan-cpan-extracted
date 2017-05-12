#!/usr/bin/perl

=head1 NAME

GD-Graph-Cartesian-example.pl - GD::Graph::Cartesian general example

=cut

use strict;
use warnings;
use GD::Graph::Cartesian;
use GD qw{}; #provides GD::Font

my $obj=GD::Graph::Cartesian->new(height=>400, width=>800);
$obj->addRectangle(0=>0, 90=>160, [255,255,255]);
my $x=5;
my $y=5;

foreach my $color ([0,255,255], [0,255,0], [255,255,0], [255,192,203], [255,0,0], [2550,165,0], [0,0,255], [0,0,0], [190,190,190]) {
  $y+=10;
  #explict color array reference
  $obj->addPoint($x=>$y, $color);
  $obj->addLine($x=>$y, $x+15=>$y, $color);
  $obj->addString($x=>$y, "Color: @$color", $color);
}

$x+=20;
$y=5;
foreach my $color (qw{cyan green yellow pink red orange blue black gray}) {
  $y+=10;
  #explict color name
  $obj->addPoint($x=>$y, $color);
  $obj->addLine($x=>$y, $x+15=>$y, $color);
  $obj->addString($x=>$y, "Color: $color", $color);
}

$x+=20;
$y=5;
foreach my $color ([0,255,255], [0,255,0], [255,255,0], [255,192,203], [255,0,0], [2550,165,0], [0,0,255], [0,0,0], [190,190,190]) {
  $y+=10;
  #implict color array reference
  $obj->color($color);
  $obj->addPoint($x=>$y);
  $obj->addLine($x=>$y, $x+15=>$y);
  $obj->addString($x=>$y, "Color: @$color");
}

$x+=20;
$y=5;
foreach my $color (qw{cyan green yellow pink red orange blue black gray}) {
  $y+=10;
  #implict color name
  $obj->color($color);
  $obj->addPoint($x=>$y);
  $obj->addLine($x=>$y, $x+15=>$y);
  $obj->addString($x=>$y, "Color: $color");
}

$y=100;
foreach my $string (qw{Tiny Small MediumBold Large Giant}) {
  $x=5;
  $y+=10;
  foreach my $color (qw{red green blue black}) {
    $obj->addString($x=>$y, $string, $color, GD::Font->$string);
    $x+=20;
  }
}

print $obj->draw;
