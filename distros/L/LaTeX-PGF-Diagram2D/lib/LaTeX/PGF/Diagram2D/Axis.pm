
package LaTeX::PGF::Diagram2D::Axis;

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
    croak "Usage: LaTeX::PGF::Diagram2D::Axis->new(width,height)";
  } else {
    my $class = shift;
    $self = {
      'min' => 0.0,	# Minimum value
      'max' => 0.0,	# Maximum value
      't' => 0,		# Type: 0=linear, 1=logarithmic
      'ts' => -1.0,	# Tic step
      'gs' => -1.0,	# Grid step
      'bo' => -1.0,	# Border
      'to' => -1.0,	# Tic offset
      'lo' => -1.0,	# Label offset
      'l' => undef,	# Label text
      'u' => undef,	# Unit text
      'dg' => undef,	# Diagram
      'used' => 0,	# Flag: used
      'n' => '',	# Name
      'color' => undef,	# Color
      'omit' => 0,	# Number of scale tics to omit for unit
    };
    bless($self, $class);
  }
  return $self;
}



sub set_grid_step
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$axis->set_grid_step(value)";
  } else {
    $self = shift; $self->{'gs'} = shift;
  }
  return $self;
}



sub set_tic_step
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$axis->set_tic_step(value)";
  } else {
    $self = shift; $self->{'ts'} = shift;
  }
  return $self;
}



sub set_linear
{
  my $self = undef;
  if($#_ < 2) {
    croak "Usage: \$axis->set_linear(min,max)";
  } else {
    $self = shift;
    $self->{'min'} = shift;
    $self->{'max'} = shift;
    $self->{'t'} = 0;
    if($self->{'max'} <= $self->{'min'}) {
      carp "Warning: Scale maximum should be larger than minimum!";
    }
  }
  return $self;
}


sub set_logarithmic
{
  my $self = undef;
  if($#_ < 2) {
    croak "Usage: \$axis->set_linear(min,max)";
  } else {
    $self = shift;
    $self->{'min'} = shift;
    $self->{'max'} = shift;
    $self->{'t'} = 1;
    if($self->{'min'} <= 0.0) {
      croak "ERROR: Only positive values allowed for logarithmic scales!";
    }
    if($self->{'max'} <= 0.0) {
      croak "ERROR: Only positive values allowed for logarithmic scales!";
    }
    if($self->{'max'} <= $self->{'min'}) {
      carp "Warning: Scale maximum should be larger than minimum!";
    }
  }
  return $self;
}


sub set_omit
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage \$axis->set_omit(number)";
  } else {
    $self = shift; $self->{'omit'} = shift;
  }
  return $self;
}



sub correct_if_necessary
{
  my $self = undef;
  my $debug = 0;
  if($#_ < 2) {
    croak "Usage: \$axis->correct_if_necessary(diagram,xyflag)";
  } else {
    $self = shift; my $dg = shift; my $xyflag = shift;
    if($#_ >= 0) { $debug = shift; }
    if($self->{'used'}) {
      if($self->{'to'} < 0.0) {
        if($dg->{'units'} == 1) {
	  $self->{'to'} = 0.2 / 2.54;
	} else {
	  if($dg->{'units'} == 2) {
	    $self->{'to'} = 0.2 * 72.0 / 2.54
	  } else {
	    $self->{'to'} = 0.2;
	  }
	}
      }
      if($self->{'lo'} < 0.0) {
        if($dg->{'units'} == 1) {
	  $self->{'lo'} = $self->{'to'} + 2.0 * $self->{'fs'} / 72.27;
	} else {
	  if($dg->{'units'} == 2) {
	    $self->{'lo'} = $self->{'to'}
	                    + 2.0 * 72.0 * $self->{'dg'}->{'fs'} / 72.27;
	  } else {
	    $self->{'lo'} = $self->{'to'}
	                    + 2.0 * 2.54 * $self->{'dg'}->{'fs'} / 72.27;
	  }
	}
      }
      if($self->{'bo'} < 0.0) {
        if($dg->{'units'} == 1) {
	  $self->{'bo'} = $self->{'to'} + 3.0 * $self->{'fs'} / 72.27;
	} else {
	  if($dg->{'units'} == 2) {
	    $self->{'bo'} = $self->{'to'}
	                    + 3.0 * 72.0 * $self->{'dg'}->{'fs'} / 72.27;
	  } else {
	    $self->{'bo'} = $self->{'to'}
	                    + 3.0 * 2.54 * $self->{'dg'}->{'fs'} / 72.27;
	  }
	}
      }
    } else {
      if($self->{'bo'} < 0.0) {
        if($dg->{'units'} == 1) {
	  $self->{'bo'} = 0.5 / 2.54;
	} else {
	  if($dg->{'units'} == 2) {
	    $self->{'bo'} = 0.5 * 72.0 / 2.54;
	  } else {
	    $self->{'bo'} = 0.5;
	  }
	}
      }
    }
  }
  if($debug) {
    print "DEBUG Axis->correct_if_necessary: " . $self->{'n'} . "\n";
    print "DEBUG bo = " . $self->{'bo'} . "\n";
    print "DEBUG to = " . $self->{'to'} . "\n";
    print "DEBUG lo = " . $self->{'lo'} . "\n";
  }
  return $self;
}



sub value_to_coord
{
  my $back = undef;
  if($#_ < 1) {
    croak "Usage: \$axis->value_to_coord(value)";
  } else {
    my $self = shift;
    my $value = shift;
    my $xmin; my $xmax;
    my $vmin = $self->{'min'}; my $vmax = $self->{'max'};
    if(($self->{'n'} eq 'l') || ($self->{'n'} eq 'r')) {
      $xmin = $self->{'dg'}->{'y3bp'};
      $xmax = $self->{'dg'}->{'y4bp'};
    } else {
      $xmin = $self->{'dg'}->{'x3bp'};
      $xmax = $self->{'dg'}->{'x4bp'};
    }
    if($self->{'t'}) {
      $back = $xmin
              + ((($xmax - $xmin) * (log($value/$vmin))) / (log($vmax/$vmin)));
    } else {
      $back = $xmin + ((($xmax - $xmin) * ($value - $vmin)) / ($vmax - $vmin));
    }
    $back = $self->{'dg'}->rd($back, 5);
  }
  return $back;
}


# dx/dX or dy/dY

sub value_to_derivative
{
  my $back = undef;
  if($#_ < 1) {
    croak "Usage: \$axis->value_to_derivative(value)";
  } else {
    my $self = shift;
    my $value = shift;
    my $xmin; my $xmax;
    my $vmin = $self->{'min'}; my $vmax = $self->{'max'};
    if(($self->{'n'} eq 'l') || ($self->{'n'} eq 'r')) {
      $xmin = $self->{'dg'}->{'y3bp'};
      $xmax = $self->{'dg'}->{'y4bp'};
    } else {
      $xmin = $self->{'dg'}->{'x3bp'};
      $xmax = $self->{'dg'}->{'x4bp'};
    }
    if($self->{'t'}) {			# logarithmic
      $back = ($xmax - $xmin) / ($value * log($vmax/$vmin));
    } else {				# linear
      $back = (($xmax - $xmin) / ($vmax - $vmin));
    }
    $back = $self->{'dg'}->rd($back, 5);
  }
  return $back;
}



sub coord_to_value
{
  my $back = undef;
  if($#_ < 1) {
    croak "Usage: \$axis->coord_to_value(coord)";
  } else {
    my $self = shift; my $coord = shift;
    my $xmin; my $xmax;
    my $vmin = $self->{'min'}; my $vmax = $self->{'max'};
    if(($self->{'n'} eq 'l') || ($self->{'n'} eq 'r')) {
      $xmin = $self->{'y3bp'}; $xmax = $self->{'y4bp'};
    } else {
      $xmin = $self->{'x3bp'}; $xmax = $self->{'x4bp'};
    }
    if($self->{'t'}) {
      $back = $vmin * exp(
        (log($vmax/$vmin) * ($coord - $xmin)) / ($xmax - $xmin)
      );
    } else {
      $back = $vmin + ((($vmax - $vmin) * ($coord - $xmin)) / ($xmax - $xmin));
    }
  }
  return $back;
}



sub set_unit
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$axis->set_unit(text)";
  } else {
    $self = shift; $self->{'u'} = shift;
  }
  return $self;
}



sub set_label
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$axis->set_label(text)";
  } else {
    $self = shift; $self->{'l'} = shift;
  }
  return $self;
}



sub set_tic_offset
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$axis->set_tic_offset(offset)";
  } else {
    $self = shift; $self->{'to'} = shift;
  }
  return $self;
}



sub set_label_offset
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$axis->set_tic_offset(offset)";
  } else {
    $self = shift; $self->{'lo'} = shift;
  }
  return $self;
}



sub set_border
{
  my $self = undef;
  if($#_ < 1) {
    croak "Usage: \$axis->set_tic_offset(offset)";
  } else {
    $self = shift; $self->{'bo'} = shift;
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



1;
__END__

=head1 NAME

LaTeX::PGF::Diagram2D::Axis - Perl extension for drawing 2D diagrams (axis).

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

Each object of this class represents one axis of the diagram, either
bottom, left, right or top axis.
The object methods can be used to configure the axis:

=head2 Axis values

set_linear(min, max)

sets a linear scale and assigns the specified minimum and maximum to the axis.

set_logarithmic(min, max)

uses a logarithmic scale. Both minimum and maximum must be positive.

=head2 Grid and tics

set_grid(step)

chooses the step size for the grid. Negative values are used to disable the
grid. A grid is only drawn for ``bottom'' and ``left'' axis.
For linear axes the step is added to the minimum, and again... to find
the values for grid positions.
For logarithmic axes the step is used as a factor.

set_tic_step(step)

chooses the step size for showing scale values.

=head2 Labels and units

set_label(text)

sets the axis label. Normally you should write this in LaTeX's math mode.

set_unit(text)

sets the text for the unit. Normally this is written upright.

set_omit(number)

decides whether or not to omit some scale values to free space to print
the unit.

Note: You must not omit scale value 0.

set_color(color)

sets the color for axis label and arrow. Choose a LaTeX color specification
like ``blue'' or ``blue!50!black''.

=head2 Distances and borders

set_tic_offset(offset)
setes the offset in cm between the canvas border and the right anchor of the
scale value texts. For ``top'' and ``bottom'' axis this is the distance
to the lower or upper text border.

If you use the right y axis you will have to correct this offset in most
cases.

set_label_offset(offset)

sets the offset between the canvas border and the center of the axis
label.

set_border(offset)

sets the offset between canvas border and image border.

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

