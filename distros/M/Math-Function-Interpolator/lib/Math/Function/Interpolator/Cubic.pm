package Math::Function::Interpolator::Cubic;

use 5.006;
use strict;
use warnings FATAL => 'all';

our $VERSION = '1.01';    ## VERSION

our @ISA = qw(Math::Function::Interpolator);

use Carp qw(confess);
use List::MoreUtils qw(pairwise indexes);
use Number::Closest::XS qw(find_closest_numbers_around);
use Scalar::Util qw(looks_like_number);

=head1 NAME

Math::Function::Interpolator::Cubic

=head1 SYNOPSIS

    use Math::Function::Interpolator::Cubic;

    my $interpolator = Math::Function::Interpolator::Cubic->new(
        points => {1=>2,2=>3,3=>4,4=>5,5=>6,6=>7}
    );

    $interpolator->cubic(2.5);

=head1 DESCRIPTION

Math::Function::Interpolator::Cubic helps you to do the interpolation calculation with cubic method.
It solves the interpolated_y given point_x and a minimum of 5 data points.

=head1 FIELDS

=head2 points (REQUIRED)

HashRef of points for interpolations

=cut

sub _sorted_Xs {
    my ($self) = @_;
    return $self->{'_sorted_Xs'} if $self->{'_sorted_Xs'};
    $self->{'_sorted_Xs'} = [sort { $a <=> $b } keys %{$self->points}];
    return $self->{'_sorted_Xs'};
}

sub _spline_points {
    my ($self) = @_;

    return $self->{'_spline_points'} if $self->{'_spline_points'};

    my $points_ref = $self->points;
    my $Xs         = $self->_sorted_Xs;
    my @Ys         = map { $points_ref->{$_} } @$Xs;

    # First element is 0
    # Second derivative of the Ys
    my @y_2derivative = (0);
    my @u             = (0);
    my $counter       = @$Xs - 2;

    for my $i (1 .. $counter) {
        my $sig = ($Xs->[$i] - $Xs->[$i - 1]) / ($Xs->[$i + 1] - $Xs->[$i - 1]);
        my $p = $sig * $y_2derivative[$i - 1] + 2;
        $y_2derivative[$i] = ($sig - 1) / $p;
        $u[$i]             = ($Ys[$i + 1] - $Ys[$i]) / ($Xs->[$i + 1] - $Xs->[$i]) - ($Ys[$i] - $Ys[$i - 1]) / ($Xs->[$i] - $Xs->[$i - 1]);
        $u[$i]             = (($u[$i] * 6) / ($Xs->[$i + 1] - $Xs->[$i - 1]) - $sig * $u[$i - 1]) / $p;
    }

    # Last element is 0
    push @y_2derivative, 0;

    for (my $i = $counter; $i > 0; $i--) {
        $y_2derivative[$i] = $y_2derivative[$i] * $y_2derivative[$i + 1] + $u[$i];
    }

    my %y_2derivative_combined = pairwise { $a => $b } @$Xs, @y_2derivative;

    $self->{'_spline_points'} = \%y_2derivative_combined;

    return $self->{'_spline_points'};
}

sub _extrapolate_spline {
    my ($self, $args) = @_;
    my $x           = $args->{x};
    my $first       = $args->{first};
    my $second      = $args->{second};
    my $derivative2 = $args->{derivative2};

    my $derivative1 = (($second->{y} - $first->{y}) / ($second->{x} - $first->{x})) - (($second->{x} - $first->{x}) * $derivative2) / 6;

    return $first->{y} - ($first->{x} - $x) * $derivative1;
}

=head1 METHODS

=head2 cubic

cubic

=cut

# Returns the interpolated_y given point_x and a minimum of 5 data points
sub cubic {
    my ($self, $x) = @_;

    confess "sought_point[$x] must be a numeric" if !looks_like_number($x);
    my $ap = $self->points;
    return $ap->{$x} if defined $ap->{$x};    # No interpolation needed.

    my $Xs = $self->_sorted_Xs;
    confess "cannot interpolate with fewer than 5 data points"
        if scalar @$Xs < 5;

    my $splines = $self->_spline_points;

    my $y;
    if ($x < $Xs->[0] or $x > $Xs->[-1]) {
        my ($spline_key, $first, $second) =
            $x < $Xs->[0]
            ? ($Xs->[1], $Xs->[0], $Xs->[1])
            : ($Xs->[-2], $Xs->[-2], $Xs->[-1]);
        $y = $self->_extrapolate_spline({
                x           => $x,
                derivative2 => $splines->{$spline_key},
                first       => {
                    x => $first,
                    y => $ap->{$first},
                },
                second => {
                    x => $second,
                    y => $ap->{$second},
                },
            },
        );
    } else {
        my ($first, $second) = @{find_closest_numbers_around($x, $Xs, 2)};

        my $range = $second - $first;

        my $A = ($second - $x) / $range;
        my $B = 1 - $A;
        my $C = ($A**3 - $A) * ($range**2) / 6;
        my $D = ($B**3 - $B) * ($range**2) / 6;

        $y = $A * $ap->{$first} + $B * $ap->{$second} + $C * $splines->{$first} + $D * $splines->{$second};
    }

    return $y;
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

1;    # End of Math::Function::Interpolator::Cubic
