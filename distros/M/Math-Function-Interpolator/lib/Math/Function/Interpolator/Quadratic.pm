package Math::Function::Interpolator::Quadratic;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.02';    ## VERSION

our @ISA = qw(Math::Function::Interpolator);

use Carp qw(confess);
use Math::Cephes::Matrix qw(mat);
use Scalar::Util qw(looks_like_number);

=head1 NAME

Math::Function::Interpolator::Quadratic

=head1 SYNOPSIS

    use Math::Function::Interpolator::Quadratic;

    my $interpolator = Math::Function::Interpolator::Quadratic->new(
        points => {1=>2,2=>3,3=>4,4=>5,5=>6}
    );

    $interpolator->quadratic(2.5);

=head1 DESCRIPTION

Math::Function::Interpolator::Quadratic helps you to do the interpolation calculation with quadratic method.
It solves the interpolated_y given point_x and a minimum of 3 data points.

=head1 FIELDS

=head2 points (REQUIRED)

HashRef of points for interpolations

=head1 METHODS

=head2 quadratic

quadratic

=cut

# Returns the interpolated_y value given point_x with 3 data points
sub quadratic {
    my ($self, $x) = @_;

    confess "sought_point[$x] must be a number" unless looks_like_number($x);
    my $ap = $self->points;
    return $ap->{$x} if defined $ap->{$x};    # no need to interpolate

    my @Xs = keys %$ap;
    confess "cannot interpolate with fewer than 3 data points"
        if scalar @Xs < 3;

    my @points = $self->closest_three_points($x, \@Xs);

    # Three cofficient
    my $abc = mat([map { [$_**2, $_, 1] } @points]);

    my $y = [map { $ap->{$_} } @points];

    my $solution;
    eval { $solution = $abc->simq($y); 1 }
        or confess 'Insoluble matrix: ' . $_;
    my ($a, $b, $c) = @$solution;

    return ($a * ($x**2) + $b * $x + $c);
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

1;    # End of Math::Function::Interpolator::Quadratic
