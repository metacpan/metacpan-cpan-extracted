package Games::Ratings::Chess::FIDE;

## TODO: check arguments for subroutines (use Data::Checker)?
## TODO: Error handling
##       * croak()
##       * perldoc anpassen

use strict;
use warnings;
use Carp;

use 5.6.1;               # 'our' was introduced in perl 5.6
use version; our $VERSION = qv('0.0.5');

## look in Games::Ratings for methods not provide by this package
use base qw ( Games::Ratings );

## calculate rating change
sub get_rating_change {
    my ($self) = @_;

    ## get own rating and own coefficient
    my $own_rating      = $self->get_rating();
    my $own_coefficient = $self->get_coefficient();

    my $rating_change_total;
    ## calculate rating change for each game separately
    foreach my $game_ref ( $self->get_all_games() ) {
        ## add rating change for single game to total rating change
        $rating_change_total += _calc_rating_change_for_single_game(
                                    $own_rating,
                                    $own_coefficient,
                                    $game_ref->{opponent_rating},
                                    $game_ref->{result},
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

    ## $own_rating -- own rating
    my $own_rating = $self->get_rating();

    ## sum up expected points for all games
    foreach my $game_ref ( $self->get_all_games() ) {
        $W_e += _get_scoring_probability_for_single_game(
                    $own_rating,
                    $game_ref->{opponent_rating},
                );
    }

    ## return expected points
    return $W_e;
}

## calculate performance
sub get_performance {
    my ($self) = @_;

    ## $R_h -- performance (independent from old rating)
    my $R_h;

    ## average rating of opponents
    my $R_c = $self->get_average_rating_of_opponents();

    ## $P -- percentage score (two digits needed)
    my $P = sprintf( "%.2f", $self->get_percentage_score() );

    ## if player scored 100 % or 0 % it's not possible to calc. performance
    if ($P == 1) {
        $R_h = $R_c + 667;
        return $R_h;
    }
    if ($P == 0) {
        $R_h = $R_c - 667;
        return $R_h;
    }

    ## lookup $D rating difference according to $P from probability table 
    my $D = _get_rating_difference_matching_percentage_score($P);

    ## calculate performance
    $R_h = $R_c + $D;

    ## return performance
    return $R_h;
}

########################
## internal functions ##
########################

## scoring probabilities depending from rating difference (FIDE B0210.1b)
our %scoring_probability_lookup_table;
_set_scoring_probability_lookup_table();

## lookup table needed to determine performance (FIDE B0210.1a)
our %reverse_scoring_probability_lookup_table;
_set_reverse_scoring_probability_lookup_table();

## calculate rating change for single game
sub _calc_rating_change_for_single_game {
    my ($A_rating, $A_coefficient, $B_rating, $result) = @_;
  
    ## get numerical result ( win=>1 draw=>0.5 loss=>0 )
    my $numerical_result = Games::Ratings::_get_numerical_result($result);

    ## check whether development coefficient is provided -- guess otherwise
    if (! defined $A_coefficient) {
        $A_coefficient = _guess_coefficient($A_rating);
    }

    ## get scoring probability for player A
    my $A_exp = _get_scoring_probability_for_single_game($A_rating,$B_rating);

    ## compute rating changes for player A
    my $A_rating_change = $A_coefficient * ($numerical_result-$A_exp);
  
    ## return rating changes for player A
    return ($A_rating_change);
}

## try to guess development coefficient
sub _guess_coefficient {
    my ($player_rating) = @_;

    ## guess coefficient according to rating (cmp. FIDE handbook B0210.52)
    my $player_coefficient;
    if ($player_rating >= 2400) {
        $player_coefficient = 10;
    }
    else {
        $player_coefficient = 15;
    }

    ## return guessed coefficient
    return $player_coefficient;
}

## calculate scoring probability for a single game
sub _get_scoring_probability_for_single_game {
    my ($A_rating,$B_rating) = @_;

    my $rating_difference = _get_rating_difference($A_rating,$B_rating);

    ## get scoring probability of player A from lookup table 
    my $A_exp;
    if ($rating_difference >= 0) {
        $A_exp = $scoring_probability_lookup_table{$rating_difference};
    }
    else {
        $A_exp = 1 - $scoring_probability_lookup_table{0-$rating_difference};
    }

    ## return scoring probability for player A
    return ($A_exp);
}

## calculate rating difference which is used to calc the scoring probability
sub _get_rating_difference {
    my ($A, $B) = @_;

    ## compute real rating difference
    my $rating_difference = ( $A-$B );

    ## large rating differences are cut (FIDE handbook B0210.51, 2nd sentence)
    if ($rating_difference > '350') {
        $rating_difference = '350';
    }
    if ($rating_difference < '-350') {
        $rating_difference = '-350';
    }

    ## return rating difference used for rating calculations
    return $rating_difference;
}

## calculate rating differences matching percentage score
sub _get_rating_difference_matching_percentage_score {
    my ($P) = @_;

    ## lookup $D (rating difference) from lookup table
    my $D;
    if ($P lt 0.5) {
        ## percentage score negated -- so we can use our lookup table
        my $P_negated = sprintf("%.2f", 1-$P);
        $D = -($reverse_scoring_probability_lookup_table{$P_negated});
    }
    else {
        $D = $reverse_scoring_probability_lookup_table{$P};
    }

    ## return $D
    return $D;
}

## use hash as lookup table for scoring probability (cmp. FIDE B0210.1b)
sub _set_scoring_probability_lookup_table {
    foreach my $rating_difference (0..3) {
        $scoring_probability_lookup_table{$rating_difference} = 0.50;
    }
    foreach my $rating_difference (4..10) {
        $scoring_probability_lookup_table{$rating_difference} = 0.51;
    }
    foreach my $rating_difference (11..17) {
        $scoring_probability_lookup_table{$rating_difference} = 0.52;
    }
    foreach my $rating_difference (18..25) {
        $scoring_probability_lookup_table{$rating_difference} = 0.53;
    }
    foreach my $rating_difference (26..32) {
        $scoring_probability_lookup_table{$rating_difference} = 0.54;
    }
    foreach my $rating_difference (33..39) {
        $scoring_probability_lookup_table{$rating_difference} = 0.55;
    }
    foreach my $rating_difference (40..46) {
        $scoring_probability_lookup_table{$rating_difference} = 0.56;
    }
    foreach my $rating_difference (47..53) {
        $scoring_probability_lookup_table{$rating_difference} = 0.57;
    }
    foreach my $rating_difference (54..61) {
        $scoring_probability_lookup_table{$rating_difference} = 0.58;
    }
    foreach my $rating_difference (62..68) {
        $scoring_probability_lookup_table{$rating_difference} = 0.59;
    }
    foreach my $rating_difference (69..76) {
        $scoring_probability_lookup_table{$rating_difference} = 0.60;
    }
    foreach my $rating_difference (77..83) {
        $scoring_probability_lookup_table{$rating_difference} = 0.61;
    }
    foreach my $rating_difference (84..91) {
        $scoring_probability_lookup_table{$rating_difference} = 0.62;
    }
    foreach my $rating_difference (92..98) {
        $scoring_probability_lookup_table{$rating_difference} = 0.63;
    }
    foreach my $rating_difference (99..106) {
        $scoring_probability_lookup_table{$rating_difference} = 0.64;
    }
    foreach my $rating_difference (107..113) {
        $scoring_probability_lookup_table{$rating_difference} = 0.65;
    }
    foreach my $rating_difference (114..121) {
        $scoring_probability_lookup_table{$rating_difference} = 0.66;
    }
    foreach my $rating_difference (122..129) {
        $scoring_probability_lookup_table{$rating_difference} = 0.67;
    }
    foreach my $rating_difference (130..137) {
        $scoring_probability_lookup_table{$rating_difference} = 0.68;
    }
    foreach my $rating_difference (138..145) {
        $scoring_probability_lookup_table{$rating_difference} = 0.69;
    }
    foreach my $rating_difference (146..153) {
        $scoring_probability_lookup_table{$rating_difference} = 0.70;
    }
    foreach my $rating_difference (154..162) {
        $scoring_probability_lookup_table{$rating_difference} = 0.71;
    }
    foreach my $rating_difference (163..170) {
        $scoring_probability_lookup_table{$rating_difference} = 0.72;
    }
    foreach my $rating_difference (171..179) {
        $scoring_probability_lookup_table{$rating_difference} = 0.73;
    }
    foreach my $rating_difference (180..188) {
        $scoring_probability_lookup_table{$rating_difference} = 0.74;
    }
    foreach my $rating_difference (189..197) {
        $scoring_probability_lookup_table{$rating_difference} = 0.75;
    }
    foreach my $rating_difference (198..206) {
        $scoring_probability_lookup_table{$rating_difference} = 0.76;
    }
    foreach my $rating_difference (207..215) {
        $scoring_probability_lookup_table{$rating_difference} = 0.77;
    }
    foreach my $rating_difference (216..225) {
        $scoring_probability_lookup_table{$rating_difference} = 0.78;
    }
    foreach my $rating_difference (226..235) {
        $scoring_probability_lookup_table{$rating_difference} = 0.79;
    }
    foreach my $rating_difference (236..245) {
        $scoring_probability_lookup_table{$rating_difference} = 0.80;
    }
    foreach my $rating_difference (246..256) {
        $scoring_probability_lookup_table{$rating_difference} = 0.81;
    }
    foreach my $rating_difference (257..267) {
        $scoring_probability_lookup_table{$rating_difference} = 0.82;
    }
    foreach my $rating_difference (268..278) {
        $scoring_probability_lookup_table{$rating_difference} = 0.83;
    }
    foreach my $rating_difference (279..290) {
        $scoring_probability_lookup_table{$rating_difference} = 0.84;
    }
    foreach my $rating_difference (291..302) {
        $scoring_probability_lookup_table{$rating_difference} = 0.85;
    }
    foreach my $rating_difference (303..315) {
        $scoring_probability_lookup_table{$rating_difference} = 0.86;
    }
    foreach my $rating_difference (316..328) {
        $scoring_probability_lookup_table{$rating_difference} = 0.87;
    }
    foreach my $rating_difference (329..344) {
        $scoring_probability_lookup_table{$rating_difference} = 0.88;
    }
    foreach my $rating_difference (345..350) {
        $scoring_probability_lookup_table{$rating_difference} = 0.89;
    }
}

## use hash as lookup table (rating differences given a percentage score)
## (cmp. FIDE B0210.1a)
sub _set_reverse_scoring_probability_lookup_table {
    $reverse_scoring_probability_lookup_table{'0.50'} = '0';
    $reverse_scoring_probability_lookup_table{'0.51'} = '7';
    $reverse_scoring_probability_lookup_table{'0.52'} = '14';
    $reverse_scoring_probability_lookup_table{'0.53'} = '21';
    $reverse_scoring_probability_lookup_table{'0.54'} = '29';
    $reverse_scoring_probability_lookup_table{'0.55'} = '36';
    $reverse_scoring_probability_lookup_table{'0.56'} = '43';
    $reverse_scoring_probability_lookup_table{'0.57'} = '50';
    $reverse_scoring_probability_lookup_table{'0.58'} = '57';
    $reverse_scoring_probability_lookup_table{'0.59'} = '65';
    $reverse_scoring_probability_lookup_table{'0.60'} = '72';
    $reverse_scoring_probability_lookup_table{'0.61'} = '80';
    $reverse_scoring_probability_lookup_table{'0.62'} = '87';
    $reverse_scoring_probability_lookup_table{'0.63'} = '95';
    $reverse_scoring_probability_lookup_table{'0.64'} = '102';
    $reverse_scoring_probability_lookup_table{'0.65'} = '110';
    $reverse_scoring_probability_lookup_table{'0.66'} = '117';
    $reverse_scoring_probability_lookup_table{'0.67'} = '125';
    $reverse_scoring_probability_lookup_table{'0.68'} = '133';
    $reverse_scoring_probability_lookup_table{'0.69'} = '141';
    $reverse_scoring_probability_lookup_table{'0.70'} = '149';
    $reverse_scoring_probability_lookup_table{'0.71'} = '158';
    $reverse_scoring_probability_lookup_table{'0.72'} = '166';
    $reverse_scoring_probability_lookup_table{'0.73'} = '175';
    $reverse_scoring_probability_lookup_table{'0.74'} = '184';
    $reverse_scoring_probability_lookup_table{'0.75'} = '193';
    $reverse_scoring_probability_lookup_table{'0.76'} = '202';
    $reverse_scoring_probability_lookup_table{'0.77'} = '211';
    $reverse_scoring_probability_lookup_table{'0.78'} = '220';
    $reverse_scoring_probability_lookup_table{'0.79'} = '230';
    $reverse_scoring_probability_lookup_table{'0.80'} = '240';
    $reverse_scoring_probability_lookup_table{'0.81'} = '251';
    $reverse_scoring_probability_lookup_table{'0.82'} = '262';
    $reverse_scoring_probability_lookup_table{'0.83'} = '273';
    $reverse_scoring_probability_lookup_table{'0.84'} = '284';
    $reverse_scoring_probability_lookup_table{'0.85'} = '296';
    $reverse_scoring_probability_lookup_table{'0.86'} = '309';
    $reverse_scoring_probability_lookup_table{'0.87'} = '322';
    $reverse_scoring_probability_lookup_table{'0.88'} = '336';
    $reverse_scoring_probability_lookup_table{'0.89'} = '351';
    $reverse_scoring_probability_lookup_table{'0.90'} = '366';
    $reverse_scoring_probability_lookup_table{'0.91'} = '383';
    $reverse_scoring_probability_lookup_table{'0.92'} = '401';
    $reverse_scoring_probability_lookup_table{'0.93'} = '422';
    $reverse_scoring_probability_lookup_table{'0.94'} = '444';
    $reverse_scoring_probability_lookup_table{'0.95'} = '470';
    $reverse_scoring_probability_lookup_table{'0.96'} = '501';
    $reverse_scoring_probability_lookup_table{'0.97'} = '538';
    $reverse_scoring_probability_lookup_table{'0.98'} = '589';
    $reverse_scoring_probability_lookup_table{'0.99'} = '677';
}


1; # Magic true value required at end of module
__END__


=head1 NAME
 
Games::Ratings::Chess::FIDE - calculate changes to FIDE ratings (Elos)
 

=head1 VERSION
 
This document describes Games::Ratings::Chess::FIDE version 0.0.4
 

=head1 SYNOPSIS
 
 use Games::Ratings::Chess::FIDE;

 my $player = Games::Ratings::Chess::FIDE->new();
 $player->set_rating(2240);
 $player->set_coefficient(15);
 $player->add_game( {
                      opponent_rating => 2114,
                      result          => 'win',   ## or 'draw' or 'loss'
                    }
                  );

 my $rating_change = sprintf( "%+.2f", $player->get_rating_change() );
 my $new_rating = $player->get_new_rating();


=head1 DESCRIPTION

This module provides methods to calculate FIDE rating (Elo) changes for one
player, having played one or more rated games. Gains and losses are calculated
according to the FIDE rating rules (cmp. FIDE Rating Regulations, FIDE
Handbook B.02.10: http://www.fide.com/info/handbook?id=75&view=article).

FIDE uses a table with scoring probabilities in dependence from rating
differences between the players.

FIDE does _not_ use the formula P = 1/(1 + 10 ^ [D/400]).

Furthermore FIDE uses a development coefficient (K) depending on the current
rating and the number of rated games.
 * K = 25 for a player with a total of less than 30 games.
 * K = 15 as long as a player`s rating remains under 2400.
 * K = 10 once a player`s published rating has reached 2400
 

=head1 INTERFACE 

This modules provides the following methods specific to FIDE ratings. Other
(more generic) methods for rating calculation are provided by Games::Ratings.
Please check the documentation of Games::Ratings for those methods.

=head2 get_rating_change

  my $rating_change = sprintf("%+.2f", $player->get_rating_change() );

Calculate rating changes for all stored games and return sum of those
changes.

=head2 get_new_rating

  my $new_rating = $player->get_new_rating();

Calculate new rating after the given games.

=head2 get_points_expected

  my $points_expected = $player->get_points_expected();

Calculate expected points according to rating differences between own rating
and opponents ratings.

=head2 get_performance

  my $performance = $player->get_performance();

Calculate performance according to average rating of opponents and percentage
score.


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

At the moment, it's not possible to compute a FIDE rating for a previously unrated player.

Note, that a missing development coefficient (set via
$player->set_coefficient()) may lead to incorrect results. The program tries
to guess the correct factor according to the players rating, but it will err
for players new to the rating list with less than thirty games played.

Please report any bugs or feature requests to
C<bug-games-ratings@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Christian Bartolomaeus  C<< <bartolin@gmx.de> >>


=head1 ACKNOWLEDGMENTS

This module was inspired by Terrence Brannon's module Chess::Elo
(http://search.cpan.org/~tbone/Chess-Elo/).


=head1 SEE ALSO

http://en.wikipedia.org/wiki/Elo_rating for informations about the Elo system.

http://www.fide.com/info/handbook?id=11&view=category for informations about
the FIDE rating system (esp. point 10.0).


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
