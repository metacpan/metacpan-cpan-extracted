package Graph::Writer::DrGeo;
use strict;
use warnings;
use Graph::Writer;
use vars qw(@ISA $VERSION);
@ISA = qw(Graph::Writer);

use Math::Trig qw(:radial deg2rad pi);

$VERSION = '0.01';

my $layout = 'circle';

sub _write_graph {
  my ($self,$graph,$FILE) = @_;
  my @V = $graph->vertices_unsorted;
  my $out = "(new-figure \"Graph\")\n";
  for my $i (0..$#V) {
    my ($x,$y) = calc_circle_dot_position($i,scalar(@V));
    $out .= qq{(lets Point "$V[$i]" free  $x  $y)\n};
  }

  my @E = $graph->edges;
  for my $i (0..@E/2) {
    my $V1 = @E[2*$i] || last;
    my $V2 = @E[2*$i + 1] || last;
    $out .= qq{(Segment "" extremities $V1 $V2)\n};
  }
  print $FILE $out;
}

sub calc_circle_dot_position {
  my ($n,$ndots) = @_;
  # 3 is just a random estimation, should have a better guess.
  my $rho = $ndots/3;
  my ($x,$y) = raid2cart($rho,deg2rad(360*$n/$ndots));
  return ($x,$y);
}

sub raid2cart {
  my ($rho,$theta) = @_;
  my ($x,$y) = spherical_to_cartesian($rho,$theta,pi/2);
  return ($x,$y);
}


1;

__END__

=head1 NAME

  Graph::Writer::DrGeo - Save the graph output DrGeo scheme script.

=head1 SYNOPSIS

  my $g = new Graph;

  # Add some vertices/edges to $g

  my $writer = Graph::Writer::DrGeo->new();
  $writer->write_graph($g,"graph.scm");

  # graph.scm can be evaluated and rendered with Dr.Geo

=head1 DESCRIPTION

Dr. Geo is a GTK interactive geometry software. It allows one to
create geometric figure plus the interactive manipulation of such
figure in respect with their geometric constraints. It is useable in
teaching situation with students from primary or secondary level.

Besides the general file format, Dr.Geo also provide a dynamic
graph definition using the language of Scheme. This module
save any L<Graph> object into Scheme language, which can be
evaluated and rendered in Dr.Geo.

So far the default layout is the circle layout, more kind of
layout could be added, and patches welcome.

=head1 SEE ALSO

L<http://ofset.sourceforge.net/drgeo/>, L<Graph::Writer>

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

