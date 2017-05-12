=head1 NAME

Math::Volume::Rotational - Volume of rotational bodies 

=head1 SYNOPSIS

  use Math::Volume::Rotational qw/volume_x volume_y/;
  
  my $volume = volume_rot_x( '(2-x^2)^0.5', -2, 2 );
  
  # equivalent:
  use Math::Symbolic qw/parse_from_string/;
  my $formula = parse_from_string('(2-x^2)^0.5');
  $volume = volume_rot_x($formula, -2, 2);
  
  # The above calculates the volume of a sphere of radius 2 by rotating
  # the half-circle of radius 2 around the x-axis.
  # This is equivalent to the well-known formula "4/3*pi*radius^3".
  
  # volume_rot_y works similar by rotating around the y-axis.

=head1 DESCRIPTION

This module calculates the volume of rotational bodies. These are bodies
resulting from the rotation of a portion of a 2D function around an axis.

Please note that rotations around an axis other than either x- or y-axis
are considered highly experimental at this point.

=head2 EXPORT

None by default, but you may choose to have any of the following subroutines
exported to the calling namespace via standard Exporter semantics:

  volume_rot_x
  volume_rot_y
  volume_rot_arb

Additionally, you may use the export tag ':all' to export all of the above.

=head1 SUBROUTINES

=cut

package Math::Volume::Rotational;

use 5.006;
use strict;
use warnings;

use Carp;

use constant PI => 3.141592653589793238462643;
use Math::Integral::Romberg 'integral';
use Math::Symbolic qw/parse_from_string/;
use Math::Symbolic::Compiler;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	'all' => [ qw(
		volume_rot_x
		volume_rot_y
		volume_rot_arb
	) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT;

our $VERSION = '0.11';



=head2 volume_rot_x

Calculates the volume of a rotational body by rotatinf a the portion of
a function graph around the x-axis. The function graph is integrated from
a lower to an upper boundary.

Expects a Math::Symbolic tree or a string to be parsed as such as first
argument. Second argument must be the lower boundary, third must be the
upper parameter boundary.

=cut

sub volume_rot_x {
	my ($function, $lower, $upper) = @_;

	$function = parse_from_string($function)
	  if not ref($function) =~ /^Math::Symbolic/;

	my @sig = $function->signature();
	croak "Function has to be a scalar function" if @sig > 1;
	
	$function = $function ** 2;
	my($compiled) = $function->to_sub();

	return PI * integral($compiled, $lower, $upper);
}



=head2 volume_rot_y

Works the same as volume_rot_x. It calculates the volume of a rotational
body by rotating a the portion of
a function graph around the y-axis. The function graph is integrated from
a lower to an upper boundary.

Expects a Math::Symbolic tree or a string to be parsed as such as first
argument. Second argument must be the lower boundary, third must be the
upper parameter boundary.

=cut

sub volume_rot_y {
	my ($function, $lower, $upper) = @_;

	$function = Math::Symbolic::parse_from_string($function)
	  if not ref($function) =~ /^Math::Symbolic/;

	my @sig = $function->signature();
	croak "Function has to be a scalar function" if @sig > 1;
	my $var = (@sig ? $sig[0] : 'x');
	$function = Math::Symbolic::Operator->new(
		'partial_derivative',
		$function,
		Math::Symbolic::Variable->new($var)
	) * "$var^2";
	$function = $function->apply_derivatives()->simplify();
	my($compiled) = $function->to_sub();

	return PI * integral($compiled, $lower, $upper);
}



=head2 volume_rot_arb

Calculates the volume of a rotational
body by rotating a portion of
a function graph around an arbitrary axis in R^2.
The function graph is integrated from a lower to an upper boundary.
volume_rot_arb takes named arguments:

=over 4

=item function

This is the function to integrate over. It must be a Math::Symbolic tree
or a string to be parsed as such. Needs to be a scalar function.
This is a mandatory argument.

=item var

Indicates the name of the variable to use for integration. This is an
optional argument if the variable can be inferred from the function.

=item lower_boundary_function

This optional argument indicates a function to subtract from the integration
function before integration. Thus, you can calculate the volume of a hollow
sphere of a given thickness.

=item axis_y

Mandatory argument indicating the y value of the axis to rotate around at
x=0.

=item axis_slope

Indicates the slope of the axis in R^2. Mandatory argument.

=item lower

The lower boundary for integration. Mandatory argument.

=item upper

The upper boundary for integration. Mandatory argument.

=back

=cut

sub volume_rot_arb {
	my %args = @_;
	my $var = $args{var};
	my $f1 = $args{function};
	my $f2 = $args{lower_boundary_function};
	my $y = $args{axis_y};
	my $slope = $args{axis_slope};
	my $lower = $args{lower};
	my $upper = $args{upper};

	croak "'function' is a mandatory named argument to volume_rot_arb"
	  if not defined $f1;
	croak "'lower' is a mandatory named argument to volume_rot_arb"
	  if not defined $lower;
	croak "'upper' is a mandatory named argument to volume_rot_arb"
	  if not defined $upper;
	croak "'axis_y' is a mandatory named argument to volume_rot_arb"
	  if not defined $y;
	croak "'axis_slope' is a mandatory named argument to volume_rot_arb"
	  if not defined $slope;

	$f1 = parse_from_string($f1) if not ref($f1) =~ /^Math::Symbolic/;
	$f2 = parse_from_string($f2)
	  if defined $f2 and not ref($f2) =~ /^Math::Symbolic/;
	
	if (not defined $var) {
		my @sig = $f1->signature;
		if (@sig == 1) {
			$var = $sig[0];
		}
		else {
			croak "Could not infer integration variable";
		}
	}
	my $func = $f1;
	$func -= $f2 if defined $f2;
	my ($code) = $func->to_sub();
	my $area = integral($code, $lower, $upper);

	my $com = calculate_center_of_mass($func, $lower, $upper, $var, $area);

	my $dist = abs($com->[0] * (1-$slope) - $y) / sqrt(1 + $slope**2);

	my $volume = PI*$dist*$area;
}

sub calculate_center_of_mass {
	my $f = shift;
	my $l = shift;
	my $u = shift;
	my $v = shift;
	my $integral = shift;

	$f = parse_from_string($f) if not ref($f) =~ /^Math::Symbolic/;
	my ($c_f) = $f->to_sub();

	my $xf = $f * $v;
	my ($c_xf) = $xf->to_sub();

	my $fsq = $f ** 2;
	my ($c_fsq) = $fsq->to_sub();

	$integral = integral($c_f, $l, $u) if not defined $integral;
	
	my $s_x = integral($c_xf, $l, $u) / $integral;
	my $s_y = 0.5 * integral($c_fsq, $l, $u) / $integral;
	return [$s_x, $s_y];
}


1;
__END__

=head1 AUTHOR

Steffen Mueller, E<lt>volume-module at steffen-mueller dot netE<gt>

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN. The module development takes place on
Sourceforge at http://sourceforge.net/projects/math-symbolic/

L<Math::Symbolic>.

L<Math::Integral::Romberg>.

=cut
