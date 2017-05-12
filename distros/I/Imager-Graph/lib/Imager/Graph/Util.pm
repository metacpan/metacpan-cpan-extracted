=head1 NAME

  Imager::Graph::Util - simple geometric functions

=head1 SYNOPSIS

  my @abc = line_from_points($x1, $y1, $x2, $y2);
  my @p = intersect_lines(@abc1, @abc2);
  my @points = intersect_line_and_circle(@abc1, $cx, $cy, $radius);

=head1 DESCRIPTION

Provides some simple geometric functions intended for use in drawing
graphs.

=over

=item line_from_points($x1, $y1, $x2, $y2)

Returns the coefficients of a line in the Ax + By + C = 0 form.

Returns the list (A, B, C), or an empty list if they are the same
point.

=item intersect_lines(@abc1, @abc2)

Returns the point of intersection of the 2 lines, each given in
Ax+By+C=0 form.  Returns either the point (x, y) or an empty list.

=item intersect_line_and_circle(@abc, $cx, $cy, $radius)

Returns the points or point of intersection of the given line and
circle.

=back

=head1 INTERNALS

=over

=cut

package Imager::Graph::Util;
use strict;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
require Exporter;
@EXPORT = qw(intersect_lines intersect_line_and_circle
              line_from_points);
use Carp;
use constant DEBUG => 0;

sub line_from_points {
  my ($x1, $y1, $x2, $y2) = @_;

  my $A = $y1 - $y2;
  my $B = $x2 - $x1;
  my $C = $x1 * $y2 - $y1 * $x2;

  return () if $A == 0 && $B == 0;

  return ($A, $B, $C);
}

sub intersect_lines {
  my ($a1, $b1, $c1, $a2, $b2, $c2) = @_;

  DEBUG and !defined($a1) and croak('$a1 undefined');
  DEBUG and !defined($b1) and croak('$b1 undefined');
  DEBUG and !defined($c1) and croak('$c1 undefined');
  DEBUG and !defined($a2) and croak('$a2 undefined');
  DEBUG and !defined($b2) and croak('$b2 undefined');
  DEBUG and !defined($c2) and croak('$c2 undefined');

  my $divisor = $a2 * $b1 - $a1 * $b2;
  return () if $divisor == 0;

  my $x = ($b2 * $c1 - $b1 * $c2) / $divisor;
  my $y = ($a1 * $c2 - $a2 * $c1) / $divisor;

  return ($x, $y);
}

=item intersect_line_and_circle()

The implementation is a little heavy on math.  Perhaps there was a
better way to implement it.

Starting with the equations of a line and that of a circle:

  (1)  Ax + By + C = 0
  (2)  (x - x1)**2 + (y - y1)**2 = R ** 2
  (3)  Ax = -By - C     # re-arrange (1)
  (4)  A**2 (x - x1)**2 + A**2 (y - y1)**2 = R**2 A**2 # (2) * A**2
  (5)  (Ax - Ax1)**2 + (Ay - Ay1)**2 = R**2 A**2 # move it inside
  (6) (-By - C - Ax1)**2 + (Ay - Ay1)**2 = R**2 A**2 # sub (3) into (5)

Expand and convert to standard quadratic form, and similary for x.

Be careful :)

=cut

sub intersect_line_and_circle {
  my ($a, $b, $c, $cx, $cy, $r) = @_;

  DEBUG and !defined($a)  and croak('$a undefined');
  DEBUG and !defined($b)  and croak('$b undefined');
  DEBUG and !defined($c)  and croak('$c undefined');
  DEBUG and !defined($cx) and croak('$cx undefined');
  DEBUG and !defined($cy) and croak('$cy undefined');
  DEBUG and !defined($r)  and croak('$r undefined');

  # I should probably optimize the following
  my $qya = $b * $b + $a * $a;
  my $qyb = 2 * $b * $c + 2 * $a * $b * $cx - 2 * $a * $a * $cy;
  my $qyc = $c * $c + 2 * $a * $c * $cx + $a * $a * $cy * $cy 
    + $a * $a * $cx * $cx - $r * $r * $a * $a;

  my $qxa = $b * $b + $a * $a;
  my $qxb = 2 * $a * $c + 2 * $a * $b * $cy - 2 * $b * $b * $cx;
  my $qxc = $c * $c + 2 * $b * $c * $cy + $b * $b * $cx * $cx
    + $b * $b * $cy * $cy - $r * $r * $b * $b;

  my $dety = $qyb * $qyb - 4 * $qya * $qyc;
  my $detx = $qxb * $qxb - 4 * $qxa * $qxc;

  return () if $dety < 0 || $detx < 0;
  
  my $detyroot = sqrt($dety);
  my $detxroot = sqrt($detx);

  my $y1 = (- $qyb - $detyroot) / ( 2 * $qya);
  my $x1 = (- $qxb - $detxroot) / ( 2 * $qxa);

  DEBUG and abs($a * $x1 + $b * $y1 + $c) > 0.00001
    and print "(x1 $x1, y1 $y1) not on line\n";
  DEBUG and abs(($x1-$cx)*($x1-$cx)+($y1-$cy)*($y1-$cy) - $r*$r) > 0.0001
    and print "(x1 $x1, y1 $y1) not on circle\n";

  return ($x1, $y1) if $detxroot == 0 && $detyroot == 0;
  
  my $y2 = (- $qyb + $detyroot) / (2 * $qya);
  my $x2 = (- $qxb + $detxroot) / (2 * $qxa);
      
  DEBUG and abs($a * $x2 + $b * $y2 + $c) > 0.00001
    and print "(x2 $x2, y2 $y2) not on line\n";
  DEBUG and abs(($x2-$cx)*($x2-$cx)+($y2-$cy)*($y2-$cy) - $r*$r) > 0.0001
    and print "(x2 $x2, y2 $y2) not on circle\n";

  return ($x1, $y1, $x2, $y2);
}

__END__

=back

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=head1 SEE ALSO

  Imager::Graph(3), http://www.develop-help.com/imager/

=cut

