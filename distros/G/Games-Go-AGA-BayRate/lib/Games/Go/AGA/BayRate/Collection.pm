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
#**************************************************************************************
#===============================================================================
#
#     ABSTRACT:  implementation of AGA BayRate (player ratings) Collection as perl object
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#        EMAIL:  reid@LucidPort.com
#      CREATED:  12/02/2010 08:51:22 AM PST
#===============================================================================

use 5.008;
use strict;
use warnings;
# this test apparently isn't smart enough to tell difference between object
#    attribute access and real hash-refs:
## no critic (ProhibitAccessOfPrivateData)

package Games::Go::AGA::BayRate::Collection;

use Readonly;
use Carp;
use Scalar::Util qw( refaddr );
use DateTime;
use Date::Parse;
use Games::Go::AGA::BayRate::Player;
use Games::Go::AGA::BayRate::Game;
# use Math::GSL qw( :all );
use Math::GSL::Permutation ( ':all' );
use Math::GSL::Matrix ( ':all' );
use Math::GSL::Vector ( ':all' );
use Math::GSL::Errno
    qw(
        $GSL_SUCCESS
        $GSL_CONTINUE
    );
use Math::GSL::Const ( ':all' ); # for various constants like $M_PI
use Math::GSL::Multimin          # for f(df)minimizer functions
    qw(
        $gsl_multimin_fdfminimizer_vector_bfgs2
        $gsl_multimin_fminimizer_nmsimplex
        gsl_multimin_fminimizer_iterate
        gsl_multimin_fminimizer_x
        gsl_multimin_fdfminimizer_iterate
        gsl_multimin_fdfminimizer_x
        gsl_multimin_test_size
        gsl_multimin_test_gradient
    );
use Math::GSL::SF ( ':all' );   # Special Functions (for sf_erfc)
use Math::GSL::Linalg ( ':all' );   # Linear Algebra (for gsl_linalg_LU_decomp)
use Games::Go::AGA::BayRate::GSL::Multimin qw(
    raw_gsl_vector_size
    my_gsl_multimin_fminimizer_set
    my_gsl_multimin_fdfminimizer_set
    raw_gsl_multimin_fdfminimizer_gradient
);

our $VERSION = '0.119'; # VERSION

# Set some constants
#Readonly our $M_SQRT2             => sqrt(2.0);
#Readonly our $M_LN2               => log(2.0);
#Readonly our $M_2_PI              => 2.0 / $M_PI;
Readonly our $SQRT_OF_2_TIMES_PI       => $M_SQRT2 * $M_SQRTPI;
Readonly our $SQRT_OF_2_DIVBY_PI       => sqrt($M_2_PI);
Readonly our $HALF_LOG_OF_TWO_TIMES_PI => 0.5 * gsl_sf_log(2.0 * $M_PI);

sub DEBUG_gsl_vector_set {
    my ($raw_vector, $idx, $val) = @_;
    printf("gsl_vector_set(x=%d, % .24g)\n", $idx, $val);
    gsl_vector_set($raw_vector, $idx, $val);
}

sub DEBUG_gsl_vector_get {
    my ($raw_vector, $idx) = @_;
    my $val = gsl_vector_get($raw_vector, $idx);
    printf("gsl_vector_get(x=%d) = % .24g\n", $idx, $val);
    return $val;
}

sub DEBUG_gsl_matrix_set {
    my ($raw_matrix, $idx_x, $idx_y, $val) = @_;
    printf("gsl_matrix_set(x=%d, y=%d, % .24g)\n", $idx_x, $idx_y, $val);
    gsl_matrix_set($raw_matrix, $idx_x, $idx_y, $val);
}

sub DEBUG_gsl_matrix_get {
    my ($raw_matrix, $idx_x, $idx_y) = @_;
    my $val = gsl_matrix_get($raw_matrix, $idx_x, $idx_y);
    printf("gsl_matrix_get(x=%d, y=%d) = % .24g\n", $idx_x, $idx_y, $val);
    return $val;
}

sub print_vector {
    my ($v, $count) = @_;

    $v = $v->raw if (not ref $v =~ 'Math::GSL::.*::gsl_vector');
    if (not $count or $count <= 0) {
        $count = raw_gsl_vector_size($v);
    }
    my $ii;
    for ($ii = 0; $ii < $count; $ii ++) {
        if ($ii % 10 == 0) { printf("%3d:", $ii); }
        printf(" % .24g", gsl_vector_get($v, $ii));
        if ($ii % 10 == 9) { print("\n"); }
    }
    if ($ii % 10 != 0) { print("\n"); }
}

# functions used by the GSL Minimizer:
sub DEBUG_f {
    my ($raw_v, $collection)  = @_;

    print("my_f v:\n"); print_vector($raw_v);
    my $pt = $collection->calc_pt($raw_v);
    printf("my_f returns % .24g\n", $pt);
    return -$pt;
}

sub DEBUG_df {
    my ($raw_v, $collection, $raw_df) = @_;

    print("my_df v:\n"); print_vector($raw_v);
    print("my_df df:\n"); print_vector($raw_df);
    $collection->calc_pt_df($raw_v, $raw_df);
    gsl_vector_scale($raw_df, -1.0);
    print("my_df returns v:\n"); print_vector($raw_v);
    print("my_df returns df:\n"); print_vector($raw_df);
}

sub DEBUG_fdf {
    my ($raw_v, $collection, $f, $raw_df) = @_;

    print("my_fdf v:\n"); print_vector($raw_v);
    print("my_fdf df:\n"); print_vector($raw_df);
    ${$f} = my_f($raw_v, $collection);
    my_df($raw_v, $collection, $raw_df);
    print("my_fdf returns v:\n"); print_vector($raw_v);
    print("my_fdf returns df:\n"); print_vector($raw_df);
    printf("my_fdf sets: \$f = % .24g\n", ${$f});
}

# same functions as previous three, but without debug prints
sub gsl_f {
    my ($raw_v, $collection)  = @_;

    my $pt = $collection->calc_pt($raw_v);
    return -$pt;
}

sub gsl_df {
    my ($raw_v, $collection, $raw_df) = @_;

    $collection->calc_pt_df($raw_v, $raw_df);
    gsl_vector_scale($raw_df, -1.0);
}

sub gsl_fdf {
    my ($raw_v, $collection, $f, $raw_df) = @_;

    ${$f} = my_f($raw_v, $collection);
    my_df($raw_v, $collection, $raw_df);
}

sub new {
    my ($proto, %args) = @_;

    # Initialize a random number generator
    # NOTE: we use a different method, see "Populate the storage vector"
    # $self->{rng} = gsl_rng_alloc(gsl_rng_default);

    my $self = {};
    bless($self, ref($proto) || $proto);
    $self->{fdf_iterations}    = 10000;
    $self->{fdf_gradient_spec} = 0.001;
    $self->{f_iterations}      = 1000000;
    $self->{f_size}            = 0.00001;
    foreach my $name (                  # optional arguments
            'iter_hook',                # called once per f or fdf iteration
            'fdf_iterations',           # number fdf_iterations to perform
            'fdf_gradient_spec',        # fdf gradient to test against
            'f_iterations',             # number f_iterations to perform
            'f_size',                   # f size to test against
            'calc_ratings_failover',    # force failover to calc_ratings_f
            'calc_sigma_failover',      # force failover to calc_sigma2
            'strict_compliance',        # adnere exactly to original bayrate C++ code
            'verbose',                  # print lots of info about vectos and matrix assignments
        ) {
        $self->{$name} = delete $args{$name} if (exists $args{$name});
    }
    $self->tournamentDate(delete $args{tournamentDate} || '0000-01-01');
    if (keys %args) {
        croak sprintf "Unknown argument: %s", join(', ', keys %args);
    }
    $self->{players_array} = [];
    $self->{players_by_id} = {};
    $self->{games} = [];

    # fiddle with the symbol table to alias various calls to
    # the debugging version for help in debugging
    if ($self->{verbose}) {
        # alias to the chatty versions
        *MY_gsl_vector_set     = \&DEBUG_gsl_vector_set;
        *MY_gsl_vector_get     = \&DEBUG_gsl_vector_get;
        *MY_gsl_matrix_set     = \&DEBUG_gsl_matrix_set;
        *MY_gsl_matrix_get     = \&DEBUG_gsl_matrix_get;
        *my_f                  = \&DEBUG_f;
        *my_df                 = \&DEBUG_df;
        *my_fdf                = \&DEBUG_fdf;
    }
    else {  # quiet versions:
        *MY_gsl_vector_set     = \&gsl_vector_set;
        *MY_gsl_vector_get     = \&gsl_vector_get;
        *MY_gsl_matrix_set     = \&gsl_matrix_set;
        *MY_gsl_matrix_get     = \&gsl_matrix_get;
        *my_f                  = \&gsl_f;
        *my_df                 = \&gsl_df;
        *my_fdf                = \&gsl_fdf;
    }
    return($self);
}

sub add_game {
    my ($self, %args) = @_;

    foreach my $name (qw(black white handicap komi)) {
        if (not exists $args{$name}) {
            croak("$name not defined - usage: add_game(white=>\$white, black=>\$black, handicap=>\$handicap, komi=>\$komi)\n");
        }
    }
    foreach my $color (qw(black white)) {
        my $id = $args{$color}->get_id;
        if (not $self->player_with_id($id)) {
            croak "The $color player (id=$id) isn't in my player list\n";
        }
    }
    my $game;
    eval {
        # this can croak for various handicap/komi out or range reasons
        $game = Games::Go::AGA::BayRate::Game->new(
            white     => $args{white},
            black     => $args{black},
            handicap  => $args{handicap},
            komi      => $args{komi},
            whiteWins => $args{whiteWins},   # True if White wins
        );
        push @{$self->{games}}, $game;
    };
    if ($@) {
        warn $@;
    }
    return $game;
}

sub add_player {
    my ($self, %args) = @_;

    foreach my $name (qw(id seed)) {
        if (not exists $args{$name}) {
            croak("$name not defined - usage: add_player(id=>\$id, seed=>\$seed [, sigma=>\$sigma])\n");
        }
    }
    my $player;
    my $id    = $args{id};
    my $seed  = $args{seed};
    if (my $p = $self->player_with_id($id)) {
        if ($seed  == $p->get_seed) {
            return $p;      # already in list
        }
        croak "A player with id $id is already in my list\n";
    }
    # Safe to make a new player
    $player = Games::Go::AGA::BayRate::Player->new(
        id     => $id,
        seed   => $seed,
        rating => $seed,    # start with rating = seed
        index  => scalar @{$self->{players_array}},    # index in GSL vector
    );
    if ($args{sigma}) {
        $player->set_sigma($args{sigma});
    }
    push @{$self->{players_array}}, $player;
    $self->{players_by_id}{$player->get_id} = $player;
    return $player;
}

sub player_with_id {
    my ($self, $id) = @_;

    return $self->{players_by_id}{$id};
}

sub players {
    my ($self) = @_;
    return $self->{players_array};
}

sub games {
    my ($self) = @_;
    return $self->{games};
}

sub tournamentDate {
    my ($self, $new) = @_;

    if ($new) {
        $self->{tournamentDate} = $self->date_to_DateTime($new);
    }
    return $self->{tournamentDate};
}

sub tournamentDate_ymd {
    my ($self, $date) = @_;

    $date = $self->tournamentDate if (not $date);
    $date = $self->date_to_DateTime($date);
    my $day = $date->day;
    $day = "0$day" if (length $day == 1);
    return join '-', $date->year, $date->month_abbr, $day;
}

my %months = (
    jan =>  1,
    feb =>  2,
    mar =>  3,
    apr =>  4,
    may =>  5,
    jun =>  6,
    jul =>  7,
    aug =>  8,
    sep =>  9,
    oct => 10,
    nov => 11,
    dec => 12,
);

sub date_to_DateTime {
    my ($self, $date) = @_;

    if (ref $date eq 'DateTime') {
        return $date;       # already a DateTime
    }
    my $dt;
    my ($year, $month, $day) = split ('-', $date);
    if ($year and $month and $day) {
        $month = lc $month;
        $month = $months{$month} if ($months{$month});
#### print "date: $year $month $day\n";
        $dt = DateTime->new(
            year   => $year,
            month  => $month,
            day    => $day,
        );
    }
    croak "Invalid date: $date" if (not $dt);
    return $dt;
}

# delta of $date to my tournamentDate
sub delta_days {
    my ($self, $date) = @_;

    $date = $self->date_to_DateTime($date);
    return $date->delta_days($self->{tournamentDate})->delta_days;
}

#****************************************************************
#
# calc_sigma2 ()
#
# Calculate the new sigmas for players.  This function uses numerical
# integration technique to calculate the variances directly.
#
#****************************************************************
sub calc_sigma2 {
    my ($self) = @_;

    my %newSigma;

    foreach my $player (@{$self->{players_array}}) {
        my $sumX2W = 0;
        my $sumW   = 0;
        my $refaddr_player = refaddr $player;
        my (@games_as_white, @games_as_black);

        if (not $self->{strict_compliance}) {
            # Note: change from C++ Bayrate code:
            # create @games_as_white and @games_as_black instead of
            #       scanning all games.  This is faster, but introduces
            #       slight variance in results - see below
            foreach my $game (@{$self->{games}}) {
                if (refaddr $game->get_white == $refaddr_player) {
                    push @games_as_white, $game;
                }
                elsif (refaddr $game->get_black == $refaddr_player) {
                    push @games_as_black, $game;
                }
            }
        }

        for (my $ii = 0; $ii < 100; $ii++) {
            my $x = -5.0 * $player->get_sigma - $player->get_sigma / 20.0 + $ii * $player->get_sigma / 10.0;
            my $r = $player->get_crating + $x;
            my $z = ($r - $player->get_cseed) / $player->get_sigma;
            my $w = exp(-$z * $z / 2) / $SQRT_OF_2_TIMES_PI;
###### printf("w = % .24g\n", $w);

            if ($self->{strict_compliance}) {
                # Note: This is the original C++ Bayrate code:
                # Inefficient, but fast enough for typical AGA cases.  A
                # more advanced game indexing data structure would be
                # appropriate for larger tournaments
                foreach my $game (@{$self->{games}}) {
                    my $white = $game->get_white;
                    my $black = $game->get_black;
                    my $rd;
                    if (refaddr $white == $refaddr_player) {
                        $rd = $r - $black->get_crating - $game->get_handicapeqv;
                    }
                    elsif (refaddr $black == $refaddr_player) {
                        $rd = $white->get_crating - $r - $game->get_handicapeqv;
                    }
                    else {
                        next;       # this should not be possible
                    }
                    if ($game->get_whiteWins) {
                        $rd = -$rd;
                    }
                    $w *= gsl_sf_erfc($rd / $game->get_sigma_px / $M_SQRT2);
                }
            }
            else {
                # This is significantly faster, but due to round-off
                # errors (because of different ordering of calculations)
                # the results differ starting at about the 15th decimal
                # place
                foreach my $game (@games_as_white) {
                    my $rd = $r - $game->get_black->get_crating - $game->get_handicapeqv;
                    if ($game->get_whiteWins) {
                        $rd = - $rd;
                    }
                    $w *= gsl_sf_erfc($rd / $game->get_sigma_px / $M_SQRT2);
                }
                foreach my $game (@games_as_black) {
                    my $rd = $game->get_white->get_crating - $r - $game->get_handicapeqv;
                    if ($game->get_whiteWins) {
                        $rd = - $rd;
                    }
                    $w *= gsl_sf_erfc($rd / $game->get_sigma_px / $M_SQRT2);
                }
            }
            $sumX2W += $x*$x*$w;
            $sumW   += $w;
        }
        # Stuff the new sigma into a holding array until all the other sigmas are calculated.
        $newSigma{$refaddr_player} = sqrt($sumX2W / $sumW);
    }

    # Copy over the new sigmas now that all the calculations are done
    map { $_->set_sigma( $newSigma{refaddr $_} );
        } @{$self->{players_array}};
}

#****************************************************************
#
# calc_sigma1 ()
#
# Calculate the new sigmas for players.  This function uses the Laplace
# approximation to calculate the sigmas.
#
# Note: the matrix inversion routine may fail.
# This can happen if the matrix is not positive definite.
# In that case calc_sigma2() should be used as a backup.
#
#****************************************************************
sub calc_sigma1 {
    my ($self) = @_;

    my $count = scalar @{$self->{players_array}};
    my $matrixA = Math::GSL::Matrix->new($count, $count);
    my $raw_matrixA = $matrixA->raw;

    # Contribution from each player is 1 / sigma^2
    foreach my $player (@{$self->{players_array}}) {
        MY_gsl_matrix_set($raw_matrixA,
            $player->get_index,
            $player->get_index,
            1.0 / $player->get_sigma / $player->get_sigma,
        );
    }

    foreach my $game (@{$self->{games}}) {
        my $white = $game->get_white;
        my $black = $game->get_black;
        my $white_idx = $white->get_index;
        my $black_idx = $black->get_index;
        my $sigma_px = $game->get_sigma_px;
        my $rd = $white->get_crating - $black->get_crating - $game->get_handicapeqv;
        my $temp1 = exp(-$rd * $rd / 2.0 / $sigma_px / $sigma_px);

        if ($game->get_whiteWins) {
            my $temp2 = gsl_sf_erfc(-$rd / $M_SQRT2 / $sigma_px);
            my $adj = $SQRT_OF_2_DIVBY_PI / $sigma_px / $sigma_px / $sigma_px * $rd * $temp1 / $temp2
                      + $M_2_PI / $sigma_px / $sigma_px * $temp1 * $temp1 / $temp2 / $temp2;

            MY_gsl_matrix_set($raw_matrixA, $white_idx, $black_idx, -$adj + MY_gsl_matrix_get($raw_matrixA, $white_idx, $black_idx));
            MY_gsl_matrix_set($raw_matrixA, $black_idx, $white_idx, -$adj + MY_gsl_matrix_get($raw_matrixA, $black_idx, $white_idx));
            MY_gsl_matrix_set($raw_matrixA, $white_idx, $white_idx,  $adj + MY_gsl_matrix_get($raw_matrixA, $white_idx, $white_idx));
            MY_gsl_matrix_set($raw_matrixA, $black_idx, $black_idx,  $adj + MY_gsl_matrix_get($raw_matrixA, $black_idx, $black_idx));
        }
        # else black wins
        else {
            my $temp2 = gsl_sf_erfc( $rd / $M_SQRT2 / $sigma_px);
            my $adj = $SQRT_OF_2_DIVBY_PI / $sigma_px / $sigma_px / $sigma_px * $rd * $temp1 / $temp2
                      - $M_2_PI / $sigma_px / $sigma_px * $temp1 * $temp1 / $temp2 / $temp2;

            MY_gsl_matrix_set($raw_matrixA, $white_idx, $black_idx,  $adj + MY_gsl_matrix_get($raw_matrixA, $white_idx, $black_idx));
            MY_gsl_matrix_set($raw_matrixA, $black_idx, $white_idx,  $adj + MY_gsl_matrix_get($raw_matrixA, $black_idx, $white_idx));
            MY_gsl_matrix_set($raw_matrixA, $white_idx, $white_idx, -$adj + MY_gsl_matrix_get($raw_matrixA, $white_idx, $white_idx));
            MY_gsl_matrix_set($raw_matrixA, $black_idx, $black_idx, -$adj + MY_gsl_matrix_get($raw_matrixA, $black_idx, $black_idx));
        }
    }

    my $p = Math::GSL::Permutation->new($count);

    gsl_linalg_LU_decomp($raw_matrixA, $p->raw);
    my $matrixB = Math::GSL::Matrix->new($count, $count);
    my $raw_matrixB = $matrixB->raw;
    gsl_linalg_LU_invert($raw_matrixA, $p->raw, $raw_matrixB);

    die "Test calc_sigma failover" if ($self->{calc_sigma_failover});
    foreach my $player (@{$self->{players_array}}) {
        my $idx = $player->get_index;
        $player->set_sigma(sqrt(MY_gsl_matrix_get($raw_matrixB, $idx, $idx)));
    }
}

#****************************************************************
#
# calc_sigma ()
#
# Calculate the new sigmas for players.
#
# deals with the possibility of the matrix inversion routine failing.
# This can happen if the matrix is not positive definite.
# In that case calc_sigma2() is used as a backup.
#
# NOTE: the original bayrate (C++) from the AGA uses calc_sigma2
#   exclusively.
# NOTE also: calc_sigma1 and calc_sigma2 differ rather significantly
#
#****************************************************************
sub calc_sigma {
    my ($self) = @_;

    if (0) {    # NOTE: calc_sigma1 not used in original bayrate from AGA
        eval {
            $self->calc_sigma1;
        };
        if ($@) {   # error?
            warn $@;
            $self->calc_sigma2;
        }
    }
    else {
        $self->calc_sigma2;
    }
}

#****************************************************************
#
# calc_pt ()
#
# Calculate the logarithm of the total likelihood of a particular
# set of ratings
#
#****************************************************************
sub calc_pt {
    my ($self, $raw_v) = @_;

    my $pt = 0.0;

    foreach my $player (@{$self->{players_array}}) {
        $player->set_crating(MY_gsl_vector_get($raw_v, $player->get_index));
        my $z = ($player->get_crating - $player->get_cseed) / $player->get_sigma;
        $pt += -$z * $z / 2 - $HALF_LOG_OF_TWO_TIMES_PI;
    }

    foreach my $game (@{$self->{games}}) {
        my $white = $game->get_white;
        my $black = $game->get_black;
    # don't need to check this, already causes croak in add_game
    #   if (not $self->player_with_id($white->get_id) or
    #       not $self->player_with_id($black->get_id)) {
    #       croak "Player is in a game, but not in the players list";
    #   }

        my $rd = $white->get_crating - $black->get_crating - $game->get_handicapeqv;

        if ($game->get_whiteWins) {
            $rd = -$rd;
        }
        my $p = gsl_sf_log_erfc($rd / $game->get_sigma_px / $M_SQRT2) - $M_LN2;
        $pt += $p;
    }

    return $pt;
}

#****************************************************************
#
# calc_pt_df ()
#
# Calculate the gradient of the logarithm of the total likelihood of a particular set of ratings
#
# The likelihood function has a player contribution, which is nominally Gaussian
# (linear when a logarithm is taken) and depends only on sigma and the deviation from a player's
# seed ratings. There is also a game contribution, which depends on the result and game conditions
# of a particular contest
#
#****************************************************************

sub calc_pt_df {
    my ($self, $raw_v, $raw_df) = @_;

    # Zero out the initial gradient vector
    gsl_vector_set_zero($raw_df);

    # Calculate the player contribution to the likelihood
    foreach my $player (@{$self->{players_array}}) {
        my $idx = $player->get_index;
        $player->set_crating(MY_gsl_vector_get($raw_v, $idx));
        my $z = ($player->get_crating - $player->get_cseed) / $player->get_sigma;

        MY_gsl_vector_set($raw_df, $idx, -$z / $player->get_sigma);
    }

    # Calculate the game contribution.
    foreach my $game (@{$self->{games}}) {
        my $white = $game->get_white;
        my $black = $game->get_black;
        my $w_idx = $white->get_index;
        my $b_idx = $black->get_index;
        # Check if somehow a game got inserted without a corresponding player entry
    # don't need to check this, already causes croak in add_game
    #   if (not $self->player_with_id($white->get_id) or
    #       not $self->player_with_id($black->get_id)) {
    #       croak "Player is in a game, but not in the players list";
    #   }

        my $rd = $white->get_crating - $black->get_crating - $game->get_handicapeqv;

        # Add in the appropriate contribution
        my $sigma_px = $game->get_sigma_px;
        my $dp = 1 / $sigma_px * $SQRT_OF_2_DIVBY_PI * exp(-$rd * $rd / (2.0 * $sigma_px * $sigma_px));
        if ($game->get_whiteWins) {
            $dp = $dp / gsl_sf_erfc(-$rd / ($M_SQRT2 * $sigma_px));
        }
        else {
            $dp = -$dp / gsl_sf_erfc($rd / ($M_SQRT2 * $sigma_px));
        }
        MY_gsl_vector_set($raw_df, $w_idx, MY_gsl_vector_get($raw_df, $w_idx) + $dp);
        MY_gsl_vector_set($raw_df, $b_idx, MY_gsl_vector_get($raw_df, $b_idx) - $dp);
    }

    return 0;
}

#****************************************************************
#
# calc_ratings_f ()
#
# Calculate ratings using a multidimensional simplex method.  This
# technique is slower than the conjuagate gradient method, but it
# is more reliable.
#
# This function should be slow, but foolproof.  If an error occurs here
# the program prints an error message and fails.
#
#****************************************************************
sub calc_ratings_f {
    my ($self) = @_;

    foreach my $game (@{$self->{games}}) {
        $game->calc_handicapeqv;
    }

    # $self->close_boundary;
    # Starting point
    my $count = scalar @{$self->{players_array}};
    my $x = Math::GSL::Vector->new($count);
    my $raw_x = $x->raw;

    my (@idx, @val);
    foreach my $player (@{$self->{players_array}}) {
        MY_gsl_vector_set($raw_x, $player->get_index, $player->get_cseed);
    }

    # Set initial step sizes to 2
    my $ss = Math::GSL::Vector->new($count);
    my $raw_ss = $ss->raw;
    gsl_vector_set_all($raw_ss, 2);

    # minimizer 'state'
    my $state = my_gsl_multimin_fminimizer_set(
        $gsl_multimin_fminimizer_nmsimplex,    # type
        # gsl_multimin_function_f structure members:
            \&my_f,    # f       function
            $count,    # n       number of free variables
            $self,     # params  function params passed to f
        # end of gsl_multimin_function_f structure members:
        $raw_x,    # vector containing the player seeds
        $raw_ss,   # step size
    );

    my $iter = 0;
    my $status = $GSL_CONTINUE;
    my $f_size = $self->{f_size};
    while (    $status == $GSL_CONTINUE
           and $iter   <= $self->{f_iterations}) {
        $iter++;
        $status = gsl_multimin_fminimizer_iterate($state);

        last if ($status != $GSL_SUCCESS);  # eh?  why not CONTINUE?

        $status = gsl_multimin_test_size(gsl_multimin_fminimizer_size($state), $f_size);
        if ($self->{iter_hook}) {
            &{$self->{iter_hook}}($self, $state, $iter, $status);     # call user iteration hook
        }

    #   my $f = $state->fval;
    #   if ($status == $GSL_SUCCESS) {
    #       printf "\nConverged to minimum. f() = $f\n";
    #   }
    #   else {
    #       print "Iteration $iter\tf() = $f \tsimplex f_size = $f_size\n",
    #   }
    }

    if ($status == $GSL_CONTINUE) {
        # carp(gsl_strerror($status));
    }
    elsif ($status != $GSL_SUCCESS) {
        # $self->open_boundary;
        croak(gsl_strerror($status));
    }

    # Update new ratings
    my $xx = gsl_multimin_fminimizer_x($state);
    foreach my $player (@{$self->{players_array}}) {
        $player->set_crating(MY_gsl_vector_get($xx, $player->get_index));
    }

    # Calculate new sigmas
    $self->calc_sigma;

    # $self->open_boundary;
    return $status;
}

#****************************************************************
#
# calc_ratings_fdf ()
#
# Calculate ratings using a conjugate gradient method.  Technique fails if the initial guess
# happens to be exactly correct, which makes 'easy' test cases a little more difficult.
#
#****************************************************************

sub calc_ratings_fdf {
    my ($self) = @_;

    foreach my $game (@{$self->{games}}) {
        $game->calc_handicapeqv;
    }

    # $self->close_boundary;
    # Storage vector for player ratings
    my $count = scalar @{$self->{players_array}};
    my $x = Math::GSL::Vector->new($count);
    my $raw_x = $x->raw;

    # Populate the storage vector
    # This function crashes if we happen to seed players at a point where the gradient is
    # identically zero.  This sounds improbable, but two new players entering the rating system
    # at the same rank and who break even in a match against each other will trigger this case.
    # Accordingly, we add a small random offset to each initial guess to take it away from the
    # potential minimum point.
    #
    # reid: change seed only if it actually collides with
    #           an already existing seed
    my %seeds;
    foreach my $player (@{$self->{players_array}}) {
        my $seed = $player->get_cseed;
        while (exists $seeds{$seed}) {
            $seed = $player->get_cseed + rand(0.001);
        }

        $seeds{$seed} = 1;
        # $x->set($player->get_index, $player->get_cseed + gsl_ran_flat(r, 0, 0.1));
        MY_gsl_vector_set($raw_x, $player->get_index, $seed);
    }

    # minimizer 'state'
    my $state = my_gsl_multimin_fdfminimizer_set(
        $gsl_multimin_fdfminimizer_vector_bfgs2,    # type
        # gsl_multimin_function_fdf structure members:
            \&my_f,    # f       function
            \&my_df,   # df      derivative of f
            \&my_fdf,  # fdf     f and df
            $count,    # n       number of free variables
            $self,     # params  function params passed to f, df, and fdf
        # end of gsl_multimin_function_fdf structure members:
        $raw_x,    # vector containing the player seeds
        2.0,       # step size
        0.1,       # accuracy required
    );

    # Main loop.  Continue iterating until the likelihood function hits an extreme, or
    # until an error occurs.
    my $iter = 0;
    my $status = $GSL_CONTINUE;
    my $gradient_spec = $self->{fdf_gradient_spec};
    while (    $status == $GSL_CONTINUE
           and $iter < $self->{fdf_iterations}) {
        $iter++;
        gsl_multimin_fdfminimizer_iterate($state);

        last if ($status != $GSL_CONTINUE);

        my $gradient = raw_gsl_multimin_fdfminimizer_gradient($state);
        $status = gsl_multimin_test_gradient($gradient, $gradient_spec);
        if ($self->{iter_hook}) {
            &{$self->{iter_hook}}($self, $state, $iter, $status);     # call user iteration hook
        }

   #    printf "%s %5d  f()=%g  Norm=%g %s\n",
   #        ($status == $GSL_SUCCESS)
   #            ?  "Converged:"
   #            :  "Iteration:",
   #        $iter,
   #        $state->minimum,
   #        $state->gradient->blas_dnrm2,
   #        ($status == $GSL_CONTINUE) ? '' : gsl_strerror($status);
    }

    die "Test calc_ratings_failover" if ($self->{calc_ratings_failover});
    if ($status == $GSL_CONTINUE) {
        # carp(gsl_strerror($status));
    }
    elsif ($status != $GSL_SUCCESS) {
        # Can hit an error by accident if the initial guess on player ratings happens to be exactly right.
        # In that case, the gradient vector vanishes and the suggested update doesn't pass the tolerance
        # threshold.
        # $self->open_boundary;
        croak(gsl_strerror($status));
    }

    # Update new ratings
    my $xx = gsl_multimin_fdfminimizer_x($state);
    foreach my $player (@{$self->{players_array}}) {
        $player->set_crating(MY_gsl_vector_get($xx, $player->get_index));
    }

    # Calculate new sigmas
    $self->calc_sigma;
    # $self->open_boundary;

    return $status;
}

#****************************************************************
#
# calc_ratings ()
#
# Calculate ratings using first the fdf method, and if that fails,
# use the slower (but more reliable) _f method.
#
#****************************************************************
sub calc_ratings {
    my ($self) = @_;

    eval {
        $self->calc_ratings_fdf;    # croaks on failure
    };
    if ($@) {   # error?
        warn $@;
        print "$@\nTry again with calc_ratings_f\n";
        $self->calc_ratings_f;      # croaks on failure (shouldn't fail)
    }
}

## sub close_boundary {
##     my ($self) = @_;
## 
##     foreach my $player (@{$self->{players_array}}) {
##         my $seed = $player->get_seed;
##         $seed += ($seed < 0) ? 1 : -1;
##         $player->set_seed($seed);
##     }
##     foreach my $player (@{$self->{players_array}}) {
##         my $rating = $player->get_rating;
##         $rating += ($rating > 0) ? 1 : -1;
##         $player->set_rating($rating);
##     }
## }
## 
## # not sure why we close on seed but open on rating?
## sub open_boundary {
##     my ($self) = @_;
## 
##     foreach my $player (@{$self->{players_array}}) {
##         my $seed = $player->get_seed;
##         $seed += ($seed < 0) ? 1 : -1;
##         $player->set_seed($seed);
##     }
##     foreach my $player (@{$self->{players_array}}) {
##         my $rating = $player->get_rating;
##         $rating += ($rating > 0) ? 1 : -1;
##         $player->set_rating($rating);
##     }
## }
## 

#****************************************************************
#
# initSeeding ()
#
# Given players playing in a tournament, games in the tournament and the TDList data
# prior to a tournament, set each player's seed rating and sigma and calculate
# the handicap equivalent and sigma_px for each game.
#
#*****************************************************************
sub initSeeding {
    my ($self, $tdList) = @_;

    my %winCount;
    foreach my $player (@{$self->{players_array}}) {
        $winCount{refaddr $player} = 0;
    }
    foreach my $game (@{$self->{games}}) {
        my $winner = $game->get_whiteWins ? $game->get_white : $game->get_black;
        $winCount{refaddr $winner}++;
    }

    # Loop through each player who played a game in the tournament
    foreach my $player (@{$self->{players_array}}) {

        # Do we have a previous record for them in the TDList?
        my $tdList_player = $tdList ? $tdList->{$player->get_id} : undef;
        if (not $tdList_player or
            # No we don't.
            # Player is seeded at the rating they entered the tournament at
            # Sigma is set according to their seed rating
            $tdList_player->{rating} == 0 or
            # Perhaps we have a legacy entry in the TDList with no actual rating.
            # If so, treat as a reseeding
             $tdList_player->{sigma} == 0) {
            # Perhaps we have a legacy entry in the TDList with no sigma
            # If so, treat as a reseeding
            $player->set_sigma($player->calc_init_sigma);
        }
        # We have a record for them in the TDList?  If so then compute a new sigma
        # a possibly a new seed
        else {
            my $deltaR = $player->get_seed - $tdList_player->{rating};
            if ($player->get_seed * $tdList_player->{rating} < 0) {
                # seed => rating crosses dan/kyu boundary
                $deltaR -= 2;
            }

            # We don't let players demote themselves
            if ($deltaR < 0) {
                $player->set_seed($tdList_player->{rating});
                my $dayCount = $self->delta_days($tdList_player->{lastRatingDate});
                $player->set_sigma(sqrt($tdList_player->{sigma}
                                        * $tdList_player->{sigma}
                                        + 0.0005
                                        * 0.0005
                                        * $dayCount
                                        * $dayCount));
            }
            # Is this a self promotion by more than three stones?
            # If so, treat as a reseeding.  Players must win at least one game
            # to trigger the self-promotion case.  Otherwise they are just seeded
            # at their old rating.
            elsif ( ($deltaR >= 3.0) and ($winCount{refaddr $player} > 0) ) {

            if ($self->{strict_compliance}) {
                printf("OOPS: suspected bug here at line 947 in Collection.pm\n");
              # $player->set_seed($player->get_seed);
            }
            else {
                $player->set_seed($tdList_player->{rating});
            }
                $player->set_sigma($player->calc_init_sigma);
            }
            # Is it a smaller self promotion?
            elsif ( ($deltaR >= 1.0) and ($winCount{refaddr $player} > 0) ) {
                $player->set_seed($tdList_player->{rating} + 0.024746 + 0.32127 * $deltaR);
                $player->set_sigma(sqrt(  $tdList_player->{sigma}
                                        * $tdList_player->{sigma}
                                        + 0.256
                                        * ($deltaR ** 1.9475)
                                        )
                              );
            }
            else {
                $player->set_seed($tdList_player->{rating});
                my $dayCount = $self->delta_days($tdList_player->{lastRatingDate});
                $player->set_sigma(sqrt($tdList_player->{sigma}
                                        * $tdList_player->{sigma}
                                        + 0.0005
                                        * 0.0005
                                        * $dayCount
                                        * $dayCount));
            }
        }
#        printf("Seed: %d\t%g,\t%g",
#            $player->get_id,
#            $player->get_seed,
#            $player->get_sigma);
#        if ($tdList_player) {
#            printf("\tTD List: %g,\t%g",
#                $tdList_player->{rating},
#                $tdList_player->{sigma});
#        }
#        printf("\n");
    }

    # Assign individual handicap equivalents and sigma_px parameters to each game.
    foreach my $game (@{$self->{games}}) {
        $game->calc_handicapeqv;
    }
}

#****************************************************************
#
# findImprobables ()
#
# Identify games that are highly improbable (<10% chance of being correct)
#    reid:  Probablity calculation moved to a Game method.
#           Comment says <10% but code looks like <1%.  In any case, I
#               changed to pass the probablility threshold as parameter,
#               and also to return array of improbable games.
# Improbables usually indicates a data entry error or a player who has
# improved dramatically since their last rating who needs to be reseeded.
#
#****************************************************************
sub findImprobables {
    my ($self, $prob) = @_;

    $prob ||= 0.01;     # one percent
    my @improbable_games;
    foreach my $game (@{$self->{games}}) {
        my $p = $game->seed_probability;
        if ($p < $prob) {
            my $white = $game->get_white;
            my $black = $game->get_black;
            printf "    White: %s Rating = %g\n", $white->get_id, $white->get_seed;
            printf "    Black: %s Rating = %g\n", $black->get_id, $black->get_seed;
            printf "    H/K: %d/%d\n", $game->get_handicap, $game->get_komi;
            printf "    Result' %s wins\n", $game->get_whiteWins ? 'White' : 'Black';
            printf "    Prob: %g\n", $p;
            push @improbable_games, $game;
        }
    }
    return wantarray ? @improbable_games : \@improbable_games;
}

1;

__END__

=head1 SYNOPSIS

  use Games::Go::AGA::BayRate::Collection;
  my $collection = Games::Go::AGA::BayRate::Collection->new(
          iter_hook      => \&iter_hook,
          tournamentDate => $tournamentDate,
          strict_compliance => $strict_compliance, # match original bayrate C++ code exactly
          #f_iterations   => 50,    # iteration limit for f method
          #fdf_iterations => 50,    # iteration limit for fdf method
          #verbose => 1,            # lots of debugging info (to STDOUT)
  );

    foreach my $player (@players) {
        $collection->add_player(
            id     => $_player->id,
            seed   => $_player->seed,
          # sigma  => 0.0,  # may not need this
        );
    }

    # enter all the games
    foreach my $game (@games) {
        $collection->add_game(
            white     => $game->white->id,
            black     => $game->black->id,
            whiteWins => $game->whiteWins,
            handicap  => $game->handicap,
            komi      => $game->komi,
        );
    }

    $collection->initSeeding($tdList);

    $collection->calc_ratings;
    # Copy the new ratings into the internal TDList for the next tournament update
    foreach my $c_player (@{$collection->players}) {
        ... # do something with new $c_player->get_rating
    }

=head1 DESCRIPTION

Games::Go::AGA::BayRate::Collection is a perl implementation of
collection.cpp found in the C<bayrate.zip> package from the American Go
Association (http://usgo.org).

Much of the following documentation is shamelessly stolen directly from
C<collection.cpp>.

=head1 METHODS

=over

= $collection->add_player( %args )

Add tournament players.  C<%args> B<must> include: C<

        id   => unique_strings,
        seed => value,

C<%args> B<may> include:

        sigma => value,

C<id>s are unique for all players in the tournament.

C<seed> is the AGA rating converted (if necessary) to a floating point
number with a 'gap' between -1.0 (1 kyu) and +1.0 (1 dan).
Specifically, a medium-strength 1 dan converts to 1.5.  A player who is
just barely above 1 kyu is 1.01.  A player who is just below 1 dan is
-1.01, and a medium strength 1 kyu player is -1.5.

C<sigma> is the standard deviation of the seed and represents the
uncertainty in the seed.  Higher sigma means less certain.  If sigma is
not given, an initial sigma is assigned based on some rather esoteric
criterion (see AGARatings-Math.pdf at http://usgo.org and C<initSeeding)
below).

=item $collection->add_game( %args )

Add a game to the collection.  C<%args> B<must> include:

    white     => white_id,
    black     => black_id,
    whiteWins =>  0 | 1,
    handicap  => $handicap,
    komi      => $komi,

where C<white_id> and C<black_id> correspond the the C<id> given for a
previous C<add_player>.  Games should only be added if they have a
winner, who is indicated by the C<whiteWins> argument.  C<handicap> and
C<komi> are numbers (should be 0 if appropriate).

=item initSeeding ()

Given players playing in a tournament, games in the tournament and the
TDList data prior to a tournament, set each player's seed rating and
sigma and calculate the handicap equivalent and sigma_px for each game.

Call C<initSeeding> after all players and games have been added, and
prior to calling C<calc_ratings>.

=item calc_ratings ()

Calculates new C<ratings> for all players based on C<seed>s and game
results.

=item findImprobables ()

Identify games that are highly improbable (<1% chance of being correct)
Improbables usually indicates a data entry error or a player who has
improved dramatically since their last rating who needs to be reseeded.


=item calc_sigma ()

This method calls C<calc_sigma1> and if that fails, it failsover to call
C<calc_sigma2>.  In C<bayrate>, it simply calls C<calc_sigma2>.

=item calc_sigma2 ()

Calculate the new sigmas for players.  This function uses numerical
integration technique to calculate the variances directly.

=item calc_sigma1 ()

Calculate the new sigmas for players.  This function uses the Laplace
approximation to calculate the sigmas.  This call can die if the matrix
is not positive definite.  In that case calc_sigma2() should be used as
a backup.

=item calc_pt ()

Calculate the logarithm of the total likelihood of a particular set of
ratings

=item calc_pt_df ()

Calculate the gradient of the logarithm of the total likelihood of a
particular set of ratings

The likelihood function has a player contribution, which is nominally
Gaussian (linear when a logarithm is taken) and depends only on sigma
and the deviation from a player's seed ratings. There is also a game
contribution, which depends on the result and game conditions of a
particular contest

=item calc_ratings_f ()

Calculate ratings using a multidimensional simplex method.  This
technique is slower than the conjuagate gradient method, but it is more
reliable.

This function should be slow, but foolproof.  If an error occurs here
the program prints an error message and fails.

=item calc_ratings_fdf ()

Calculate ratings using a conjugate gradient method.  Technique fails if
the initial guess happens to be exactly correct, which makes 'easy' test
cases a little more difficult.

=back
