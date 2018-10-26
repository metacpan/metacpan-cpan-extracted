package Math::Function::Interpolator;

use 5.006;
use strict;
use warnings;

use Carp qw(confess);
use Scalar::Util qw(looks_like_number);

use Number::Closest::XS qw(find_closest_numbers_around);
use List::MoreUtils qw(pairwise indexes);
use List::Util qw(min max);

use Math::Function::Interpolator::Linear;
use Math::Function::Interpolator::Quadratic;
use Math::Function::Interpolator::Cubic;

=head1 NAME

Math::Function::Interpolator - Interpolation made easy

=head1 SYNOPSIS

    use Math::Function::Interpolator;

    my $interpolator = Math::Function::Interpolator->new(
        points => {1=>2,2=>3,3=>4}
    );

    $interpolator->linear(2.5);

    $interpolator->quadratic(2.5);

    $interpolator->cubic(2.5);

=head1 DESCRIPTION

Math::Function::Interpolator helps you to do the interpolation calculation with linear, quadratic and cubic methods.

1. Linear method (needs more than 1 data point)
1. Quadratic method (needs more than 2 data points)
1. Cubic method, it's a Cubic Spline method (needs more than 4 data points)

=head1 FIELDS

=head2 points (REQUIRED)

HashRef of points for interpolations

=cut

our $VERSION = '1.02';

=head1 METHODS

=head2 new

New instance method

=cut

sub new {    ## no critic (RequireArgUnpacking)
    my $class = shift;
    my %params_ref = ref($_[0]) ? %{$_[0]} : @_;

    confess "points are required to do interpolation"
        unless $params_ref{'points'};

    # We can't interpolate properly on undef values so make sure we know
    # they are missing by removing them entirely.
    my $points = $params_ref{points};
    $params_ref{points} = {
        map { $_ => $points->{$_} }
        grep { defined $points->{$_} } keys %$points
    };

    my $self = {
        _points        => $params_ref{'points'},
        _linear_obj    => 0,
        _cubic_obj     => 0,
        _quadratic_obj => 0
    };
    my $obj = bless $self, $class;

    return $obj;
}

=head2 points

points

=cut

sub points {
    my ($self) = @_;
    return $self->{'_points'};
}

=head2 linear

This method do the linear interpolation. It solves for point_y linearly given point_x and an array of points.
This method needs more than 1 data point.

=cut

sub linear {
    my ($self, $x) = @_;
    my $linear_obj = $self->{'_linear_obj'};
    if (!$linear_obj) {
        $linear_obj = Math::Function::Interpolator::Linear->new(points => $self->points);
        $self->{'_linear_obj'} = $linear_obj;
    }
    return $linear_obj->linear($x);
}

=head2 quadratic

This method do the quadratic interpolation. It solves the interpolated_y value given point_x with 3 data points.
This method needs more than 2 data point.

=cut

sub quadratic {
    my ($self, $x) = @_;
    my $quadratic_obj = $self->{'_quadratic_obj'};
    if (!$quadratic_obj) {
        $quadratic_obj = Math::Function::Interpolator::Quadratic->new(points => $self->points);
        $self->{'_quadratic_obj'} = $quadratic_obj;
    }
    return $quadratic_obj->quadratic($x);
}

=head2 cubic

This method do the cubic interpolation. It solves the interpolated_y given point_x and a minimum of 5 data points.
This method needs more than 4 data point.

=cut

sub cubic {
    my ($self, $x) = @_;
    my $cubic_obj = $self->{'_cubic_obj'};
    if (!$cubic_obj) {
        $cubic_obj = Math::Function::Interpolator::Cubic->new(points => $self->points);
        $self->{'_cubic_obj'} = $cubic_obj;
    }
    return $cubic_obj->cubic($x);
}

=head2 closest_three_points

 Returns the the closest three points to the sought point.
 The third point is chosen based on the point which is closer to mid point

=cut

sub closest_three_points {
    my ($self, $sought, $all_points) = @_;

    my @ap = sort { $a <=> $b } @{$all_points};
    my $length = scalar @ap;

    my ($first, $second) =
        @{find_closest_numbers_around($sought, $all_points, 2)};
    my @indexes = indexes { $first == $_ or $second == $_ } @ap;
    my $third_index =
        (max(@indexes) < $length - 2) ? max(@indexes) + 1 : min(@indexes) - 1;
    my @sorted = sort { $a <=> $b } ($first, $second, $ap[$third_index]);

    return @sorted;
}

=head1 AUTHOR

Binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-function-interpolator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Function-Interpolator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Function::Interpolator


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Function-Interpolator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Function-Interpolator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Function-Interpolator>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Function-Interpolator/>

=back


=head1 ACKNOWLEDGEMENTS

=cut

1;    # End of Math::Function::Interpolator
