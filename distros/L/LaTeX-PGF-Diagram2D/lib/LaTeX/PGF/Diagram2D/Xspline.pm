
package LaTeX::PGF::Diagram2D::Xspline;

use 5.000000;
use strict;
use warnings;

use Carp;

our @ISA = qw();

our $VERSION = '1.00';

sub new
{
  my $self = undef;
  if($#_ < 0) {
    croak "Usage: LaTeX::PGF::Diagram2D::Xspline->new()";
  } else {
    my $class = shift;
    $self = {
      'correct_open_spline' => 0
    };
    bless($self, $class);
    $self->init();
  }
  return $self;
}


sub init
{
  my $s = undef;
  if($#_ >= 0) {
    $s->{'usea'} = 0; $s->{'useb'} = 0; $s->{'usec'} = 0; $s->{'used'} = 0;
    $s->{'gha'} = 0; $s->{'ghb'} = 0; $s->{'ghc'} = 0; $s->{'ghd'} = 0;
    $s->{'sa'} = 0.0; $s->{'sb'} = 0.0; $s->{'sc'} = 0.0; $s->{'sd'} = 0.0;
    $s->{'Ta'} = 0.0; $s->{'Tb'} = 1.0; $s->{'Tc'} = 0.0; $s->{'Td'} = 1.0;
    $s->{'pa'} = 2.0; $s->{'pb'} = 2.0; $s->{'pc'} = 2.0; $s->{'pd'} = 2.0;
    $s->{'qa'} = 0.0; $s->{'qb'} = 0.0; $s->{'qc'} = 0.0; $s->{'qd'} = 0.0;
    $s->{'xa'} = 0.0; $s->{'xb'} = 0.0; $s->{'xc'} = 0.0; $s->{'xd'} = 0.0;
    $s->{'ya'} = 0.0; $s->{'yb'} = 0.0; $s->{'yc'} = 0.0; $s->{'yd'} = 0.0;
    $s->{'sa'} = 0.0; $s->{'sb'} = 0.0; $s->{'sc'} = 0.0; $s->{'sd'} = 0.0;
    $s->{'dudta'} = -1.0; $s->{'dudtb'} = -1.0;
    $s->{'dudtc'} =  1.0; $s->{'dudtd'} =  1.0;
    $s->{'t'} = 0.0;
    $s->{'x'} = 0.0; $s->{'y'} = 0.0; $s->{'ddtx'} = 0.0; $s->{'ddty'} = 0.0;
  } else {
    croak "Usage: \$xspline->init0()";
  }
  return $s;
}



sub f
{
  my $self = shift;
  my $u = shift;
  my $p = shift;
  my $uu = $u * $u;
  my $uuu = $uu * $u;
  my $uuuu = $uuu * $u;
  my $uuuuu = $uuuu * $u;
  my $back = (6.0 - $p)*$uuuuu + (2.0 * $p - 15.0) * $uuuu
             + (10.0 - $p) * $uuu;
  return $back;
}



sub g
{
  my $self = shift;
  my $u = shift;
  my $p = shift;
  my $q = shift;
  my $uu = $u * $u; my $uuu = $uu * $u; my $uuuu = $uuu * $u;
  my $uuuuu = $uuuu * $u;
  my $back = $q *$u + 2.0 * $q * $uu + (10.0 - 12.0 * $q - $p) * $uuu
             + (2.0 * $p + 14.0 * $q - 15.0) * $uuuu
	     + (6.0 - 5.0 * $q - $p) * $uuuuu;
  return $back;
}


sub h
{
  my $self = shift;
  my $u = shift;
  my $p = shift;
  my $q = shift;
  my $uu = $u * $u; my $uuu = $uu * $u; my $uuuu = $uuu * $u;
  my $uuuuu = $uuuu * $u;
  my $back = $q * $u + 2.0 * $q * $uu - 2.0 * $q * $uuuu - $q * $uuuuu;
  return $back;
}



sub dfdu
{
  my $self = shift;
  my $u = shift;
  my $p = shift;
  my $uu = $u * $u; my $uuu = $uu * $u; my $uuuu = $uuu * $u;
  my $uuuuu = $uuuu * $u;
  my $back = 5.0 * (6.0 - $p)*$uuuu + 4.0 * (2.0 * $p - 15.0) * $uuu
             + 3.0 * (10.0 - $p) * $uu;
  return $back;
}


sub dgdu
{
  my $self = shift;
  my $u = shift;
  my $p = shift;
  my $q = shift;
  my $uu = $u * $u; my $uuu = $uu * $u; my $uuuu = $uuu * $u;
  my $uuuuu = $uuuu * $u;
  my $back = $q + 4.0 * $q * $u + 3.0 * (10.0 - 12.0 * $q - $p) * $uu
             + 4.0 * (2.0 * $p + 14.0 * $q - 15.0) * $uuu
	     + 5.0 * (6.0 - 5.0 * $q - $p) * $uuuu;
  return $back;
}



sub dhdu
{
  my $self = shift;
  my $u = shift;
  my $p = shift;
  my $q = shift;
  my $uu = $u * $u; my $uuu = $uu * $u; my $uuuu = $uuu * $u;
  my $uuuuu = $uuuu * $u;
  my $back = $q + 4.0 * $q * $u - 8.0 * $q * $uuu - 5.0 * $q * $uuuu;
  return $back;
}


sub set_points
{
  my $s = undef;
  if($#_ >= 4) {
    $s = shift;
    my $pa = shift;
    my $pb = shift;
    my $pc = shift;
    my $pd = shift;
    $s->{'usea'} = 0; $s->{'useb'} = 0; $s->{'usec'} = 0; $s->{'used'} = 0;
    $s->{'gha'} = 0; $s->{'ghb'} = 0; $s->{'ghc'} = 0; $s->{'ghd'} = 0;
    $s->{'sa'} = 0.0; $s->{'sb'} = 0.0; $s->{'sc'} = 0.0; $s->{'sd'} = 0.0;
    $s->{'Ta'} = 0.0; $s->{'Tb'} = 1.0; $s->{'Tc'} = 0.0; $s->{'Td'} = 1.0;
    $s->{'pa'} = 2.0; $s->{'pb'} = 2.0; $s->{'pc'} = 2.0; $s->{'pd'} = 2.0;
    $s->{'qa'} = 0.0; $s->{'qb'} = 0.0; $s->{'qc'} = 0.0; $s->{'qd'} = 0.0;
    $s->{'xa'} = 0.0; $s->{'xb'} = 0.0; $s->{'xc'} = 0.0; $s->{'xd'} = 0.0;
    $s->{'ya'} = 0.0; $s->{'yb'} = 0.0; $s->{'yc'} = 0.0; $s->{'yd'} = 0.0;
    $s->{'sa'} = 0.0; $s->{'sb'} = 0.0; $s->{'sc'} = 0.0; $s->{'sd'} = 0.0;
    $s->{'dudta'} = -1.0; $s->{'dudtb'} = -1.0;
    $s->{'dudtc'} =  1.0; $s->{'dudtd'} =  1.0;
    $s->{'t'} = 0.0;
    $s->{'x'} = 0.0; $s->{'y'} = 0.0; $s->{'ddtx'} = 0.0; $s->{'ddty'} = 0.0;
    if(defined($pa)) {
      if($#$pa >= 2) {
        $s->{'usea'} = 1;
        $s->{'xa'} = $pa->[0];
	$s->{'ya'} = $pa->[1];
	$s->{'sa'} = $pa->[2];
      }
    }
    if(defined($pb)) {
      if($#$pb >= 2) {
        $s->{'useb'} = 1;
        $s->{'xb'} = $pb->[0];
	$s->{'yb'} = $pb->[1];
	$s->{'sb'} = $pb->[2];
      }
    }
    if(defined($pc)) {
      if($#$pc >= 2) {
        $s->{'usec'} = 1;
        $s->{'xc'} = $pc->[0];
	$s->{'yc'} = $pc->[1];
	$s->{'sc'} = $pc->[2];
      }
    }
    if(defined($pd)) {
      if($#$pd >= 2) {
        $s->{'used'} = 1;
        $s->{'xd'} = $pd->[0];
	$s->{'yd'} = $pd->[1];
	$s->{'sd'} = $pd->[2];
      }
    }
    if($s->{'sa'} < -1.0) { $s->{'sa'} = -1.0; }
    if($s->{'sb'} < -1.0) { $s->{'sb'} = -1.0; }
    if($s->{'sc'} < -1.0) { $s->{'sc'} = -1.0; }
    if($s->{'sd'} < -1.0) { $s->{'sd'} = -1.0; }
    if($s->{'sa'} >  1.0) { $s->{'sa'} =  1.0; }
    if($s->{'sb'} >  1.0) { $s->{'sb'} =  1.0; }
    if($s->{'sc'} >  1.0) { $s->{'sc'} =  1.0; }
    if($s->{'sd'} >  1.0) { $s->{'sd'} =  1.0; }
    if($s->{'sb'} < 0.0) {
      if($s->{'usea'}) { $s->{'gha'} = 1; }
      if($s->{'usec'}) { $s->{'ghc'} = 1; }
    }
    if($s->{'sc'} < 0.0) {
      if($s->{'useb'}) { $s->{'ghb'} = 1; }
      if($s->{'used'}) { $s->{'ghd'} = 1; }
    }
    if($s->{'usea'}) {
      if($s->{'gha'}) {
        $s->{'qa'} = -0.5 * $s->{'sb'};
      } else {
        $s->{'Ta'} = $s->{'sb'};
	$s->{'pa'} = 2.0 * (1.0 + $s->{'Ta'}) * (1.0 + $s->{'Ta'});
	$s->{'dudta'} = -1.0 / (1.0 + $s->{'Ta'});
      }
    }
    if($s->{'useb'}) {
      if($s->{'ghb'}) {
        $s->{'qb'} = -0.5 * $s->{'sc'};
      } else {
        $s->{'Tb'} = 1.0 + $s->{'sc'};
	$s->{'pb'} = 2.0 * $s->{'Tb'} * $s->{'Tb'};
	$s->{'dudtb'} = -1.0 / $s->{'Tb'};
      }
    }
    if($s->{'usec'}) {
      if($s->{'ghc'}) {
        $s->{'qc'} = -0.5 * $s->{'sb'};
      } else {
        $s->{'Tc'} = 0.0 - $s->{'sb'};
	$s->{'pc'} = 2.0 * (1.0 - $s->{'Tc'}) * (1.0 - $s->{'Tc'});
	$s->{'dudtc'} = 1.0 / (1.0 - $s->{'Tc'});
      }
    }
    if($s->{'used'}) {
      if($s->{'ghd'}) {
        $s->{'qd'} = -0.5 * $s->{'sc'};
      } else {
        $s->{'Td'} = 1.0 - $s->{'sc'};
	$s->{'pd'} = 2.0 * (2.0 - $s->{'Td'}) * (2.0 - $s->{'Td'});
	$s->{'dudtd'} = 1.0 / (2.0 - $s->{'Td'});
      }
    }
  } else {
    croak "Usage: \$xpline->set_points(a, b, c, d, seg, nsegs, closed";
  }
  return $s;
}



sub calculate
{
  my $s = undef;
  if($#_ >= 1) {
    $s = shift; my $t = shift;
    my $fv = 0.0;		# Function value (weight)
    my $dfdt = 0.0;		# First derivative
    my $s_d_f_d_t = 0.0;	# Summary of derivatives
    my $s_f = 0.0;		# Summary of all weights
    my $s_x_f = 0.0;		# Summary x * weight
    my $s_y_f = 0.0;		# Summary y * weight
    my $s_x_d_f_d_t = 0.0;	# Summary x * derivative
    my $s_y_d_f_d_t = 0.0;	# Summary y * derivative
    my $u;			# Substitution for t
    $s->{'t'} = $t;
    if($s->{'usea'}) {
      $fv = 0.0; $dfdt = 0.0;
      if($s->{'gha'}) {
        $u = 0.0 - $t;
	$fv = $s->h($u, $s->{'pa'}, $s->{'qa'});
	$dfdt = -1.0 * $s->dhdu($u, $s->{'pa'}, $s->{'qa'});
      } else {
        if($t < $s->{'Ta'}) {
	  $u = ($s->{'Ta'} - $t)/(1.0 + $s->{'Ta'});
	  $fv = $s->f($u, $s->{'pa'});
	  $dfdt = $s->dfdu($u, $s->{'pa'}) * $s->{'dudta'};
	}
      }
      $s_f += $fv;
      $s_d_f_d_t += $dfdt;
      $s_x_f += $s->{'xa'} * $fv;
      $s_y_f += $s->{'ya'} * $fv;
      $s_x_d_f_d_t += $s->{'xa'} * $dfdt;
      $s_y_d_f_d_t += $s->{'ya'} * $dfdt;

    }
    if($s->{'useb'}) {
      $fv = 0.0; $dfdt = 0.0;
      if($s->{'ghb'}) {
        $u = 1.0 - $t;
	$fv = $s->g($u, $s->{'pb'}, $s->{'qb'});
	$dfdt = -1.0 * $s->dgdu($u, $s->{'pb'}, $s->{'qb'});
      } else {
        $u = ($s->{'Tb'} - $t) / $s->{'Tb'};
	$fv = $s->f($u, $s->{'pb'});
	$dfdt = $s->dfdu($u, $s->{'pb'}) * $s->{'dudtb'};
      }
      $s_f += $fv;
      $s_d_f_d_t += $dfdt;
      $s_x_f += $s->{'xb'} * $fv;
      $s_y_f += $s->{'yb'} * $fv;
      $s_x_d_f_d_t += $s->{'xb'} * $dfdt;
      $s_y_d_f_d_t += $s->{'yb'} * $dfdt;
    }
    if($s->{'usec'}) {
      $fv = 0.0; $dfdt = 0.0;
      if($s->{'ghc'}) {
        $u = $t;
	$fv = $s->g($u, $s->{'pc'}, $s->{'qc'});
	$dfdt = $s->dgdu($u, $s->{'pc'}, $s->{'qc'});
      } else {
        $u = ($t - $s->{'Tc'}) / (1.0 - $s->{'Tc'});
	$fv = $s->f($u, $s->{'pc'});
	$dfdt = $s->dfdu($u, $s->{'pc'}) * $s->{'dudtc'};
      }
      $s_f += $fv;
      $s_d_f_d_t += $dfdt;
      $s_x_f += $s->{'xc'} * $fv;
      $s_y_f += $s->{'yc'} * $fv;
      $s_x_d_f_d_t+= $s->{'xc'} * $dfdt;
      $s_y_d_f_d_t+= $s->{'yc'} * $dfdt;
    }
    if($s->{'used'}) {
      $fv = 0.0; $dfdt = 0.0;
      if($s->{'ghd'}) {
        $u = $t - 1.0;
	$fv = $s->h($u, $s->{'pd'}, $s->{'qd'});
	$dfdt = $s->dhdu($u, $s->{'pd'}, $s->{'qd'});
      } else {
        if($t > $s->{'Td'}) {
	  $u = ($t - $s->{'Td'}) / (2.0 - $s->{'Td'});
	  $fv = $s->f($u, $s->{'pd'});
	  $dfdt = $s->dfdu($u, $s->{'pd'}) * $s->{'dudtd'};
	}
      }
      $s_f += $fv;
      $s_d_f_d_t += $dfdt;
      $s_x_f += $s->{'xd'} * $fv;
      $s_y_f += $s->{'yd'} * $fv;
      $s_x_d_f_d_t += $s->{'xd'} * $dfdt;
      $s_y_d_f_d_t += $s->{'yd'} * $dfdt;
    }
    $s->{'x'} = $s_x_f / $s_f;
    $s->{'y'} = $s_y_f / $s_f;
    $s->{'ddtx'} =
    ($s_x_d_f_d_t * $s_f - $s_x_f * $s_d_f_d_t) / ($s_f * $s_f);
    $s->{'ddty'} =
    ($s_y_d_f_d_t * $s_f - $s_y_f * $s_d_f_d_t) / ($s_f * $s_f);
  } else {
    croak "Usage: \$xspline->calculate(t)";
  }
  return $s;
}


1;
__END__


=head1 NAME

LaTeX::PGF::Diagram2D::Xspline - Perl extension for drawing 2D diagrams

=head1 DESCRIPTION

This class is used internally by the LaTeX::PGF::Diagram2D package.

=cut

