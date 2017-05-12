#*************************************************************************************
#
#     Copyright 2010 Philip Waldron
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
#***************************************************************************************
#===============================================================================
#
#     ABSTRACT:  re-factored game.cpp portion of AGA BayRate in perl
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  05/24/2011 11:05:53 AM
#===============================================================================

use 5.008;
use strict;
use warnings;

package Games::Go::AGA::BayRate::Game;

use Readonly;
use Carp;
use Math::GSL::SF ( ':all' );   # Special Functions (for sf_erfc)

our $VERSION = '0.119'; # VERSION

Readonly our @attr => (
    'komi',        # Komi
    'handicap',    # Actual handicap
    'whiteWins',   # True if White wins
    'white',       # white player
    'black',       # black player
);

sub new {
    my ($proto, %args) = @_;

    my $self = {};
    bless($self, ref($proto) || $proto);
    foreach my $name (@attr) {
        # transfer user args
        if (not exists($args{$name})) {
            croak("$name not defined");
        }
        $self->{$name} = delete $args{$name};
    }
    if (keys %args) {
        croak sprintf "Unknown argument: %s", join(', ', keys %args);
    }
    my $handicap = $self->get_handicap;
    my $komi = $self->get_komi;
    if (# NOTE: difference from AGA code here:
        # $handicap > 9 or      # inappropriate place to be enforcing this
        $handicap < 0) {
        croak "Handicap $handicap out of range (0-9)";
    }
    if ($handicap >=2 and
        ($komi >= 10 or
         $komi <= -10)) {
        croak "Komi($komi) for handicap $handicap must be in range (-10, 10)";
    }
    if ($handicap <= 1 and
        ($komi <= -20 or
         $komi >= 20)) {
        croak "Komi($komi) for handicap $handicap must be in range (-20, 20)";
    }
    return($self);
}

# make read accessor methods
foreach my $name (@attr) {
    no strict 'refs'; ## no critic
    *{"get_$name"} = sub {
        return shift->{$name};
    }
}

# these read accessor methods need a little extra
foreach my $name ('sigma_px',
                  'handicapeqv', # Equivalent rating adjustment based on handicap and komi
                ) {
    no strict 'refs'; ## no critic
    *{"get_$name"} = sub {
        my ($self) = @_;

        $self->calc_handicapeqv if (not exists($self->{$name}));
        return $self->{$name};
    }
}

# make write accessor methods
foreach my $name (qw(
            whiteWins
            komi
            handicap
        )) {
    no strict 'refs'; ## no critic
    *{"set_$name"} = sub {
        my ($self, $val) = @_;
        $self->{$name} = $val;
        delete $self->{sigma_px};
        delete $self->{handicapeqv};
        return shift->{$name};
    }
}

#****************************************************************
#
# calc_handicapeqv ()
#
# Calculates the equivalent rating difference for the handicap/komi
# conditions of this game.
#
#****************************************************************
Readonly our @sigma_add_from_handicap => (
    undef,
    undef,
    1.13672,    # case 2
    1.18795,    # case 3
    1.22841,    # case 4
    1.27457,    # case 5
    1.31978,    # case 6
    1.35881,    # case 7
    1.39782,    # case 8
    1.43614,    # case 9
);

sub calc_handicapeqv {
    my ($self) = @_;

    if ($self->{handicap} == 0 or
        $self->{handicap} == 1) {
        $self->{handicapeqv} = 0.580 - 0.0757 * $self->{komi};
        $self->{sigma_px} = 1.0649 - 0.0021976 * $self->{komi} + 0.00014984 * $self->{komi} * $self->{komi};
    }
    else {
        $self->{handicapeqv} = $self->{handicap} - 0.0757 * $self->{komi};
        my $sigma_add = $sigma_add_from_handicap[$self->{handicap}];
        if (not defined $sigma_add) {
            # NOTE: difference from AGA code here:
            # croak "handicap $self->{handicap} out of range"
            # this game has too large a handicap, make a rough guess:
            $sigma_add = 1.43614 + (($self->{handicap} - 9) * (1.43614 - 1.39782));
        }
        $self->{sigma_px} = -0.0035169 * $self->{komi};
        $self->{sigma_px} += $sigma_add;
    }
    croak "sigma_px is $self->{sigma_px}" if ($self->{sigma_px} <= 0);
}

Readonly our $SQRT_OF_TWO => sqrt(2.0);
# return probability of this game result based on players' seeds
sub seed_probability {
    my ($self) = @_;

    my $white = $self->get_white;
    my $black = $self->get_black;

    my $rd = $white->get_cseed - $black->get_cseed - $self->get_handicapeqv;

    if ($self->get_whiteWins) {
        $rd = -$rd;
    }
    return gsl_sf_erfc($rd / $self->get_sigma_px / $SQRT_OF_TWO) / 2.0;
}

1;

=head1 SYNOPSIS

  use Games::Go::AGA::BayRate::Game;

=head1 DESCRIPTION

Games::Go::AGA::BayRate::Game is a perl implementation of game.cpp
found in the C<bayrate.zip> package from the American Go Association
(http://usgo.org).

Most of the following documentation is shamelessly stolen directly from
C<game.cpp>.

=head1 METHODS

=over

=item get_komi ()

=item get_handicap ()

=item get_whiteWins ()

=item set_komi ( new )

=item set_handicap ( new )

=item set_whiteWins ( new )

=item get_white ()

=item get_black ()

=item get_sigma_px ()

=item get_handicapeqv ()

Accessors for getting and setting game attributes.  Attributes without a
'C<set_>' method must be created at C<->new(...)> time.

=item calc_handicapeqv ()

Calculates the equivalent rating difference for the handicap/komi
conditions of this game.  C<get_sigma_px()> and C<get_handicapeqv()>
call this if necessary.

=item seed_probability

Returns the probability of this game result based on players' seeds

=back
