#!/usr/bin/perl
use strict;
use warnings;
use GD::Graph::Polar;

=head1 NAME

example-plot.cgi - GD::Graph::Polar example

=head1 SAMPLE OUTPUT

L<http://search.cpan.org/src/MRDVT/GD-Graph-Polar-0.16/scripts/example-plot.png>

=cut

my $obj=GD::Graph::Polar->new(size=>450, radius=>10, border=>3, ticks=>20);
foreach (1..10) {
  my $r0=$_;
  my $t0=-($_*3+5);
  my $r1=$r0 * 0.8;
  my $t1=-$t0;
  $obj->addPoint($r0=>$t0);
  $obj->addPoint($r1=>$t1);
  $obj->addLine($r0=>$t0, $r1=>$t1);
  $obj->addArc($r0=>$t0, $r1=>$t1);
}
print "Content-type: image/png\n\n", $obj->draw;
