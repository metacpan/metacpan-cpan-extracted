#!perl -w
#______________________________________________________________________
# Symbolic algebra: Invariants of the ellipse.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests => 5;

#______________________________________________________________________
# The focii to locus round trip of an ellipse has a length of twice the
# major radius
#______________________________________________________________________

 {my ($R, $f, $x, $i) = symbols(qw(R f x i)); # Major radius, focii

  my $y  = sqrt($R*$R-$f*$f - $x*$x +$f*$f*$x*$x / ($R*$R));  # Ellipse: rr=RR-ff
  my $a = $x+$i*$y - $f;            # Vector from focus1 to a point on the locus
  my $b = $x+$i*$y + $f;            # Vector from focus2 to same point on the locus

  ok(abs($a) + abs($b) ==  2*$R, 'Focus trip is constant 2R');
 }

#______________________________________________________________________
# Angle of incidence equals angle of reflection via dot product with
# normal to tangent vector.
#______________________________________________________________________

 {my ($i, $R, $f, $x) = symbols(qw(i R f x));

  my $r  = sqrt($R*$R - $f*$f);      # Minor radius
  my $y  = sqrt($r*$r - $x*$x +$f*$f*$x*$x / ($R*$R));  # Ellipse

  my $p  = $x + $i * $y;             # x,y point on locus of ellipse
  my $s  = $x*$r*$r + $i*$y*$R*$R;   # Normal to tangent at locus

  my $a  = $p - $f;                  # Vector from Focus to locus
  my $b  = $p + $f;                  # Vector from other Focus to locus

  my $c  = $a * abs($b);             # Make each focus vector the same length
  my $d  = $b * abs($a);             #   so that dot or cross will measure angle

  my $A  = $c^$s;                    # Angle of Reflection vs
  my $B  = $d^$s;                    # Angle of Incidence

  ok($A == $B, "Angle of incidence equals angle of reflection via dot product with normal to tangent");
 }

#______________________________________________________________________
# Angle of incidence equals angle of reflection via dot product with
# tangent vector using optimized substitutions.
# NB: -B due to anti-symmetry of cos(x) at x==pi/2
#______________________________________________________________________

 {my ($i, $R, $f, $x) = symbols(qw(i R f x));

  my $r  = sqrt($R*$R - $f*$f);      # Minor radius
  my $y  = sqrt($r*$r - $x*$x +$f*$f*$x*$x / ($R*$R)); # Ellipse

  my $p  = $x + $i * $y;             # x,y point on locus of ellipse
  my $s  = $i*$x*$r*$r - $y*$R*$R;   # Tangent at locus

  my $a  = $p - $f;                  # Vector from Focus to locus
  my $b  = $p + $f;                  # Vector from other Focus to locus

  my $c  = $a * abs($b);             # Make each focus vector the same length
  my $d  = $b * abs($a);             #   so that dot or cross will measure angle

  my $A  = $c ^ $s;                  # Angle of Reflection vs
  my $B  = $d ^ $s;                  # Angle of Incidence

  ok($A == -$B, "Angle of incidence equals angle of reflection via dot product with tangent");
 }

#______________________________________________________________________
# Angle of incidence equals angle of reflection via cross product with
# normal to tangent vector.
#______________________________________________________________________

 {my ($i, $R, $f, $x) = symbols(qw(i R f x));

  my $r  = sqrt($R*$R - $f*$f);      # Minor radius
  my $y  = sqrt($r*$r - $x*$x +$f*$f*$x*$x / ($R*$R));  # Ellipse

  my $p  = $x + $i * $y;             # x,y point on locus of ellipse
  my $s  = $x*$r*$r + $y*$R*$R*$i;   # Normal to tangent at locus

  my $a  = $p - $f;                  # Vector from Focus to locus
  my $b  = $p + $f;                  # Vector from other Focus to locus

  my $c  = $a * abs($b);             # Make each focus vector the same length
  my $d  = $b * abs($a);             #   so that dot or cross will measure angle

  my $A  = $c x $s;                  # Angle of Reflection vs
  my $B  = $d x $s;                  # Angle of Incidence

  ok($A == $B, "Angle of incidence equals angle of reflection via cross product with normal to tangent");
 }

#______________________________________________________________________
# Angle of incidence equals angle of reflection via cross product with
# tangent vector.
#______________________________________________________________________

 {my ($i, $R, $f, $x) = symbols(qw(i R f x));

  my $r  = sqrt($R*$R - $f*$f);      # Focus
  my $y  = sqrt($r*$r - $x*$x +$f*$f*$x*$x / ($R*$R));  # Ellipse

  my $p  = $x + $i * $y;             # x,y point on locus of ellipse
  my $s  = $i*($x*$r*$r + $y*$R*$R*$i);   # Normal to tangent at locus

  my $a  = $p - $f;                  # Vector from Focus to locus
  my $b  = $p + $f;                  # Vector from other Focus to locus

  my $c  = $a * abs($b);             # Make each focus vector the same length
  my $d  = $b * abs($a);             #   so that dot or cross will measure angle

  my $A  = $c x $s;                  # Angle of Reflection vs
  my $B  = $d x $s;                  # Angle of Incidence

  ok($A == $B, "Angle of incidence equals angle of reflection via cross product with tangent");
 }

