
package LaTeX::PGF::Diagram2D::Label;

use 5.000000;
use strict;
use warnings;

use Carp;

our @ISA = qw();

our $VERSION = '1.00';


# Arguments:
# - diagram
# - x
# - y
# - text
# - (position)

sub new
{
  my $self = undef;

  if($#_ < 6) {
    croak "Usage: LaTeX::PGF::Diagram2D::Label->new(diagram, xaxis, yaxis, x, y, text[, pos])";
  } else {
    my $class = shift;
    my $diagram = shift;
    my $ax = shift;
    my $ay = shift;
    my $x = shift;
    my $y = shift;
    my $t = shift;
    my $p = undef;
    if($#_ >= 0) {
      $p = shift;
    }
    $self = {
      'x'	=>	$x,		# X position
      'y'	=>	$y,		# Y position
      't'	=>	$t,		# Text
      'p'	=>	$p,		# Alignment
      'd'	=>	$diagram,	# Diagram
      'c'	=>	'black',	# Color
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



sub plot
{
  my $self = shift;
  my $d = $self->{'d'};
  my $x = $d->value_to_coord(
    $self->{'ax'}, $self->{'ay'}, $self->{'x'}, 0
  );
  my $y = $d->value_to_coord(
    $self->{'ax'}, $self->{'ay'}, $self->{'y'}, 1
  );
  my $fh = $d->{'f1'};
  $d->set_color($self->{'c'});
  print $fh "\\pgftext[at={";
  $d->write_point($x, $y);
  print $fh "}";
  if(defined($self->{'p'})) {
    print $fh "," . $self->{'p'};
  }
  print $fh "]{";
  print $fh "" . $self->{'t'};
  print $fh "}";
  return $self;
}



1;
__END__


=head1 NAME

LaTeX::PGF::Diagram2D:: - Perl extension for drawing 2D diagrams (label).

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

  my $l = $d->label('b', 'l', 3.5, 0.175,
  "\\colorbox{white}{\\ovalbox{\\(R_{\\text{i}}=4\\,\\Omega\\)}}"
  );
  $l->set_color("black!50!blue");
  
  $d->write("test001a.pgf");


=head1 DESCRIPTION

Each object of the LaTeX::PGF::Diagram2D::Label class represents one
additional text label drawn in the plot.
The LaTeX::PGF::Diagram2D object's label() method creates a new
LaTeX::PGF::Diagram2D::Label object and returns a reference to it.
This reference can be used for further setup (setting the color).

The set_color() method can be used to set the label color,
use a LaTeX color description as argument.

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

