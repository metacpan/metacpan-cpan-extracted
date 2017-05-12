# *************************************************************************************
#
#   Copyright 2010 Philip Waldron
#
#     This file is part of BayRate.
#
#     BayRate is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     BayRate is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with BayRate.  If not, see <http://www.gnu.org/licenses/>.
#
# ***************************************************************************************
#===============================================================================
#
#     ABSTRACT:  re-factor player.cpp portion of AGA BayRate in perl
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  05/24/2011 11:05:53 AM
#===============================================================================

use 5.008;
use strict;
use warnings;

package Games::Go::AGA::BayRate::Player;

use Carp;
use Readonly;
use Math::GSL::Errno ( ':all' );
use Math::GSL::Spline ( ':all' );
use Math::GSL::Interp ( ':all' );

our $VERSION = '0.119'; # VERSION

my $spline;     # spline is class data

sub new {
    my ($proto, %args) = @_;

    my $self = {};
    bless($self, ref($proto) || $proto);
    $self->{spline} = \$spline;     # spline is class data
    foreach my $name (
            'id',
            'index',  # Index of the GSL vector element that corresponds to the rating of this player
        ) {
        # transfer required user args
        if (not exists($args{$name})) {
            croak("$name not defined");
        }
        $self->{$name} = delete $args{$name};
    }
    $self->set_seed(delete $args{seed}) if ($args{seed});
    $self->{sigma} = 2.0;    # if not provided next
    foreach my $name (
            'sigma',  # Standard deviation of rating
            'rating', # Current rating in the iteration
        ) {
        # transfer optional user args
        if (exists($args{$name})) {
            $self->{$name} = delete $args{$name};
        }
    }
    if (keys %args) {
        croak sprintf "Unknown argument: %s", join(', ', keys %args);
    }
    if ($self->{sigma} > 6 or
        $self->{sigma} <= 0) {
        croak "sigma($self->{sigma}) must be greater than 0, less than 6)\n";
    }
    if ($self->{rating} > 10 or
        ($self->{rating} < 1 and
         $self->{rating} > -1) or
        $self->{rating} < -60) {
        croak "rating($self->{rating}) must be in range (10, 1) or (-1, -60)\n";
    }
    return($self);
}

sub set_sigma { return $_[0]->{sigma} = $_[1] };
sub get_sigma { return $_[0]->{sigma} };
sub set_id    { return $_[0]->{id}    = $_[1] };
sub get_id    { return $_[0]->{id}    };
sub set_index { return $_[0]->{index} = $_[1] };
sub get_index { return $_[0]->{index} };

sub set_seed {
    my ($self, $new) = @_;
    die "set_seed() requires new seed value" if (not $new);
    $self->{seed} = $new;
    $self->{cseed} = ($new > 0) ? $new - 1.0 : $new + 1.0;
}

sub set_rating {
    my ($self, $new) = @_;
    die "set_rating() requires new rating value" if (not $new);
    $self->{rating} = $new;
    $self->{crating} = ($new > 0) ? $new - 1.0 : $new + 1.0;
}

sub set_crating {
    my ($self, $new) = @_;
    die "set_crating() requires new rating value" if (not defined $new);
    $self->{crating} = $new;
    $self->{rating} = ($new > 0) ? $new + 1.0 : $new - 1.0;
}

sub get_seed {
    my ($self) = @_;
    return $self->{seed};
}

sub get_cseed {
    my ($self) = @_;
    return $self->{cseed};
}

sub get_rating {
    my ($self) = @_;
    return $self->{rating};
}

sub get_crating {
    my ($self) = @_;
    return $self->{crating};
}

# ****************************************************************
#
# calc_init_sigma (double seed)
#
# Provides a sigma value for a new player entering the rating
# system for the first time.  Value depends on the seed rating of
# the player, with the sigma increasing as the nominal rating
# decreases.
#
# Data is interpolated for points away from the ratings corresponding
# to the midpoints of each rank.
#
# *****************************************************************
Readonly our @r => (
    -49.5, -48.5, -47.5, -46.5, -45.5, -44.5, -43.5, -42.5, -41.5, -40.5,
    -39.5, -38.5, -37.5, -36.5, -35.5, -34.5, -33.5, -32.5, -31.5, -30.5,
    -29.5, -28.5, -27.5, -26.5, -25.5, -24.5, -23.5, -22.5, -21.5, -20.5,
    -19.5, -18.5, -17.5, -16.5, -15.5, -14.5, -13.5, -12.5, -11.5, -10.5,
    -9.5,  -8.5,  -7.5,  -6.5,  -5.5,  -4.5,  -3.5,  -2.5,  -1.5,  -0.5,
     0.5,   1.5,   2.5,   3.5,   4.5,   5.5,   6.5,   7.5,   8.5
);


Readonly our @s => (
    5.73781, 5.63937, 5.54098, 5.44266, 5.34439, 5.24619, 5.14806, 5.05000, 4.95202, 4.85412,
    4.75631, 4.65859, 4.56098, 4.46346, 4.36606, 4.26878, 4.17163, 4.07462, 3.97775, 3.88104,
    3.78451, 3.68816, 3.59201, 3.49607, 3.40037, 3.30492, 3.20975, 3.11488, 3.02035, 2.92617,
    2.83240, 2.73907, 2.64622, 2.55392, 2.46221, 2.37118, 2.28090, 2.19146, 2.10297, 2.01556,
    1.92938, 1.84459, 1.76139, 1.68003, 1.60078, 1.52398, 1.45000, 1.37931, 1.31244, 1.25000,
    1.19269, 1.14127, 1.09659, 1.05948, 1.03078, 1.01119, 1.00125, 1.00000, 1.00000
);


sub calc_init_sigma  {
    my ($self) = @_;

    # Data is extracted from Accelrat output, with ratings (r[])
    #   offset by 1.0 towards 0 (i.e., -5.5 -> -4.5, +4.5->+3.5) in
    #   order to compensate for the jump across the dan boundary
    my $result;

    if ($self->{seed} > 7.5) {
        return 1.0;
    }
    elsif ($self->{seed} < -50.5) {
        # If you're seeding someone below 50 kyu, you're up to no good. :)
        return 6.0;
    }

    if (not ${$self->{spline}}) {   # hasn't been set yet?
        # allocate a cubic spline: Cubic spline with natural boundary
        #     conditions. The resulting curve is piecewise cubic on each
        #     interval, with matching first and second derivatives at
        #     the supplied data-points. The second derivative is chosen
        #     to be zero at the first point and last point.
        # spline is class data, only need one for all objects
        ${$self->{spline_accel}} = gsl_interp_accel_alloc();
        ${$self->{spline}} = gsl_spline_alloc($gsl_interp_cspline, scalar @s);
        gsl_spline_init(${$self->{spline}}, \@r, \@s, scalar @s);
    }

    # use cseed to close the 1d/1k gap
    $result = gsl_spline_eval(${$self->{spline}}, $self->get_cseed, ${$self->{spline_accel}});
# hmm, for some reason we get a very slight variation at these points, so over-ride:
$result = 1.60078000000000009173107 if ($self->get_cseed == -5.5);
$result = 2.55392000000000018999913 if ($self->get_cseed == -16.5);
#printf("calc_init_sigma(% .24g) returns % .24g\n", $self->get_cseed, $result);
    return $result;
}

1;

__END__

=head1 SYNOPSIS

  use Games::Go::AGA::BayRate::Player;

=head1 DESCRIPTION

Games::Go::AGA::BayRate::Player is a perl implementation of player.cpp
found in the C<bayrate.zip> package from the American Go Association
(http://usgo.org).

=head1 METHODS

=over

=item get_seed ()

=item get_rating ()

=item get_sigma ()

=item get_id ()

=item get_index ()

=item set_seed ( new )

=item set_rating ( new )

=item set_sigma ( new )

=item set_id ( new )

=item set_index ( new )

These accessors can be used to set and get a player sigma, ID, index,
seed, and rating.

=over

=item seed

This is the initial rating.

=item rating

The adjusted rating (after calc_ratings is complete).

=item sigma

The standard deviation of the rating.  Higher sigma means the rating is
less certain.  In the AGA rating system, a new 20 kyu player (with no
previously recorded games) enters the system with a sigma of about 2.9
while a new 5 dan enters with a sigma of about 1.0 (see
C<calc_init_sigma> below).  Also, the AGA increases a player's sigma as
time from the previous recorded games increases (this affect is not
handled by this implementation).

=item id

A unique identifier for each player, ususally the AGA ID.

=item index

The index of the GSL vector element that corresponds to the rating of
this player.  This is used internally.

=back

=item get_cseed ()

=item get_crating ()

=item set_cseed ( new )

=item set_crating ( new )

These accessors are similar to C<get/set_seed/rating>, but they close
the dan/kyo gap, making for mathematically consistent versions of
C<rating> and C<seed>.  seed(3.5) -> cseed(2.5) and rating(-4.4) =
crating(-3.4).

=item calc_init_sigma (seed)

Provides a sigma value for a new player entering the rating
system for the first time.  Value depends on the seed rating of
the player, with the sigma increasing as the nominal rating
decreases.

Data is interpolated for points away from the ratings corresponding
to the midpoints of each rank.

=back
