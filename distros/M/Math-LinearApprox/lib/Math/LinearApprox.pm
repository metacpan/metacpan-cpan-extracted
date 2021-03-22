#!/usr/bin/perl
#made by: KorG
# vim: sw=4 ts=4 et cc=79 :

package Math::LinearApprox;

use 5.008;
use strict;
use warnings FATAL => 'all';
use Carp;
use Exporter 'import';

our $VERSION = '0.02';
$VERSION =~ tr/_//d;

our @EXPORT_OK = qw( linear_approx linear_approx_str );

##
# @brief Model constructor
# @param __PACKAGE__
# @param (optional) ARRAYref with points to add ( x1, y1, x2, y2, ... )
# @return blessed reference to empty model
sub new {
    my $self = bless {
        x_sum => 0,
        y_sum => 0,
        N => 0,
        delta => 0,
    }, __PACKAGE__;

    # Handle array, if any
    if (ref $_[1] eq "ARRAY") {
        my $half = @{$_[1]} / 2;
        croak "Array has odd number of elements!" if int $half != $half;
        for (my $i = 0; $i < @{$_[1]}; $i += 2) {
            $self->add_point($_[1]->[$i], $_[1]->[$i + 1]);
        }
    } else {
        croak "Unknown argument specified!" if defined $_[1];
    }

    return $self;
}

##
# @brief Translate two points into line equation (coefficients)
# @param $_[0] X_1 coordinate
# @param $_[1] Y_1 coordinate
# @param $_[2] X_2 coordinate
# @param $_[3] Y_2 coordinate
# @return ($A, $B) for equation [y = Ax + B]
sub _eq_by_points {
    die "X_1 == X_2" if $_[0] == $_[2];

    my $A = ($_[3] - $_[1]) / ($_[2] - $_[0]);
    my $B = $_[3] - ($_[2] * ($_[3] - $_[1])) / ($_[2] - $_[0]);

    return ($A, $B);
}

##
# @brief Get numeric equation of model
# @param $_[0] self reference
# @return undef or ($A, $B) for equation [y = Ax + B]
sub equation {
    # Check conditions
    # - check points number
    return unless $_[0]->{N} > 1;
    # - handle vertical lines
    return if $_[0]->{x_last} == $_[0]->{x_0};

    # Calculate means
    my $M_delta = $_[0]->{delta} / ( $_[0]->{x_last} - $_[0]->{x_0} );
    my $M_x = $_[0]->{x_sum} / $_[0]->{N};
    my $M_y = $_[0]->{y_sum} / $_[0]->{N};

    # Translate them into a line
    my ($A, $B) = _eq_by_points($M_x, $M_y, $M_x + 1, $M_y + $M_delta);

    # Return coefficients
    return ($A, $B);
}

##
# @brief Get stringified equation of model
# @param $_[0] self reference
# @return die or String in forms: "y = A * x + B", "x = X"
sub equation_str {
    my ($A, $B) = $_[0]->equation();

    unless (defined $A) {
        die "Too few points in model!" if $_[0]->{N} == 0;

        # Calculate avg
        my $avg = $_[0]->{x_sum} / $_[0]->{N};
        return "x = $avg";
    }

    return "y = $A * x + $B";
}

##
# @brief Add new point to model
# @param $_[0] self reference
# @param $_[1] X coordinate
# @param $_[2] Y coordinate
# @return Nothing
sub add_point {
    # Save first point
    $_[0]->{x_0} = $_[1] unless defined $_[0]->{x_0};

    # Sum up Y deltas
    $_[0]->{delta} += $_[2] - $_[0]->{y_last} if $_[0]->{N} != 0;

    # Append the point to sums
    $_[0]->{x_sum} += $_[1];
    $_[0]->{y_sum} += $_[2];

    # Save right-most coordinates
    $_[0]->{x_last} = $_[1];
    $_[0]->{y_last} = $_[2];

    # Increase x, y counters
    $_[0]->{N}++;
}

##
# @brief Decorators for procedural style
sub linear_approx { return __PACKAGE__->new($_[0])->equation(); }
sub linear_approx_str { return __PACKAGE__->new($_[0])->equation_str(); }

1;

__END__

=pod

=encoding utf8

=head1 NAME

Math::LinearApprox - fast linear approximation of 2D sequential points

=head1 SYNOPSIS

    use Math::LinearApprox qw( linear_approx linear_approx_str );

    # OO style
    my @points = ( 0, 4 );
    my $la = Math::LinearApprox->new();
    my $la = Math::LinearApprox->new(\@points);
    $la->add_point( 2, 1 );
    $la->add_point( 7, 0 );
    print $la->equation_str();
    my ($A, $B) = $la->equation();

    # Procedural style
    my @points = ( 0, 4, 2, 1, 7, 0 );
    print linear_approx_str(\@points);

=head1 DESCRIPTION

Typically there are several methods of linear approximation in use to
approximate 2D points series, including least squares method.
All of them requires a lot of multiplication operations.

I have invented new numerical method which requires less complex instructions
and much more suitable for approximation of really huge arrays of data.
This method description and comparative analysis will be published in a
separate scientific paper soon.

Currently there is a requirement for all the points to be sorted by X axis.
Also currently this method uses all the points and does not include any
filtering abilities.  Hopefully, they will be added soon.

Each point should be specified by C<$x, $y> pair of coordinates.
You can either push the points from anywhere into the model -- they are not
being saved AS-IS -- or populate the model with C<@points = ($x, $y, ...)>
reference.

=head1 SUBROUTINES

=head2 add_point

To fill the model with data one can call C<$obj-E<gt>add_point( $x, $y )>.
This function returns nothing meaningful.
Perl will cast anything illegal passed as C<$x, $y> into numbers.
So it is your responsibility to validate your points in advance.

=over 4

=item C<$x> is X coordinate of the point.

=item C<$y> is Y coordinate of the point.

=back

=head2 equation

Since any line that is not perpendicular to X axis could be represented 
in a form of C<y = A * x + B>, then C<$obj-E<gt>equation()> returns
C<($A, $B)> coefficients.  The method returns undef unless the model could
not be represented in such a form.

=head2 equation_str

The C<$obj-E<gt>equation_str> returns stringified equation of the model either
in form C<"y = A * x + B">, or C<"x = X"> in case all points are vertically
distributed.  The method dies unless the model could not be approximated.
In most cases it is due to absense of points in the model.

=head2 linear_approx

The C<linear_approx( \@points )> is a procedural style alias for
C<new( \@points )-E<gt>equation()>.

=head2 linear_approx_str

The C<linear_approx_str( \@points )> is a procedural style alias for
C<new( \@points )-E<gt>equation_str()>.

=head2 new

C<$obj = Math::LinearApprox-E<gt>new()> is an object constructor
that will instantiate the approximation model.  The only parameter is 
optional -- reference to array of points: C<[$x1, $y1, $x2, $y2, ...]>.

=head1 AUTHOR

Sergei Zhmylev, C<E<lt>zhmylove@cpan.orgE<gt>>

=head1 BUGS

Please report any bugs or feature requests to official GitHub page at
L<https://github.com/zhmylove/math-linearapprox>.
You also can use official CPAN bugtracker by reporting to
C<bug-math-linearapprox at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-LinearApprox>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 INSTALLATION

To install this module, run the following commands:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Sergei Zhmylev.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

