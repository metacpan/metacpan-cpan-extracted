#!/usr/bin/perl

=head1 NAME

GD-Graph-Cartesian-points.cgi - GD::Graph::Cartesian points example

=cut

use strict;
use warnings;
use CGI;
use GD::Graph::Cartesian;

my $cgi=CGI->new;

my $obj=GD::Graph::Cartesian->new(
                                  height   => 400,
                                  width    => 800,
                                  borderx  => 10,
                                  bordery  => 10,
                                  iconsize => 2,
                                 );
$obj->color("blue");      #sets the current color from Graphics::ColorNames
foreach my $x (0 .. 500) {
  my $pi=3.1415926;
  my $x=2 * $pi * rand();
  my $y=sin($x);
  $obj->addPoint($x => $y);
}

print $cgi->header("image/png");
print $obj->draw;
