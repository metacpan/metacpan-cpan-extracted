
package LaTeX::PGF::Diagram2D::Plot;

use 5.000000;
use strict;
use warnings;

use Carp;

our @ISA = qw();

our $VERSION = '1.00';

require LaTeX::PGF::Diagram2D::Xspline;

# Plot types, Output (t):
#  0  Dots
#  1  Curve
#  2  Lines

# Plot data types, input (d):
#  0  Function, optionally with derivative given
#     d1=function, d2=derivative
#  1  Points (optionally with a derivative)
#     d1=reference to array of points
#  2  Parametric function
#     d1=xfunction d2=yfunction, d3=xderivative (opt), d4=yderivative (opt)
#  3  X-spline points (open spline)




# Dot style:
#  0 = circle
#  1 = square
#  2 = diamond
#  3 = triangle
#  4 = crosshair
#  5 = pentagon


use PDL;



sub new
{
  my $self = undef;
  if($#_ < 0) {
    croak "Usage: LaTeX::PGF::Diagram2D::Plot->new()";
  } else {
    my $class = shift;
    $self = {
      't' => 1,	# Plot type: -1=unknown, 0=points, 1=curve, 2=lines
      'd' => -1,	# Data type: -1=unknown, 0=function, 1=points, 2=param
      'r' => undef,	# Range (for undef use entire x-axis or plot points)
      'd1' => undef,	# Data 1 (Function or array of points)
      'd2' => undef,	# Data 2 (Derivative function)
      'd3' => undef,	# Data 3
      'd4' => undef,	# Data 4
      'f' => undef,	# Flag: Finished.
      'ax' => undef,	# x axis
      'ay' => undef,	# y axis
      'color' => undef,	# Plot color
      'pp' => undef,	# Paper points (userspace coordinates)
      'i' => 20,	# Number of curve intervals
      'ds' => 0,	# Dot style
      'dsz' => 5.0,	# Dot size (diameter, multiple of line size)
      'debug' => 0,	# Flag: Debug
      'xspline' => 8,	# Bezier segments per X-spline segment
    };
    bless($self, $class);
  }
  return $self;
}


sub set_xy_fct
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$plot->set_xy_fct(function,[derivative-function])";
  } else {
    $self = shift;
    $self->{'d1'} = shift;
    if($#_ >= 0) {
      $self->{'d2'} = shift;
    }
    $self->{'d'} = 0;
  }
  return $self;
}



sub set_parametric_fct
{
  my $self = undef;
  if($#_ < 4) {
    croak "Usage: \$plot->set_parametric_fct(min, max, xfct, yfct[, xderiv, yderiv]);";
  } else {
    $self = shift;
    my $min = shift;
    my $max = shift;
    $self->{'r'} = [ $min, $max ];
    $self->{'d1'} = shift;
    $self->{'d2'} = shift;
    $self->{'d'} = 2;
    if($#_ >= 1) {
      $self->{'d3'} = shift;
      $self->{'d4'} = shift;
    }
  }
  return $self;
}



sub set_xy_points
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$plot->set_xy_points(pointsarrayref)";
  } else {
    $self = shift;
    $self->{'d1'} = shift;
    $self->{'d'} = 1;
  }
  return $self;
}



sub set_xy_points_text
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$plot->set_xy_points_text(text)";
  } else {
    $self = shift;
    my $text = shift;
    my @array;
    my $na = 0;
    my $x;
    my $y;
    my $d;
    foreach my $line (split(/\n/, $text)) {
      $x = 0.0; $y = 0.0; $d = 0.0;
      if($line =~ /\S/o) {
        if($line =~ /^\s*(\S+)\s+(\S+)\s+(\S+)/o) {
	  $x = $1; $y = $2; $d = $3;
	  $array[$na++] = [ $x, $y, $d ];
	} else {
	  if($line =~ /^\s*(\S+)\s+(\S+)/o) {
	    $x = $1; $y = $2;
	    $array[$na++] = [ $x, $y ];
	  } else {
	    croak "ERROR: Illegal line \"$line\" in text!";
	  }
	}
      }
    }
    $self->{'d1'} = \@array; $self->{'d'} = 1;
  }
  return $self;
}



sub set_xy_points_file
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$plot->set_xy_points_file(filename)";
  } else {
    $self = shift; my $fn = shift; my $line;
    my @array; my $na = 0;
    my $x; my $y; my $d;
    if(open(my $fh, '<', "$fn")) {
      while(<$fh>) {
        $line = $_; chomp $line;
	if($line =~ /\S/o) {
	  if($line =~ /^\s*(\S+)\s+(\S+)\s+(\S+)/o) {
	    $x = $1; $y = $2; $d = $3;
	    $array[$na++] = [ $x, $y, $d ];
	  } else {
	    if($line =~ /^\s*(\S+)\s+(\S+)/o) {
	      $x = $1; $y = $2;
	      $array[$na++] = [ $x, $y ];
	    }
	  }
	}
      }
      close($fh); $fh = undef;
      $self->{'d1'} = \@array; $self->{'d'} = 1;
    }
  }
  return $self;
}



sub set_xsplines_points
{
  my $self = undef;
  my @pp; my $npp = 0; my $pr; my $x; my $y; my $s;
  if($#_ < 1) {
    croak "Usage: \$plot->set_xspline_points(arrayref [, s_default ])";
  } else {
    $self = shift;
    my $ar = shift;
    my $sdef = -1.0;
    if($#_ >= 0) {
      $sdef = shift;
      if($sdef < -1.0) { $sdef = -1.0; }
      if($sdef >  1.0) { $sdef =  1.0; }
    }
    for(my $i = 0; $i <= $#$ar; $i++) {
      $pr = $ar->[$i];
      if($#$pr > 0) {
        $x = $pr->[0]; $y = $pr->[1]; $s = $sdef;
	if($#$pr > 1) {
	  $s = $pr->[2];
	  if($s < -1.0) { $s = -1.0; }
	  if($s >  1.0) { $s =  1.0; }
	}
	$pp[$npp++] = [ $x, $y, $s ];
      }
    }
    $self->{'d1'} = \@pp; $self->{'d'} = 3;
  }
  return $self;
}



sub set_xsplines_points_text
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$plot->set_xsplines_points_text(text [, s_default ])";
  } else {
    $self = shift; my $t = shift; my $sdef = -1.0;
    my $x; my $y; my $s;
    my @pp; my $npp = 0;
    if($#_ >= 0) {
      $sdef = shift;
      if($sdef < -1.0) { $sdef = -1.0; }
      if($sdef >  1.0) { $sdef =  1.0; }
    }
    foreach my $line (split(/\n/, $t)) {
      $x = 0.0; $y = 0.0; $s = $sdef;
      if($line =~ /\S/o) {
        if($line =~ /^\s*(\S+)\s+(\S+)\s+(\S+)/o) {
	  $x = $1; $y = $2; $s = $3;
	  if($s < -1.0) { $s = -1.0; }
	  if($s >  1.0) { $s =  1.0; }
	  $pp[$npp++] = [ $x, $y, $s ];
	} else {
	  if($line =~ /^\s*(\S+)\s+(\S+)/o) {
	    $x = $1; $y = $2;
	    $pp[$npp++] = [ $x, $y, $sdef ];
	  }
	}
      }
    }
    $self->{'d1'} = \@pp; $self->{'d'} = 3;
  }
  return $self;
}



sub set_xspline_points_file
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$plot->set_xspline_points_file(filename [, s_default ])";
  } else {
    $self = shift; my $fn = shift; my $sdef = -1; my $fh = undef;
    my $line; my $x; my $y; my $s;
    my @pp; my $npp = 0;
    if($#_ >= 0) {
      $sdef = shift;
      if($sdef < -1.0) { $sdef = -1.0; }
      if($sdef >  1.0) { $sdef =  1.0; }
    }
    if(open($fh, '<', $fn)) {
      while(<$fh>) {
        $line = $_; chomp $line;
	$x = 0.0; $y = 0.0; $s = $sdef;
	if($line =~ /\S/o) {
	  if($line =~/^\s*(\S+)\s+(\S+)\s+(\S+)/o) {
	    $x = $1; $y = $2; $s = $3;
	    if($s < -1.0) { $s = -1.0; }
	    if($s >  1.0) { $s =  1.0; }
	    $pp[$npp++] = [ $x, $y, $s ];
	  } else {
	    if($line =~/^\s*(\S+)\s+(\S+)/o) {
	      $x = $1; $y = $2;
	      $pp[$npp++] = [ $x, $y, $sdef ];
	    }
	  }
	}
      }
      close($fh);
      $self->{'d1'} = \@pp; $self->{'d'} = 3;
    }
  }
  return $self;
}



sub finish_points_points
{
  my $self = shift;
  $self->{'pp'} = $self->{'d1'};
  return $self;
}



sub finish_points_lines
{
  my $self = shift;
  $self->{'pp'} = $self->{'d1'};
  return $self;
}



sub finish_points_curve
{
  my $self = shift;
  $self->{'pp'} = $self->{'d1'};
  return $self;
}



sub finish_function_points
{
  my $self = shift;
  my @dp;		# data points
  my $ndp = 0;		# Number of data points
  my $xs = $self->{'ax'}->{'min'};
  my $xe = $self->{'ax'}->{'max'};
  my $rp = $self->{'range'};
  my $x = 0.0;
  my $y = 0.0;
  if(defined($rp)) {
    $xs = $rp->[0]; $xe = $rp->[1];
  }
  my $diff = $xe - $xs;
  my $i = $self->{'i'};
  if(defined($self->{'d1'})) {
    my $fp = $self->{'d1'};
    if($self->{'ax'}->{'t'}) {
      $diff = exp(log($xe/$xs)/(1.0 * $i));
      $x = $xs;
      $y = &$fp($x);
      $dp[0] = [ $x, $y ];
      for(my $j = 1; $j < $i; $j++) {
        $x = $x * $diff;
	$y = &$fp($x);
	$dp[$j] = [ $x, $y ];
      }
      $x = $xe;
      $y = &$fp($x);
      $dp[$i] = [ $x, $y ];
    } else {
      $x = $xs;
      $y = &$fp($x);
      $dp[0] = [ $x, $y ];
      for(my $j = 1; $j < $i; $j++) {
        $x = $xs + ((1.0 * $j) * $diff)/(1.0 * $i);
        $y = &$fp($x);
        $dp[$j] = [ $x, $y ];
      }
      $x = $xe;
      $y = &$fp($x);
      $dp[$i] = [ $x, $y ];
    }
    $self->{'pp'} = \@dp;
  }
  return $self;
}



sub finish_function_curve
{
  my $self = shift;
  if(defined($self->{'d2'})) {
    my @dp;		# data points
    my $ndp = 0;		# Number of data points
    my $xs = $self->{'ax'}->{'min'};
    my $xe = $self->{'ax'}->{'max'};
    my $rp = $self->{'range'};
    my $x = 0.0;
    my $y = 0.0;
    my $z = 0.0;
    if(defined($rp)) {
      $xs = $rp->[0]; $xe = $rp->[1];
    }
    my $diff = $xe - $xs;
    my $i = $self->{'i'};
    if(defined($self->{'d1'})) {
      my $fp = $self->{'d1'};
      my $dfp = $self->{'d2'};
      if($self->{'ax'}->{'t'}) {
        $diff = exp(log($xe/$xs)/(1.0 * $i));
        $x = $xs;
        $y = &$fp($x);
        $z = &$dfp($x);
        $dp[0] = [ $x, $y, $z ];
        for(my $j = 1; $j < $i; $j++) {
          $x = $x * $diff;
          $y = &$fp($x);
	  $z = &$dfp($x);
          $dp[$j] = [ $x, $y, $z ];
        }
        $x = $xe;
        $y = &$fp($x);
        $z = &$dfp($x);
        $dp[$i] = [ $x, $y, $z ];
      } else {
        $x = $xs;
        $y = &$fp($x);
        $z = &$dfp($x);
        $dp[0] = [ $x, $y, $z ];
        for(my $j = 1; $j < $i; $j++) {
          $x = $xs + ((1.0 * $j) * $diff)/(1.0 * $i);
          $y = &$fp($x);
	  $z = &$dfp($x);
          $dp[$j] = [ $x, $y, $z ];
        }
        $x = $xe;
        $y = &$fp($x);
        $z = &$dfp($x);
        $dp[$i] = [ $x, $y, $z ];
      }
      $self->{'pp'} = \@dp;
    }
  } else {
    $self->finish_function_points();
  }
  return $self;
}



sub finish_param_points
{
  my $self = shift;
  if(defined($self->{'r'}) && defined($self->{'d1'}) && defined($self->{'d2'}))
  {
    my @pp; my $npp = 0;
    my $range = $self->{'r'}; my $fx = $self->{'d1'}; my $fy = $self->{'d2'};
    my $mint = $range->[0]; my $maxt = $range->[1]; my $i = $self->{'i'};
    my $x; my $y;
    my $t;
    $t = $mint;
    $x = &$fx($t); $y = &$fy($t);
    $pp[$npp++] = [ $t, $x, $y, undef, undef ];
    for(my $j = 1; $j < $i; $j++) {
      $t = $mint + ((1.0 * $j) * ($maxt - $mint)) / (1.0 * $i);
      $x = &$fx($t); $y = &$fy($t);
      $pp[$npp++] = [ $t, $x, $y, undef, undef ];
    }
    $t = $maxt;
    $x = &$fx($t); $y = &$fy($t);
    $pp[$npp++] = [ $t, $x, $y, undef, undef ];
    $self->{'pp'} = \@pp;
  }
  return $self;
}



sub finish_param_curve
{
  my $self = shift;
  if(defined($self->{'r'}) && defined($self->{'d1'}) && defined($self->{'d2'}))
  {
    my @pp; my $npp = 0;
    my $range = $self->{'r'};
    my $fx = $self->{'d1'}; my $fy = $self->{'d2'};
    my $fxx = undef; my $fyy = undef;
    if(defined($self->{'d3'}) && defined($self->{'d4'})) {
      $fxx = $self->{'d3'}; $fyy = $self->{'d4'};
    }
    my $mint = $range->[0]; my $maxt = $range->[1]; my $i = $self->{'i'};
    my $x; my $y; my $xx; my $yy;
    my $t;
    $t = $mint;
    $x = &$fx($t); $y = &$fy($t); $xx = undef; $yy = undef;
    if(defined($fxx)) { $xx = &$fxx($t); $yy = &$fyy($t); }
    $pp[$npp++] = [ $t, $x, $y, $xx, $yy ];
    for(my $j = 1; $j < $i; $j++) {
      $t = $mint + ((1.0 * $j) * ($maxt - $mint)) / (1.0 * $i);
      $x = &$fx($t); $y = &$fy($t); $xx = undef; $yy = undef;
      if(defined($fxx)) { $xx = &$fxx($t); $yy = &$fyy($t); }
      $pp[$npp++] = [ $t, $x, $y, $xx, $yy ];
    }
    $t = $maxt;
    $x = &$fx($t); $y = &$fy($t); $xx = undef; $yy = undef;
    if(defined($fxx)) { $xx = &$fxx($t); $yy = &$fyy($t); }
    $pp[$npp++] = [ $t, $x, $y, $xx, $yy ];
    $self->{'pp'} = \@pp;
  }
  return $self;
}



sub finish
{
  my $self = undef;
  if($#_ < 0) {
    croak "Usage: \$plot->finish()";
  } else {
    $self = shift;
    if(!defined($self->{'f'})) {
      my $pt = $self->{'t'};
      my $dt = $self->{'d'};
      if($pt == 0) {
        if($dt == 0) {
          $self->finish_function_points();
        } else {
          if($dt == 1) {
	    $self->finish_points_points();
	  } else {
	    if($dt == 2) {
	      $self->finish_param_points();
	    } else {
	      if($dt == 3) {
	        $self->finish_points_points();
	      }
	    }
	  }
        }
      } else {
        if($pt == 1) {
          if($dt == 0) {
	    $self->finish_function_curve();
	  } else {
	    if($dt == 1) {
	      $self->finish_points_curve();
	    } else {
	      if($dt == 2) {
	        $self->finish_param_curve();
	      } else {
	        if($dt == 3) {
		  $self->finish_points_points();
		}
	      }
	    }
	  }
        } else {
          if($pt == 2) {
	    if($dt == 0) {
	      $self->finish_function_points();
	    } else {
	      if($dt == 1) {
	        $self->finish_points_lines();
	      } else {
	        if($dt == 2) {
	          $self->finish_param_points();
	        } else {
		  if($dt == 3) {
		    $self->finish_points_points();
		  }
		}
	      }
	    }
	  }
        }
      }
      $self->{'f'} = 1;
    }
  }
  return $self;
}



sub dot_circle
{
  my $self = shift;
  my $dg = shift;
  my $fh = shift;
  my $x = shift;
  my $y = shift;
  my $diameter = shift;
  print $fh "\\pgfpathcircle{";
  $dg->write_point($x, $y);
  print $fh "}{" . (0.5 * $diameter) . "bp}\\pgfusepath{fill}\n";
  return $self;
}



sub dot_square
{
  my $self = shift;
  my $dg = shift;
  my $fh = shift;
  my $x = shift;
  my $y = shift;
  my $diameter = shift;
  print $fh "\\pgfpathmoveto{";
  $dg->write_point(($x - 0.5 * $diameter), ($y - 0.5 * $diameter));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x + 0.5 * $diameter), ($y - 0.5 * $diameter));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x + 0.5 * $diameter), ($y + 0.5 * $diameter));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x - 0.5 * $diameter), ($y + 0.5 * $diameter));
  print $fh "}\n\\pgfpathclose\\pgfusepath{fill}\n";
  return $self;
}



sub dot_diamond
{
  my $self = shift;
  my $dg = shift;
  my $fh = shift;
  my $x = shift;
  my $y = shift;
  my $diameter = shift;
  my $d = $diameter / sqrt(2.0);
  print $fh "\\pgfpathmoveto{";
  $dg->write_point($x, ($y + $d));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x - $d), $y);
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point($x, ($y - $d));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x + $d), $y);
  print $fh "}\n\\pgfpathclose\\pgfusepath{fill}\n";
  return $self;
}



sub dot_triangle
{
  my $self = shift;
  my $dg = shift;
  my $fh = shift;
  my $x = shift;
  my $y = shift;
  my $diameter = shift;
  my $a = 0.25 * $diameter;
  my $b = 0.5 * sqrt(0.75) * $diameter;
  print $fh "\\pgfpathmoveto{";
  $dg->write_point($x, ($y + 0.5 * $diameter));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x - $b), ($y - $a));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x + $b), ($y - $a));
  print $fh "}\n\\pgfpathclose\\pgfusepath{fill}\n";
  return $self;
}



sub dot_crosshair
{
  my $self = shift;
  my $dg = shift;
  my $fh = shift;
  my $x = shift;
  my $y = shift;
  my $diameter = shift;
  print $fh "\\pgfpathmoveto{";
  $dg->write_point($x, ($y + 0.5 * $diameter));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point($x, ($y - 0.5 * $diameter));
  print $fh "}\n";
  print $fh "\\pgfusepath{stroke}\n";
  print $fh "\\pgfpathmoveto{";
  $dg->write_point(($x - 0.5 * $diameter), $y);
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x + 0.5 * $diameter), $y);
  print $fh "}\n\\pgfusepath{stroke}\n";
  return $self;
}



sub dot_pentagon
{
  my $self = shift;
  my $dg = shift;
  my $fh = shift;
  my $x = shift;
  my $y = shift;
  my $diameter = shift;
  my $a = 0.5 * $diameter * cos(2.0 * 3.1415926 / 5.0);
  my $b = 0.5 * $diameter * sin(2.0 * 3.1415926 / 5.0);
  my $c = 0.5 * $diameter * cos(4.0 * 3.1415926 / 5.0);
  my $d = 0.5 * $diameter * sin(4.0 * 3.1415926 / 5.0);
  print $fh "\\pgfpathmoveto{";
  $dg->write_point($x, ($y + 0.5 * $diameter));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x - $b), ($y + $a));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x - $d), ($y + $c));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x + $d), ($y + $c));
  print $fh "}\n";
  print $fh "\\pgfpathlineto{";
  $dg->write_point(($x + $b), ($y + $a));
  print $fh "}\n\\pgfpathclose\\pgfusepath{fill}\n";
  return $self;
}



sub plot_points_points
{
  my $self = shift; my $dg = shift;
  my $fh = $dg->{'f1'};
  my $aref = $self->{'pp'};
  my $pref = undef; my $x = undef; my $y = undef;
  my $diameter = $self->{'dsz'} * 0.2 * 72.0 / 25.4;
  if($#$aref > 0) {
    for(my $i = 0; $i <= $#$aref; $i++) {
      $pref = $aref->[$i];
      $x = $pref->[0]; $y = $pref->[1];
      $x = $self->{'ax'}->value_to_coord($x);
      $y = $self->{'ay'}->value_to_coord($y);
      my $dt = $self->{'ds'};
      if($dt == 0) {
        $self->dot_circle($dg, $fh, $x, $y, $diameter);
      }
      if($dt == 1) {
        $self->dot_square($dg, $fh, $x, $y, $diameter);
      }
      if($dt == 2) {
        $self->dot_diamond($dg, $fh, $x, $y, $diameter);
      }
      if($dt == 3) {
        $self->dot_triangle($dg, $fh, $x, $y, $diameter);
      }
      if($dt == 4) {
        $self->dot_crosshair($dg, $fh, $x, $y, $diameter);
      }
      if($dt == 5) {
        $self->dot_pentagon($dg, $fh, $x, $y, $diameter);
      }
    }
  }
  return $self;
}



sub plot_points_lines
{
  my $self = shift; my $dg = shift;
  my $fh = $dg->{'f1'};
  my $aref = $self->{'pp'};
  my $pref = undef; my $x = undef; my $y = undef;
  if($#$aref > 0) {
    for(my $i = 0; $i <= $#$aref; $i++) {
      $pref = $aref->[$i];
      $x = $pref->[0]; $y = $pref->[1];
      $x = $self->{'ax'}->value_to_coord($x);
      $y = $self->{'ay'}->value_to_coord($y);
      if($i == 0) {
        print $fh "\\pgfpathmoveto{";
      } else {
        print $fh "\\pgfpathlineto{";
      }
      $dg->write_point($x, $y);
      print $fh "}\n";
    }
    print $fh "\\pgfusepath{stroke}\n";
  }
  return $self;
}



sub all_values_with_derivative
{
  my $self = shift; my $dg = shift; my $pp = shift; my $fh = $dg->{'f1'};
  my $pref = $pp->[0];
  my $x = $pref->[0];
  my $y = $pref->[1];
  my $z = $pref->[2];
  my $ox = $x; my $oy = $y; my $oz = $z; my $dxdt = undef; my $dydt = undef;
  print $fh "\\pgfpathmoveto{";
  $dg->write_point($x, $y);
  print $fh "}\n";
  for(my $i = 1; $i <= $#$pp; $i++) {
    $pref = $pp->[$i];
    $x = $pref->[0]; $y = $pref->[1]; $z = $pref->[2];
    $dxdt = $x - $ox;
    print $fh "\\pgfpathcurveto{";
    $dydt = $oz * $dxdt;
    $dg->write_point(($ox + ($dxdt/3.0)), ($oy + ($dydt/3.0)));
    print $fh "}{";
    $dydt = $z * $dxdt;
    $dg->write_point(($x - ($dxdt/3.0)), ($y - ($dydt/3.0)));
    print $fh "}{";
    $dg->write_point($x, $y);
    print $fh "}\n";
    $ox = $x; $oy = $y; $oz = $z;
  }
  print $fh "\\pgfusepath{stroke}\n";
  return $self;
}



sub some_values_without_derivative
{
  my $self = shift; my $dg = shift; my $pp = shift;
  my $N = $#$pp + 1;		# Number of points
  my $nsegs = $N - 1;		# Number of segments
  my $neqs = 4 * $nsegs;	# Number of equations and coefficients
  my $eqnno;			# Current equation
  my $pref;			# Reference to current point
  my $j;			# Number index
  my $i;			# Index of pref
  my $x;			# X coordinate
  my $y;			# Y coordinate
  my $z;			# first derivative (dy/dx)
  my $mtx = zeros($neqs, $neqs);	# Coefficients of eq sys
  my $rve = zeros(1, $neqs);		# Results vector of eq sys
  # nsegs: 0 ... nsegs-1
  for($j = 0; $j < $nsegs; $j++) {
    $eqnno = $j; $i = $j;
    $pref = $pp->[$i]; $x = $pref->[0]; $y = $pref->[1];
    $rve->set(0, $eqnno, $y);
    $mtx->set((4*$j), $eqnno, ($x * $x * $x));
    $mtx->set((4*$j+1), $eqnno, ($x * $x));
    $mtx->set((4*$j+2), $eqnno, $x);
    $mtx->set((4*$j+3), $eqnno, 1.0);
  }
  # nsegs: nsegs ... 2*nsegs-1
  for($j = 0; $j < $nsegs; $j++) {
    $eqnno = $nsegs + $j; $i = $j + 1;
    $pref = $pp->[$i]; $x = $pref->[0]; $y = $pref->[1];
    $rve->set(0, $eqnno, $y);
    $mtx->set((4*$j), $eqnno, ($x * $x * $x));
    $mtx->set((4*$j+1), $eqnno, ($x * $x));
    $mtx->set((4*$j+2), $eqnno, $x);
    $mtx->set((4*$j+3), $eqnno, 1.0);
  }
  # nsegs-1: 2*nsegs ... 3*nsegs-2
  for($j = 0; $j < ($nsegs - 1); $j++) {
    $eqnno = 2 * $nsegs + $j; $i = $j + 1;
    $pref = $pp->[$i]; $x = $pref->[0]; $y = $pref->[1];
    $mtx->set((4*$j), $eqnno, (3.0 * $x * $x));
    $mtx->set((4*$j+1), $eqnno, (2.0 * $x));
    $mtx->set((4*$j+2), $eqnno, 1.0);
    $mtx->set((4*$i), $eqnno, (-3.0 * $x * $x));
    $mtx->set((4*$i+1), $eqnno, (-2.0 * $x));
    $mtx->set((4*$i+2), $eqnno, -1.0);
  }
  # nsegs-1: 3*nsegs-1 ... 4*nsegs-3
  for($j = 0; $j < ($nsegs - 1); $j++) {
    $eqnno = 3 * $nsegs - 1 + $j; $i = $j + 1;
    $pref = $pp->[$i]; $x = $pref->[0]; $y = $pref->[1];
    if($#$pref > 1) {
      $z = $pref->[2];
      $mtx->set((4*$j), $eqnno, (3.0 * $x * $x));
      $mtx->set((4*$j+1), $eqnno, (2.0 * $x));
      $mtx->set((4*$j+2), $eqnno, 1.0);
      $rve->set(0, $eqnno, $z);
    } else {
      $mtx->set((4*$j), $eqnno, (6.0 * $x));
      $mtx->set((4*$j+1), $eqnno, 2.0);
      $mtx->set((4*$i), $eqnno, (-6.0 * $x));
      $mtx->set((4*$i+1), $eqnno, -2.0);
    }
  }
  # 4*nsegs-2
  $eqnno = 4 * $nsegs - 2; $j = 0; $i = 0;
  $pref = $pp->[$i]; $x = $pref->[0]; $y = $pref->[1];
  if($#$pref > 1) {
    $z = $pref->[2];
    $mtx->set((4*$j), $eqnno, (3.0 * $x * $x));
    $mtx->set((4*$j+1), $eqnno, (2.0 * $x));
    $mtx->set((4*$j+2), $eqnno, 1.0);
    $rve->set(0, $eqnno, $z);
  } else {
    $mtx->set((4*$j), $eqnno, (6.0 * $x));
    $mtx->set((4*$j+1), $eqnno, 2.0);
  }
  # 4*nsegs-1
  $eqnno = 4 * $nsegs - 1; $j = $nsegs - 1; $i = $j + 1;
  $pref = $pp->[$i]; $x = $pref->[0]; $y = $pref->[1];
  if($#$pref > 1) {
    $z = $pref->[2];
    $mtx->set((4*$j), $eqnno, (3.0 * $x * $x));
    $mtx->set((4*$j+1), $eqnno, (2.0 * $x));
    $mtx->set((4*$j+2), $eqnno, 1.0);
    $rve->set(0, $eqnno, $z);
  } else {
    $mtx->set((4*$j), $eqnno, (6.0 * $x));
    $mtx->set((4*$j+1), $eqnno, 2.0);
  }
  my $res = $mtx->inv() x $rve;
  if($self->{'debug'}) {
    print $res;
  }
  my @ppb; my $nppb = 0;
  for($i = 0; $i <= $#$pp; $i++) {
    $pref = $pp->[$i];
    $x = $pref->[0]; $y = $pref->[1]; $z = 0.0;
    if($#$pref > 1) {
      $z = $pref->[2];
    } else {
      if($i > 0) {
        $z = 3.0 * $res->at(0, 4*($i-1)) * $x * $x
	     + 2.0 * $res->at(0, 4*($i-1)+1) * $x
	     + $res->at(0, 4*($i-1)+2);
      } else {
        $z = 3.0 * $res->at(0, 0) * $x * $x
	     + 2.0 * $res->at(0, 1) * $x
	     + $res->at(0, 2);
      }
    }
    $ppb[$i] = [ $x, $y, $z ];
  }
  $self->all_values_with_derivative($dg, \@ppb);
  return $self;
}



sub plot_points_curve
{
  my $self = shift; my $dg = shift;
  my @ppa; my $nppa = 0;
  my $aref = $self->{'pp'};
  my $pref = undef;
  my $ax = $self->{'ax'}; my $ay = $self->{'ay'};
  my $x = undef;
  my $y = undef;
  my $z = undef;
  my $value_without_derivative = 0;
  for(my $i = 0; $i <= $#$aref; $i++) {
    $pref = $aref->[$i];
    $z = undef;
    $x = $pref->[0]; $y = $pref->[1];
    if($#$pref > 1) {
      $z = $pref->[2]
           * $ay->value_to_derivative($y) / $ax->value_to_derivative($x);
    } else {
      $value_without_derivative = 1;
    }
    $x = $self->{'ax'}->value_to_coord($x);
    $y = $self->{'ay'}->value_to_coord($y);
    if(defined($z)) {
      $ppa[$nppa++] = [ $x, $y, $z ];
    } else {
      $ppa[$nppa++] = [ $x, $y ];
    }
  }
  my @ppb = sort { $a->[0] <=> $b->[0]; } @ppa;
  if($value_without_derivative) {
    $self->some_values_without_derivative($dg, \@ppb);
  } else {
    $self->all_values_with_derivative($dg, \@ppb);
  }
  return $self;
}



sub plot_param_points
{
  my $self = shift; my $dg = shift; my $fh = $dg->{'f1'};
  my $ar = $self->{'pp'};
  my $pr = undef;
  my $x = undef;
  my $y = undef;
  my $dt = $self->{'ds'};
  my $diameter = $self->{'dsz'} * 0.2 * 72.0 / 25.4;
  for(my $i = 0; $i <= $#$ar; $i++) {
    $pr = $ar->[$i];
    $x = $pr->[1];
    $y = $pr->[2];
    $x = $self->{'ax'}->value_to_coord($x);
    $y = $self->{'ay'}->value_to_coord($y);
    if($dt == 0) {
        $self->dot_circle($dg, $fh, $x, $y, $diameter);
    }
    if($dt == 1) {
        $self->dot_square($dg, $fh, $x, $y, $diameter);
    }
    if($dt == 2) {
        $self->dot_diamond($dg, $fh, $x, $y, $diameter);
    }
    if($dt == 3) {
        $self->dot_triangle($dg, $fh, $x, $y, $diameter);
    }
    if($dt == 4) {
        $self->dot_crosshair($dg, $fh, $x, $y, $diameter);
    }
    if($dt == 5) {
        $self->dot_pentagon($dg, $fh, $x, $y, $diameter);
    }
  }
  return $self;
}



sub plot_param_lines
{
  my $self = shift; my $dg = shift; my $fh = $dg->{'f1'};
  my $ar = $self->{'pp'};
  my $pr = undef;
  my $x = undef;
  my $y = undef;
  if($#$ar >= 1) {
    $pr = $ar->[0];
    $x = $self->{'ax'}->value_to_coord($pr->[1]);
    $y = $self->{'ax'}->value_to_coord($pr->[2]);
    print $fh "\\pgfpathmoveto{";
    $dg->write_point($x, $y);
    print $fh "}\n";
    for(my $i = 1; $i <= $#$ar; $i++) {
      $pr = $ar->[$i];
      $x = $self->{'ax'}->value_to_coord($pr->[1]);
      $y = $self->{'ax'}->value_to_coord($pr->[2]);
      print $fh "\\pgfpathlineto{";
      $dg->write_point($x, $y);
      print $fh "}\n";
    }
    print $fh "\\pgfusepath{stroke}\n";
  }
  return $self;
}



sub check_param_derivatives
{
  my $self = shift;
  my $back = 1;
  my $ar; my $pr;
  $ar = $self->{'pp'};
  for(my $i = 0; $i <= $#$ar; $i++) {
    $pr = $ar->[$i];
    if(!(defined($pr->[3]) && defined($pr->[4]))) {
      $back = 0; $i = $#$ar + 1;
    }
  }
  return $back;
}



sub do_param_with_all_derivatives
{
  my $self = shift;
  my $dg = shift;
  my $pp = shift;
  my $fh = $dg->{'f1'};
  my $ox; my $oy; my $odxdt; my $odydt; my $x; my $y; my $dxdt; my $dydt;
  my $pr;
  $pr = $pp->[0];
  $x = $pr->[1]; $y = $pr->[2]; $dxdt = $pr->[3]; $dydt = $pr->[4];
  print $fh "\\pgfpathmoveto{";
  $dg->write_point($x, $y);
  print $fh "}\n";
  $ox = $x; $oy = $y; $odxdt = $dxdt; $odydt = $dydt;
  for(my $i = 1; $i <= $#$pp; $i++) {
    $pr = $pp->[$i];
    $x = $pr->[1]; $y = $pr->[2]; $dxdt = $pr->[3]; $dydt = $pr->[4];
    print $fh "\\pgfpathcurveto{";
    $dg->write_point(($ox + $odxdt/3.0), ($oy + $odydt/3.0));
    print $fh "}{";
    $dg->write_point(($x - $dxdt/3.0), ($y - $dydt/3.0));
    print $fh "}{";
    $dg->write_point($x, $y);
    print $fh "}\n";
    $ox = $x; $oy = $y; $odxdt = $dxdt; $odydt = $dydt;
  }
  print $fh "\\pgfusepath{stroke}\n";
  return $self;
}


sub param_with_all_derivatives
{
  my $self = shift; my $dg = shift;
  my $fh = $dg->{'f1'};
  my @npp;
  my $ar = $self->{'pp'};
  my $pr;
  my $t; my $x; my $y; my $xx; my $yy;
  my $r = $self->{'r'};
  my $mint = $r->[0]; my $maxt = $r->[1];
  my $dTdt = ($maxt - $mint) / (1.0 * $self->{'i'});
  my $ax = $self->{'ax'}; my $ay = $self->{'ay'};
  for(my $i = 0; $i <= $#$ar; $i++) {
    $pr = $ar->[$i];
    $t = $pr->[0]; $x = $pr->[1]; $y = $pr->[2]; $xx = $pr->[3]; $yy = $pr->[4];
    $xx = $xx * $ax->value_to_derivative($x) * $dTdt;
    $yy = $yy * $ay->value_to_derivative($y) * $dTdt;
    $x  = $ax->value_to_coord($x);
    $y  = $ay->value_to_coord($y);
    $npp[$i] = [ $t, $x, $y, $xx, $yy ];
  }
  $self->do_param_with_all_derivatives($dg, \@npp);
  return $self;
}



sub find_missing_derivatives
{
  my $self = shift; my $dg = shift; my $pp = $self->{'pp'};
  my @npp;
  my $pr;
  my $t; my $x; my $y; my $xx; my $yy;
  my $N = $#$pp + 1;
  my $nsegs = $N - 1;
  my $ax = $self->{'ax'}; my $ay = $self->{'ay'};
  my $i;
  my $eqnno;
  for($i = 0; $i <= $#$pp; $i++) {
    $pr = $pp->[$i];
    $t = $pr->[0]; $x = $pr->[1]; $y = $pr->[2]; $xx = undef; $yy = undef;
    $x = $ax->value_to_coord($x);
    $y = $ay->value_to_coord($y);
    $npp[$i] = [ (1.0 * $i) , $x, $y, $xx, $yy ];
  }
  my $xmtx = zeros((4 * $nsegs), (4 * $nsegs));
  my $ymtx = zeros((4 * $nsegs), (4 * $nsegs));
  my $xres = zeros(1, (4 * $nsegs));
  my $yres = zeros(1, (4 * $nsegs));
  for($i = 0; $i < $nsegs; $i++) {
    $eqnno = $i;
    $pr = $npp[$i];
    $t = $pr->[0]; $x = $pr->[1]; $y = $pr->[2];
    $xres->set(0, $eqnno, $x);
    $xmtx->set((4 * $i), $eqnno, ($t*$t*$t));
    $xmtx->set((4 * $i + 1), $eqnno, ($t * $t));
    $xmtx->set((4 * $i + 2), $eqnno, $t);
    $xmtx->set((4 * $i + 3), $eqnno, 1.0);
    $yres->set(0, $eqnno, $y);
    $ymtx->set((4 * $i), $eqnno, ($t * $t * $t));
    $ymtx->set((4 * $i + 1), $eqnno, ($t * $t));
    $ymtx->set((4 * $i + 2), $eqnno, $t);
    $ymtx->set((4 * $i + 3), $eqnno, 1.0);
  }
  for($i = 0; $i < $nsegs; $i++) {
    $eqnno = $nsegs + $i;
    $pr = $npp[$i + 1];
    $t = $pr->[0]; $x = $pr->[1]; $y = $pr->[2];
    $xres->set(0, $eqnno, $x);
    $xmtx->set((4 * $i), $eqnno, ($t * $t * $t));
    $xmtx->set((4 * $i + 1), $eqnno, ($t * $t));
    $xmtx->set((4 * $i + 2), $eqnno, $t);
    $xmtx->set((4 * $i + 3), $eqnno, 1.0);
    $yres->set(0, $eqnno, $y);
    $ymtx->set((4 * $i), $eqnno, ($t * $t * $t));
    $ymtx->set((4 * $i + 1), $eqnno, ($t * $t));
    $ymtx->set((4 * $i + 2), $eqnno, $t);
    $ymtx->set((4 * $i + 3), $eqnno, 1.0);
  }
  for($i = 0; $i < ($nsegs - 1); $i++) {
    $eqnno = 2 * $nsegs + $i;
    $pr = $npp[$i + 1];
    $t = $pr->[0]; $x = $pr->[1]; $y = $pr->[2];
    $xmtx->set((4 * $i), $eqnno, (3.0 * $t * $t));
    $xmtx->set((4 * $i + 1), $eqnno, (2.0 * $t));
    $xmtx->set((4 * $i + 2), $eqnno, 1.0);
    $xmtx->set((4 * ($i + 1)), $eqnno, (-3.0 * $t * $t));
    $xmtx->set((4 * ($i + 1) + 1), $eqnno, (-2.0 * $t));
    $xmtx->set((4 * ($i + 1) + 2), $eqnno, -1.0);
    $ymtx->set((4 * $i), $eqnno, (3.0 * $t * $t));
    $ymtx->set((4 * $i + 1), $eqnno, (2.0 * $t));
    $ymtx->set((4 * $i + 2), $eqnno, 1.0);
    $ymtx->set((4 * ($i + 1)), $eqnno, (-3.0 * $t * $t));
    $ymtx->set((4 * ($i + 1) + 1), $eqnno, (-2.0 * $t));
    $ymtx->set((4 * ($i + 1) + 2), $eqnno, -1.0);
  }
  for($i = 0; $i < ($nsegs - 1); $i++) {
    $eqnno = 3 * $nsegs - 1 + $i;
    $pr = $npp[$i + 1];
    $t = $pr->[0]; $x = $pr->[1]; $y = $pr->[2];
    $xmtx->set((4 * $i), $eqnno, (6.0 * $t));
    $xmtx->set((4 * $i + 1), $eqnno, 2.0);
    $xmtx->set((4 * ($i + 1)), $eqnno, (-6.0 * $t));
    $xmtx->set((4 * ($i + 1) + 1), $eqnno, -2.0);
    $ymtx->set((4 * $i), $eqnno, (6.0 * $t));
    $ymtx->set((4 * $i + 1), $eqnno, 2.0);
    $ymtx->set((4 * ($i + 1)), $eqnno, (-6.0 * $t));
    $ymtx->set((4 * ($i + 1) + 1), $eqnno, -2.0);
  }
  $i = 0; $eqnno = 4 * $nsegs - 2;
  $pr = $npp[0];
  $t = $pr->[0]; $x = $pr->[1]; $y = $pr->[2];
  $xmtx->set((4 * $i), $eqnno, (6.0 * $t));
  $xmtx->set((4 * $i + 1), $eqnno, 2.0);
  $ymtx->set((4 * $i), $eqnno, (6.0 * $t));
  $ymtx->set((4 * $i + 1), $eqnno, 2.0);
  $i = $nsegs - 1; $eqnno = 4 * $nsegs - 1;
  $pr = $npp[$nsegs];
  $t = $pr->[0]; $x = $pr->[1]; $y = $pr->[2];
  $xmtx->set((4 * $i), $eqnno, (6.0 * $t));
  $xmtx->set((4 * $i + 1), $eqnno, 2.0);
  $ymtx->set((4 * $i), $eqnno, (6.0 * $t));
  $ymtx->set((4 * $i + 1), $eqnno, 2.0);
  my $xco = $xmtx->inv() x $xres;
  my $yco = $ymtx->inv() x $yres;
  for($i = 0; $i < $#npp; $i++) {
    $pr = $npp[$i];
    $t = $pr->[0]; $x = $pr->[1]; $y = $pr->[2];
    $xx = 3.0 * $xco->at(0, (4 * $i)) * $t * $t
          + 2.0 * $xco->at(0, (4 * $i + 1)) * $t
	  + $xco->at(0, (4 * $i + 2));
    $yy = 3.0 * $yco->at(0, (4 * $i)) * $t * $t
          + 2.0 * $yco->at(0, (4 * $i + 1)) * $t
	  + $yco->at(0, (4 * $i + 2));
    $pr->[3] = $xx; $pr->[4] = $yy;
  }
  $i = $#npp - 1;
  $pr = $npp[ $#npp ];
  $t = $pr->[0]; $x = $pr->[1]; $y = $pr->[2];
  $xx = 3.0 * $xco->at(0, (4 * $i)) * $t * $t
        + 2.0 * $xco->at(0, (4 * $i + 1)) * $t
	+ $xco->at(0, (4 * $i + 2));
  $yy = 3.0 * $yco->at(0, (4 * $i)) * $t * $t
        + 2.0 * $yco->at(0, (4 * $i + 1)) * $t
	+ $yco->at(0, (4 * $i + 2));
  $pr->[3] = $xx; $pr->[4] = $yy;
  $self->do_param_with_all_derivatives($dg, \@npp);
}



sub plot_param_curve
{
  my $self = shift; my $dg = shift;
  if($self->check_param_derivatives($dg)) {
    $self->param_with_all_derivatives($dg);
  } else {
    $self->find_missing_derivatives($dg);
  }
  return $self;
}



sub plot_xspline_curve
{
  my $self = shift;
  my $dg = shift;
  my $fh = $dg->{'f1'};
  my $xs = LaTeX::PGF::Diagram2D::Xspline->new();
  my @pp; my $npp = 0;
  my $ar = $self->{'pp'};
  my $ax = $self->{'ax'};
  my $ay = $self->{'ay'};
  my $x;
  my $y;
  my $s;
  my $dxdt;
  my $dydt;
  my $odxdt;
  my $odydt;
  my $ox;
  my $oy;
  my $b;		# Current start point of segment
  my $a;		# Left neighbour
  my $c;		# Current end point of segment
  my $d;		# Right neighbour
  my $pa; my $pb; my $pc; my $pd;
  for($npp = 0; $npp <= $#$ar; $npp++) {
    $pa = $ar->[$npp];
    $x = $pa->[0]; $y = $pa->[1];
    $s = -1.0;
    if($#$pa > 1) {
      $s = $pa->[2];
    }
    $x = $ax->value_to_coord($x);
    $y = $ay->value_to_coord($y);
    $pp[$npp] = [ $x, $y, $s ];
  }
  $ar = \@pp;
  my $subs = $self->{'xspline'}; ; my $i; my $t;
  for($b = 0; $b < $#pp; $b++) {
    $a = $b - 1; $c = $b + 1; $d = $b + 2;
    $pa = undef; $pb = undef; $pc = undef; $pd = undef;
    if($a >= 0) { $pa = $pp[$a]; }
    $pb = $pp[$b];
    $pc = $pp[$c];
    if($d <= $#pp) { $pd = $pp[$d]; }
    $xs->set_points($pa, $pb, $pc, $pd);
    $xs->calculate(0.0);
    $odxdt = $xs->{'ddtx'} / (1.0 * $subs);
    $odydt = $xs->{'ddty'} / (1.0 * $subs);
    $ox = $xs->{'x'}; my $oy = $xs->{'y'};
    if($b == 0) {
      print $fh "\\pgfpathmoveto{";
      $dg->write_point($ox, $oy);
      print $fh "}\n";
    }
    for($i = 1; $i < $subs; $i++) {
      $t = (1.0 * $i) / (1.0 * $subs);
      $xs->calculate($t);
      $x = $xs->{'x'}; $y = $xs->{'y'};
      $dxdt = $xs->{'ddtx'} / (1.0 * $subs);
      $dydt = $xs->{'ddty'} / (1.0 * $subs);
      print $fh "\\pgfpathcurveto{\n";
      $dg->write_point(($ox + ($odxdt / 3.0)), ($oy + ($odydt / 3.0)));
      print $fh "}{";
      $dg->write_point(($x - ($dxdt / 3.0)), ($y - ($dydt / 3.0)));
      print $fh "}{";
      $dg->write_point($x, $y);
      print $fh "}\n";
      $ox = $x; $oy = $y; $odxdt = $dxdt; $odydt = $dydt;
    }
    $t = 1.0;
    $xs->calculate($t);
    $x = $xs->{'x'}; $y = $xs->{'y'};
    $dxdt = $xs->{'ddtx'} / (1.0 * $subs);
    $dydt = $xs->{'ddty'} / (1.0 * $subs);
    print $fh "\\pgfpathcurveto{\n";
    $dg->write_point(($ox + ($odxdt / 3.0)), ($oy + ($odydt / 3.0)));
    print $fh "}{";
    $dg->write_point(($x - ($dxdt / 3.0)), ($y - ($dydt / 3.0)));
    print $fh "}{";
    $dg->write_point($x, $y);
    print $fh "}\n";
    $ox = $x; $oy = $y; $odxdt = $dxdt; $odydt = $dydt;
  }
  print $fh "\\pgfusepath{stroke}\n";
}



sub plot_to
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$plot->plot_to(diagram)";
  } else {
    $self = shift; my $dg = shift;
    $self->finish();
    my $color = 'black';
    if(defined($self->{'color'})) {
      $color = $self->{'color'};
    }
    $dg->set_color($color);
    my $pt = $self->{'t'};
    my $dt = $self->{'d'};
    if($pt == 0) {
      if($dt == 0) {
        $self->plot_points_points($dg);
      } else {
        if($dt == 1) {
	  $self->plot_points_points($dg);
	} else {
	  if($dt == 2) {
	    $self->plot_param_points($dg);
	  } else {
	    if($dt == 3) {
	      $self->plot_points_points($dg);
	    }
	  }
	}
      }
    } else {
      if($pt == 1) {
        if($dt == 0) {
	  $self->plot_points_curve($dg);
	} else {
	  if($dt == 1) {
	    $self->plot_points_curve($dg);
	  } else {
	    if($dt == 2) {
	      $self->plot_param_curve($dg);
	    } else {
	      if($dt == 3) {
	        $self->plot_xspline_curve($dg);
	      }
	    }
	  }
	}
      } else {
        if($pt == 2) {
	  if($dt == 0) {
	    $self->plot_points_lines($dg);
	  } else {
	    if($dt == 1) {
	      $self->plot_points_lines($dg);
	    } else {
	      if($dt == 2) {
	        $self->plot_param_lines($dg);
	      } else {
	        if($dt == 3) {
		  $self->plot_points_lines($dg);
		}
	      }
	    }
	  }
	}
      }
    }
  }
  return $self;
}


sub set_curve
{
  my $self = undef;
  if($#_ < 0) {
    croak "Usage: \$plot->set_lines()";
  } else {
    $self = shift; $self->{'t'} = 1;
  }
  return $self;
}


sub set_lines
{
  my $self = undef;
  if($#_ < 0) {
    croak "Usage: \$plot->set_lines()";
  } else {
    $self = shift; $self->{'t'} = 2;
  }
  return $self;
}



sub set_dots
{
  my $self = undef;
  if($#_ < 0) {
    croak "Usage: \$plot->set_dots([dotstyle])";
  } else {
    $self = shift; $self->{'t'} = 0; $self->{'ds'} = 0;
    if($#_ >= 0) {
      my $t = shift;
      if(("$t" eq "0") || ("$t" eq "c") || ("$t" eq "circle")) {
        $self->{'ds'} = 0;
      }
      if(("$t" eq "1") || ("$t" eq "s") || ("$t" eq "square")) {
        $self->{'ds'} = 1;
      }
      if(("$t" eq "2") || ("$t" eq "d") || ("$t" eq "diamond")) {
        $self->{'ds'} = 2;
      }
      if(("$t" eq "3") || ("$t" eq "t") || ("$t" eq "triangle")) {
        $self->{'ds'} = 3;
      }
      if(("$t" eq "4") || ("$t" eq "cr") || ("$t" eq "crosshair")) {
        $self->{'ds'} = 4;
      }
      if(("$t" eq "5") || ("$t" eq "p") || ("$t" eq "pentagon")) {
        $self->{'ds'} = 5;
      }
      if($#_ >= 0) {
        $self->{'dsz'} = shift;
      }
    }
  }
  return $self;
}



sub debug
{
  my $self = undef;
  if($#_ >= 0) {
    $self = shift;
    my $msg = ""; my $i = 0;
    while($#_ > -1) {
      if($i) {
        $msg = "$msg " . shift;
      } else {
        $msg = shift;
      }
      $i++;
    }
    if($self->{'debug'}) {
      print "DEBUG $msg\n";
    }
  }
  return $self;
}



sub set_intervals
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$plot->set_intervals(number)";
  } else {
    $self = shift;
    my $n = shift;
    if($n < 1) {
      croak "ERROR: At least one interval is needed!";
    } else {
      $self->{'i'} = $n;
    }
  }
  return $self;
}



sub set_color
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$plot->set_color(color)";
  } else {
    $self = shift; $self->{'color'} = shift;
  }
  return $self;
}



sub set_xsplines_segments
{
  my $self = undef;
  if($#_ >= 1) {
    $self = shift; $self->{'xspline'} = shift;
  } else {
    croak "Usage: \$plot->set_xsplines_segments(num)";
  }
  return $self;
}



sub set_range
{
  my $self = undef;
  if($#_ >= 2) {
    $self = shift; my $min = shift; my $max = shift;
    $self->{'r'} = [ $min, $max ];
  } else {
    croak "Usage: \$plot->set_range(min, max)";
  }
  return $self;
}


1;

__END__


=head1 NAME

LaTeX::PGF::Diagram2D:: - Perl extension for drawing 2D diagrams (plot).

=head1 SYNOPSIS

  use LaTeX::PGF::Diagram2D;
  
  my $Uq = 1.0;
  my $Ri = 4.0;
  
  sub I($)
  {
    my $RL = shift;
    my $back = $Uq / ($Ri + $RL);
    return $back;
  }
  
  # 10 centimeters wide, 6 centimeters high 
  my $d = LaTeX::PGF::Diagram2D->new(10.0, 6.0);
  
  $d->set_font_size(12.0);
  
  # R (on the x axis) is in the range 0 ... 10
  $d->axis('b')->set_linear(0.0, 10.0)->set_grid_step(1.0)
	       ->set_tic_step(1.0);
  # I (on the y axis) is in the range 0 ... 0,3
  $d->axis('l')->set_linear(0.0,  0.3)->set_grid_step(0.05)
	       ->set_tic_step(0.1);
  
  my $p = $d->plot('b', 'l');
  $p->set_xy_fct(\&I);
  
  $d->write("test001a.pgf");


=head1 DESCRIPTION

Each object of the LaTeX::PGF::Diagram2D::Plot class represents one curve
or point set to plot. The object methods can be used to configure
the plot.

A LaTeX::PGF::Diagram2D::Plot object is created by calling a
LaTeX::PGF::Diagram2D object's plot() or copy_plot() method.
These methods create a new plot object and return a reference to it.

=head2 Data sources

set_xy_fct(fct [, derivative ])

sets the function to plot. Whenever possible you should specify the function
for the first derivative too.
Both functions must be implemented in your Perl program as a sub taking
one argument (x). The argument to set_xy_fct() is a reference to the sub.

set_parametric_fct(min, max, xfct, yfct [, xderivative, yderivative ])

chooses parametric plotting and sets the start and end value for the
parameter. The current value of the parameter is given to the xfct and
yfct function as argument to find coordinates and to xderivative and
yderivative to find the first derivative of x and y.

set_xy_points(arrayref)

chooses plotting of values. The argument to this function is an array
reference. Each array entry is a reference to an array containing the
coordinates of one point and optionally the first derivative in the point.

I<Note:> For set_xy_points(), set_xy_points_text() and set_xy_points_file()
the points must be sorted by rising x!

set_xy_points_text(text)

chooses plotting of values. The values are obtained from a text string.
Each line is either empty or contains the data for one
point: x value, y value and optionally dy/dx.

set_xy_points_file(filename)

chooses plotting of values. The values are obtained from a text file. Each
line is either empty or contains data for one point:
x value, y value and optionally dy/dx.

set_xsplines_points(arrayref [, s_default ])

chooses X-spline plotting. The argument to this function is a reference to an
array containing control point data. For each control point there is one
reference to an array. The control point array contains x value, y value
and optionally an s value. If the s value is omitted the default value
s_default is used or -1 if no s_default value was specified.

set_xsplines_points_text(text [, s_default ])

chooses X-spline plotting. Point values are obtained from a text string,
each line is either empty or contains one control point:
x value, y value and optionally s value.

set_xsplines_points_file(filename [, s_default ])

chooses X-spline plotting. Point values are obtained from a text file.
Each line in the file is either empty or contains one control point:
x value, y value and optionally s value.

set_xsplines_number(number)

sets the number of Bezier spline segments to create per X-spline segment.
X-splines are 5th grade curves, Bezier splines are 3rd grade curves.
So we use multiple Bezier spline segments to draw one X-spline segment.
Normally the default 8 is sufficient.

=head2 Configuring output

set_intervals(number)

specifies the number of curve intervals to print (for xy function plotting
and parametric function plotting).

set_curve()

sets output style to curve.

set_lines()

sets output style to polyline.

set_dots( [ style [, size ]])

sets output style to dots and chooses a style (``circle'', ``square'',
``diamond'', ``triangle'', ``crosshair'' or ``pentagon'') and dot size.
The dot size is specified as multiples of the line size (default: 5).

set_color(color)

chooses a color for the plot.

=head2 Preparing output

finish()

caluculates function and derivative values for function plotting
immediately. This is useful if your function uses a Perl variable as
function parameter and you want to change the variable.


=head1 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

Dirk Krause, E<lt>krause@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dirk Krause

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

