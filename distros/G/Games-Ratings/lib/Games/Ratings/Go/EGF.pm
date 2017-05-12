package Games::Ratings::Go::EGF;

## TODO: check arguments for subroutines (use Data::Checker)?
## TODO: Error handling
##       * croak()
##       * perldoc anpassen
## TODO: $self->set_rating() checken: >= 100

use strict;
use warnings;
use Carp;

use 5.6.1;               # 'our' was introduced in perl 5.6
use version; our $VERSION = qv('0.0.5');

## look in Games::Ratings for methods not provide by this package
use base qw ( Games::Ratings );

## epsilon (inflation factor)
our $e = 0.014;

## calculate rating change
sub get_rating_change {
    my ($self) = @_;

    ## get own rating
    my $own_rating      = $self->get_rating();

    my $rating_change_total;
    ## calculate rating change for each game separately
    foreach my $game_ref ( $self->get_all_games() ) {
        ## add rating change for single game to total rating change
        $rating_change_total += _calc_rating_change_for_single_game(
                                    $own_rating,
                                    $game_ref->{opponent_rating},
                                    $game_ref->{result},
                                    $game_ref->{handicap},
                                );
    }

    ## return total rating change
    return $rating_change_total;
}

## calculate new rating
sub get_new_rating {
    my ($self) = @_;

    ## $R_o -- old rating
    my $R_o = $self->get_rating();

    ## $R_n -- new rating (rounded)
    my $R_n = sprintf( "%.f", $R_o + $self->get_rating_change() );

    ## return new rating
    return $R_n;
}

## calculate expected points
sub get_points_expected {
    my ($self) = @_;

    ## $W_e -- expected points
    my $W_e;

    ## get value for $A_rating
    my $A_rating = $self->get_rating();

    ## sum up expected points for all games
    foreach my $game_ref ( $self->get_all_games() ) {
        ## get values for $B_rating, $A_handicap
        my $B_rating = $game_ref->{opponent_rating};
        my $A_handicap = $game_ref->{handicap};

        ## check whether handicap is provided -- otherwise set to zero
        if (! defined $A_handicap) {
            $A_handicap = 0;
        }

        ## sum up individual scoring probabilities
        $W_e += _get_scoring_probability_for_single_game(
                    $A_rating,
                    $B_rating,
                    $A_handicap,
                );

    }

    ## return expected points
    return $W_e;
}

########################
## internal functions ##
########################

## calculate rating change for single game
sub _calc_rating_change_for_single_game {
    my ($A_rating, $B_rating, $result, $A_handicap) = @_;

    ## check whether handicap is provided -- otherwise set to zero
    if (! defined $A_handicap) {
        $A_handicap = 0;
    }
  
    ## get numerical result ( win=>1 draw=>0.5 loss=>0 )
    my $numerical_result = Games::Ratings::_get_numerical_result($result);

    ## calculate parameter 'con' according to $A_rating
    my $A_con = _get_con($A_rating);

    ## get scoring probability for player A
    my $A_exp = _get_scoring_probability_for_single_game(
                    $A_rating,
                    $B_rating,
                    $A_handicap,
                );

    ## compute rating changes for player A
    my $A_rating_change = $A_con * ($numerical_result-$A_exp);
  
    ## return rating changes for player A
    return ($A_rating_change);
}

## calculate scoring probability for a single game
sub _get_scoring_probability_for_single_game {
    my ($A_rating,$B_rating,$A_handicap) = @_;

    ## scoring probability for player A
    my $A_exp;

    ## scoring probability for weaker player is computed first
    if ($A_rating > $B_rating) {
        ## determine rating difference for calculation of scoring probability
        my $rating_difference = _get_rating_difference(
                                    $B_rating,
                                    $A_rating,
                                    -$A_handicap,
                                );
        ## calculate parameter a
        my $a = _get_a($B_rating, -$A_handicap);

        ## get scoring probability for player A (1 - e - Se(B))
        $A_exp = 1 - $e - 1 / ( 1 + exp($rating_difference/$a) );
    }
    else {
        ## determine rating difference for calculation of scoring probability
        my $rating_difference = _get_rating_difference(
                                    $A_rating,
                                    $B_rating,
                                    $A_handicap,
                                );
        ## calculate parameter a
        my $a = _get_a($A_rating, $A_handicap);

        ## get scoring probability for player A
        $A_exp = 1 / ( 1 + exp($rating_difference/$a) );
    }

    ## return scoring probability for weaker player
    return ($A_exp);
}

## calculate rating difference which is used to calc the scoring probability
sub _get_rating_difference {
    my ($A, $B, $A_handicap) = @_;

    ## compute real rating difference
    my $rating_difference = ( $B-$A );

    ## rating difference is adjusted when handicaps are given
    if ($A_handicap > 0) {
        $rating_difference = $rating_difference 
                             - 100 * ($A_handicap - 0.5);
    }
    if ($A_handicap < 0) {
        $rating_difference = $rating_difference
                             + 100 * (-$A_handicap - 0.5);
    }

    ## return rating difference used for rating calculations
    return $rating_difference;
}

## calculate paramater 'a'
sub _get_a {
    my ($player_rating,$player_handicap) = @_;

    ## $player_rating is adjusted for calculation of $a if handicap exists
    if ($player_handicap != 0) {
        $player_rating = $player_rating + 100*( $player_handicap-0.5 );
    }

    ## compute parameter 'a' -- some values are given, rest interpolated
    my $a;
    if ($player_rating > 2700) {
        $a = 70;
    }
    ## adjusted $player_rating could fall below 100 (with given handicap)
    elsif ($player_rating < 100) {
        $a = 200;
    }
    else {
        $a = 200 - ( 200-70 ) * ($player_rating-100)/(2700-100);
    }

    ## return parameter 'a'
    return $a;
}

## calculate paramater 'con'
sub _get_con {
    my ($player_rating) = @_;

    ## compute parameter 'con' -- some values are given, rest interpolated
    my $con;
    if ($player_rating == 100) {
        $con = 116;
    }
    elsif ($player_rating < 200) {
        $con = 116 - ( 116-110 )*( $player_rating-100 )/(200-100);
    }
    elsif ($player_rating == 200) {
        $con = 110;
    }
    elsif ($player_rating < 1300) {
        $con = 110 - ( 110-55 )*( $player_rating-200 )/(1300-200);
    }
    elsif ($player_rating == 1300) {
        $con = 55;
    }
    elsif ($player_rating < 2000) {
        $con = 55 - ( 55-27 )*( $player_rating-1300 )/(2000-1300);
    }
    elsif ($player_rating == 2000) {
        $con = 27;
    }
    elsif ($player_rating < 2400) {
        $con = 27 - ( 27-15 )*( $player_rating-2000 )/(2400-2000);
    }
    elsif ($player_rating == 2400) {
        $con = 15;
    }
    elsif ($player_rating < 2600) {
        $con = 15 - ( 15-11 )*( $player_rating-2400 )/(2600-2400);
    }
    elsif ($player_rating == 2600) {
        $con = 11;
    }
    elsif ($player_rating < 2700) {
        $con = 11 - ( 11-10 )*( $player_rating-2600 )/100;
    }
    elsif ($player_rating == 2700) {
        $con = 10;
    }
    elsif ($player_rating > 2700) {
        $con = 10;
    }

    ## return parameter 'con'
    return $con;
}

1; # Magic true value required at end of module
__END__


=head1 NAME
 
Games::Ratings::Go::EGF - calculate changes to EGF ratings (GoR)
 

=head1 VERSION
 
This document describes Games::Ratings::Go::EGF version 0.0.1
 

=head1 SYNOPSIS
 
 use Games::Ratings::Go::EGF;

 my $player = Games::Ratings::Go::EGF->new();
 $player->set_rating(2240);
 $player->add_game( {
                      opponent_rating => 2114,
                      result          => 'win',   ## or 'draw' or 'loss'
                      handicap        => '+5',    ## got 5 handicap
                                                  ## or '-2': gave 2 h.
                                                  ## can be ommitted
                    }
                  );

 my $rating_change = $player->get_rating_change();
 my $new_rating = $player->get_new_rating();


=head1 DESCRIPTION

This module provides methods to calculate EGF rating (GoR) changes for one
player, having played one or more rated games. Gains and losses are calculated
according to the EGF rating rules (cmp. EGF Official ratings:
http://gemma.ujf.cas.cz/~cieply/GO/gor.html).

Basically EGF uses a formula to calculate scoring probabilities in dependence
from rating differences between players: Se(A) = 1/(e^[D/a] + 1).

Furthermore EGF uses a coefficient ('con') depending on the current
rating which reduces rating change for stronger players and increases rating
change for weaker players: Rnew - Rold = con * (Sa - Se).
 

=head1 INTERFACE 

This modules provides the following methods specific to EGF ratings. Other
(more generic) methods for rating calculation are provided by Games::Ratings.
Please check the documentation of Games::Ratings for those methods.

=head2 get_rating_change

  my $rating_change = $player->get_rating_change();

Calculate rating changes for all stored games and return sum of those
changes.

=head2 get_new_rating

  my $new_rating = $player->get_new_rating();

Calculate new rating after the given games.

=head2 get_points_expected

  my $points_expected = $player->get_points_expected();

Calculate expected points according to rating differences between own rating
and opponents ratings.


=head1 CONFIGURATION AND ENVIRONMENT

Games::Ratings requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module relies on Games::Ratings which provides some generic methods, e.g.
  * new()
  * get_rating()
  * set_rating()
  * get_coefficient()
  * set_coefficient()
  * add_game()
  * remove_all_games()
  * DESTROY()


=head1 DIAGNOSTICS
 
At the moment, there are no error or warning messages that the module can
generate.

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

At the moment, it's not possible to compute a EGF rating for a previously
unrated player.

Please report any bugs or feature requests to
C<bug-games-ratings@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Christian Bartolomaeus  C<< <bartolin@gmx.de> >>


=head1 ACKNOWLEDGMENTS

Many thanks to Ales Cieply for answering my questions about the EGF rating
system.


=head1 SEE ALSO

http://en.wikipedia.org/wiki/Elo_rating for informations about the Elo system.

http://gemma.ujf.cas.cz/~cieply/GO/gor.html for informations about the
EGF rating system.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Christian Bartolomaeus C<< <bartolin@gmx.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
