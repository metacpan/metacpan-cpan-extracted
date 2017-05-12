
package LaTeX::PGF::Diagram2D::Polyline;

use 5.000000;
use strict;
use warnings;

use Carp;

our @ISA = qw();

our $VERSION = '1.00';


# Arguments:
# - diagram
# - polyline points

sub new
{
  my $self = undef;

  if($#_ < 4) {
    croak "Usage: LaTeX::PGF::Diagram2D::Polyline->new(diagram, xaxis, yaxis, pointsarrayref)";
  } else {
    my $class = shift;
    my $diagram = shift;
    my $ax = shift;
    my $ay = shift;
    my $points = shift;
    $self = {
      'p'	=>	$points,	# Point coordinates
      'c'	=>	'black',	# Color
      's'	=>	0,		# Line style
      'w'	=>	0.5,		# Linewidth factor
      'd'	=>	$diagram,	# Parent diagram
      'ax'	=>	$ax,		# X axis
      'ay'	=>	$ay,		# Y axis
    };
    bless($self, $class);
  }
  return $self;
}



sub set_color
{
  my $self = undef;
  if($#_ < 0) {
    croak "Usage: \$polyline->set_color(color)";
  } else {
    $self = shift; $self->{'c'} = shift;
  }
  return $self;
}



sub set_width
{
  my $self = undef;
  if($#_ < 0) {
    croak "Usage: \$polyline->set_width(widthfactor)";
  } else {
    $self = shift; $self->{'w'} = shift;
  }
  return $self;
}



sub plot
{
  my $self = shift;
  my $d = $self->{'d'};
  my $fh = $d->{'f1'};
  my $ax = $self->{'ax'}; my $ay = $self->{'ay'};
  my @p;
  my $ar = $self->{'p'};
  my $i = 0;
  for($i = 0; $i <= $#$ar; $i++) {
    $p[$i] = $d->value_to_coord($ax, $ay, $ar->[$i], $i);
  }
  $d->set_color($self->{'c'});
  $d->setlinewidth_mm( 0.2 * $self->{'w'} );
  $i = 0;
  while($i < $#p) {
    if($i) {
      print $fh "\\pgfpathlineto{";
      $d->write_point($p[$i], $p[$i+1]);
      print $fh "}\n";
    } else {
      print $fh "\\pgfpathmoveto{";
      $d->write_point($p[$i], $p[$i+1]);
      print $fh "}\n";
    }
    $i++; $i++;
  }
  print $fh "\\pgfusepath{stroke}\n";
  return $self;
}




1;
__END__


=head1 NAME

LaTeX::PGF::Diagram2D::Polyline - Perl extension for drawing 2D diagrams (polyline).

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

  my @polylinepoints = (
    0.0, 0.0,
    1.0, 0.3,
    2.0, 0.0,
    3.0, 0.3,
    4.0, 0.0
  );
  my $l = $d->polyine('b', 'l', \@polylinepoints);

  $l->set_color("black!50!blue");
  
  $d->write("test001a.pgf");


=head1 DESCRIPTION

Each object of the LaTeX::PGF::Diagram2D::Label class represents one
additional polyline drawn in the plot.
The LaTeX::PGF::Diagram2D object's polyline() method creates a new
LaTeX::PGF::Diagram2D::Polyline object and returns a reference to it.
This reference can be used for further setup (setting the color and width).

The set_color() method can be used to set the label color,
use a LaTeX color description as argument.

The set_width() method can be used to set the width.
The argument is a factor, n times the width of drawed curves.

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

