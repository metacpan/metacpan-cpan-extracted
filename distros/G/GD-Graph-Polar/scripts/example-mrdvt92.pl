#!/usr/bin/perl
use strict;
use warnings;
use GD::Graph::Polar;

=head1 NAME

example-mrdvt92.pl - GD::Graph::Polar example

=head1 SAMPLE OUTPUT

L<http://search.cpan.org/src/MRDVT/GD-Graph-Polar-0.16/scripts/example-mrdvt92.png>

=cut

my $obj=GD::Graph::Polar->new(size=>450, radius=>10, border=>3, ticks=>10);
my $r=9;
#M
$obj->addLine($r=>-135, $r=>135);
$obj->addLine($r=>135, $r=>-115);
$obj->addLine($r=>100, $r=>-115);
$obj->addLine($r=>100, $r=>-100);
#R
$obj->addArc(0=>0, $r/2=>45);
$obj->addArc($r/2=>45, $r=>90);
$obj->addLine(0=>0, $r=>-65);
$obj->addLine($r=>-90, $r=>90);
#D
$obj->addLine($r=>-60, $r=>60);
$obj->addArc($r=>-60, $r=>60);

open(IMG, ">example-mrdvt92.png");
print IMG $obj->draw;
close(IMG);
