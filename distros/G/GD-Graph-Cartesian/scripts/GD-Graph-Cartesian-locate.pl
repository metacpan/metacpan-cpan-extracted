#!/usr/bin/perl -w

=head1 NAME

GD-Graph-Cartesian-locate.pl - GD::Graph::Cartesian label example

=head1 SAMPLE OUTPUT

L<http://search.cpan.org/src/MRDVT/GD-Graph-Cartesian-0.05/scripts/GD-Graph-Cartesian-locate.png>

=cut

use strict;
use warnings;
use GD::Graph::Cartesian;
use Path::Class qw{file dir};

my $obj=GD::Graph::Cartesian->new(width=>800, height=>400,
                                  borderx=>15, bordery=>25,
                                  iconsize=>2);

my $sx=-5;
my $sy=-4;
my $ex=8;
my $ey=10;
$obj->addRectangle($sx,$sy,$ex,$ey);
foreach my $x ($sx.. $ex) {
  foreach my $y ($sy .. $ey) {
    $obj->addPoint($x=>$y);
    $obj->addString($x=>$y, "$x=>$y");
  } 
}
my ($x0,$x1,$y0,$y1) = ($obj->_minmaxx, $obj->_minmaxy);
$obj->addRectangle($x0,$y0,$x1,$y1);
my $file=file(file($0)->dir => "GD-Graph-Cartesian-locate.png");
my $fh=$file->openw;
print $fh $obj->draw;
