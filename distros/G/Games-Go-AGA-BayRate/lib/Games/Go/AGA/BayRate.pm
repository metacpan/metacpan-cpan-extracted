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
#     ABSTRACT:  implementation of AGA BayRate (player ratings) as perl object
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#        EMAIL:  reid@LucidPort.com
#      CREATED:  12/02/2010 08:51:22 AM PST
#===============================================================================

use 5.008;
use strict;
use warnings;

package Games::Go::AGA::BayRate;

use parent qw( Games::Go::AGA::BayRate::Collection );

use Alien::GSL;
use Math::GSL::Errno qw(
    $GSL_SUCCESS
);

our $VERSION = '0.119'; # VERSION

sub new {
    my ($proto, %args) = @_;

    my $self = {};
    bless($self, ref($proto) || $proto);

    my $collection
    = $self->{collection}
    = Games::Go::AGA::BayRate::Collection->new(
            iter_hook             => \&iter_hook, # called once per f or fdf iteration
        #   fdf_iterations        =>  # number fdf_iterations to perform
        #   fdf_gradient_spec     =>  # fdf gradient to test against
        #   f_iterations          =>  # number f_iterations to perform
        #   f_size                =>  # f size to test against
        #   calc_ratings_failover =>  # force failover to calc_ratings_f
        #   calc_sigma_failover   =>  # force failover to calc_sigma2
        #   strict_compliance     =>  # adnere exactly to original bayrate C++ code
    );

    # enter all the players who were in a game
    my $players = $args{players} || [];
    foreach my $player ( @{$players} ) {
        $self->add_player($player);
    }

    # enter all the games
    my $games = $args{games} || [];
    foreach my $game (@{$games}) {
        $self->add_game($game);
    }
    return $self;
}

# hook called for each F(DF)Minimzer iteration
sub iter_hook {
    my ($collection, $state, $iter, $status) = @_;

    if (ref $state eq 'Math::GSL::Multimin::gsl_multimin_fminimizer') {
        my $f = # gsl_multimin_fminimizer_fval($state),    # hmm, struct member, not a function
                # ok, do it this way instead:
            Games::Go::AGA::BayRate::GSL::Multimin::my_fminimizer_fval($state),
        my $size = gsl_multimin_fminimizer_size($state);
        printf("F Iteration %d\tf() = %g\tsimplex size = %g\n", $iter, $f, $size);
        if ($status == $GSL_SUCCESS) {
            printf "\nConverged to minimum. f() = %g\n", $f;
        }
    }
    elsif (ref $state eq 'Math::GSL::Multimin::gsl_multimin_fdfminimizer') {
        my $gradient = Games::Go::AGA::BayRate::GSL::Multimin::my_fdfminimizer_gradient($state);
        my $minimum = gsl_multimin_fdfminimizer_minimum($state);
        printf("FDF Iteration %d\tf() = %g\tnorm = %g\tStatus = %d\n",
            $iter,
            $minimum,
            gsl_blas_dnrm2($gradient),
            $status);
        if ($status == $GSL_SUCCESS) {
            printf "\nConverged to minimum. Norm(gradient) = %g\n",
                gsl_blas_dnrm2($gradient),
        }

    }
    else {
        die(sprintf("Unknown minimizer state type: %s", ref $state));
    }
}

sub add_player {
    my ($self, $player) = @_;

    $self->{collection}->add_player(
        id     => $player->id,
        seed   => $player->rating,
        #  sigma  => 6.0,  # will get changed later
    );
}

sub add_game {
    my ($self, $game) = @_;

    return if (not $game->winner);  # skip games without results
    $self->{collection}->add_game(
        white     => $game->white.
        black     => $game->black.
        whiteWins => $game->winner->id eq $game->white->id,
        handicap  => $game->handicap,
        komi      => $game->komi,
    );
}

1;

__END__

=head1 SYNOPSIS

    use Games::Go::AGA::BayRate;

    my $bayrate = Games::Go::AGA::BayRate->new(
        players => $tournament->players,    # ref to array of players
        games   => $tournament->games,      # ref to array of games
    };

    # assuming we don't have carryover sigma info:
    $bayrate->initSeeding($tdList);

    # caclulate new ratings
    $bayrate->calc_ratings;

    for (my $bay_player (@${bayrate->players}) {
        # transfer adjusted ratings back to tournament players
        my $tourn_player = $tournament->find_player($bay_player->id);
        $tourn_player->set_adj_rating($bay_player->rating);
    }

=head1 DESCRIPTION

The American Go Association (AGA) provides a rating system for the go
players of the nation.  The algorithm is described in detail in a paper
on their web-site (http://usgo.org):  AGARatings-Math.pdf.  They also
provide a C++ implementation example: C<bayrate.zip>.

This package implements a perl version of C<bayrate>, both the
executable and the support objects (Game, Player, etc).  Note: only
C<bin/bayrate> is included here, C<singlerate> and C<check> are left as
an excersise for the student.

C<bayrate>, and this module, require a fairly recent version of the GNU
Scientific Library (GSL), including the devel portion (containing header
files, etc).  If you are using Fedora (linux), "yum install gsl
gsl-devel" should be sufficient.  Version 1.14 and later should work,
earlier versions may not.  To find your current version, run:

    pkg-config --modversion gsl

Work is being done to provide a full perl interface to GSL, but it is
not complete as of this writing.  I have used Inline::C to hook to the
specific GSL functions used by bayrate.pl.  The missing parts needed by
bayrate.pl are the Multimin functions (f_minimizer and fdf_minimizer).
Tests for the Inline::C interface to these functions (as well as the C
versions as called out in the Gnu GSL documentation) are included in the
'extra' subdirectory of this package.

This module interfaces between a C<Games::Go::AGA::DataObjects> objects
and a C<Games::Go::AGA::BayRate::Collection> object.  A new BayRate
object subclasses the Collection object and copies information from a
list of C<Games::Go::AGA::DataObjects::Players> and a list of
C<Games::Go::AGA::DataObjects::Games> (such as the lists provided by the
C<players> and C<games> methods of a
C<Games::Go::AGA::DataObjects::Tournament> object) to the Collection.
After calling the C<$bayrate-E<gt>calc_ratings> method to run
the C<Collection> rating algorithm,  The adjusted ratings are available
to copy back into the C<adj_rating>s of the Tournament players.

=head1 IMPLEMENTATION

Given a collection of players, each with a rating and a sigma, and given
a collection of games the players may or may not have participated in
(including the outcomes of those games), this module uses Bayesian
statistical mathods to determine an adjusted rating for each player so
that the observed outcomes are considered to be 'most likely'.

In practice, what this means is that if player A defeats player B, but
because of the difference in rating, this is the expected outcome, then
the adjustments to the ratings of player A and player B will be rather
small.  On the other hand, if player B is expected to defeat player A,
then the rating of player A should be raised rather significantly, and
player B should be correspondingly lowered.

To use this in a tournament, enter the players and all the games after
each round (NOTE: use the players' B<initial> ratings, not their
adjusted ratings, and add B<all> the games from B<all> rounds).  For
example, after round 3 is complete, enter all the games from rounds 1,
2, and 3.  Then use the adjusted ratings to help find pairings for the
next round (See Games::Go::Wgtd using the Best pairing method).

The effects of wins and losses propagate so that the adjustment to
player A (who played against player B in the first round) can be
affected by the outcome of player B's game against player C (in a
subsequent round).

=head1 SEE ALSO

=over

=item Games::Go::AGA::BayRate::Collection

=item Games::Go::AGA::BayRate::Game

=item Games::Go::AGA::BayRate::Player

=item Games::Go::Wgtd

=back

