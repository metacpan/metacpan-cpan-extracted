package Math::Function::Interpolator::Linear;

use 5.006;
use strict;
use warnings;

our @ISA = qw(Math::Function::Interpolator);

our $VERSION = '1.02';    ## VERSION

use Carp qw(confess);
use Number::Closest::XS qw(find_closest_numbers_around);
use Scalar::Util qw(looks_like_number);

=head1 NAME

Math::Function::Interpolator::Linear - Interpolation made easy

=head1 SYNOPSIS

    use Math::Function::Interpolator::Linear;

    my $interpolator = Math::Function::Interpolator::Linear->new(
        points => {1=>2,2=>3,3=>4}
    );

    $interpolator->linear(2.5);

=head1 DESCRIPTION

Math::Function::Interpolator::Linear helps you to do the interpolation calculation with linear method.
It solves for point_y linearly given point_x and an array of more than 2 data points.

=head1 FIELDS

=head2 points (REQUIRED)

HashRef of points for interpolations

=cut

=head1 METHODS

=head2 linear

linear

=cut

# Solves for point_y linearly given point_x and an array of points.
sub linear {
    my ($self, $x) = @_;

    confess "sought_point[$x] must be a number" unless looks_like_number($x);
    my $ap = $self->points;
    return $ap->{$x} if defined $ap->{$x};    # no need to interpolate

    my @Xs = keys %$ap;
    confess "cannot interpolate with fewer than 2 data points"
        if scalar @Xs < 2;

    my ($first, $second);
    ($first->{x}, $second->{x}) =
        @{find_closest_numbers_around($x, \@Xs, 2)};
    ($first->{y}, $second->{y}) =
        ($ap->{$first->{x}}, $ap->{$second->{x}});

    my $m = ($second->{y} - $first->{y}) / ($second->{x} - $first->{x});
    my $c = $first->{y} - ($first->{x} * $m);

    return $m * $x + $c;
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

1;    # End of Math::Function::Interpolator::Linear
