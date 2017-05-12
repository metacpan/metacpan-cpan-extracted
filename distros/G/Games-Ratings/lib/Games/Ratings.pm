package Games::Ratings;

## TODO: Error handling
##       * croak()
##       check arguments for subroutines (use Data::Checker)?

use warnings;
use strict;
use Carp;

use 5.6.1;               # 'our' was introduced in perl 5.6
use version; our $VERSION = qv('0.0.5');

use Class::Std::Utils;   # we are using inside-out objects

{
    ## objects of this class (players) will have the following attributes
    my %rating_of;       # rating of player
    my %coefficient_of;  # coefficient of player
    my %games_of;        # list of games of player

    ## create new object (inside-out object -- see "Encapsulation" in PBP)
    sub new {
        my ($class) = @_;

        ## bless a scalar to instantiate the new object
        my $new_player_object = bless anon_scalar(), $class;

        return $new_player_object;
    }

    ## set rating according to passed argument
    sub set_rating {
        my ($self, $rating) = @_;

        ## check that rating is passed as argument
        croak( 'Usage: $obj->set_rating($rating)' )
            if @_ < 2;

        ## store rating in player object
        $rating_of{ident $self} = $rating;

        return;
    }
    
    ## return previously set rating
    sub get_rating {
        my ($self) = @_;
        return $rating_of{ident $self};
    }
    
    ## set coefficient according to passed argument
    sub set_coefficient {
        my ($self, $coefficient) = @_;

        ## check that coefficient is passed as argument
        croak( 'Usage: $obj->set_coefficient($coefficient)' )
            if @_ < 2;
        
        ## store coefficient in player object
        $coefficient_of{ident $self} = $coefficient;

        return;
    }
    
    ## return previously set coefficient
    sub get_coefficient {
        my ($self) = @_;
        return $coefficient_of{ident $self};
    }
    
    ## add new game to list of games ($games_of{ident $self} is list of games)
    sub add_game {
        my ($self, $game_ref) = @_;

        ## check that new game is passed as argument (hash reference) 
        croak( 'Usage: $obj->add_game( { 
                         opponent_rating => 2300,
                         result          => \'draw\',
                       }
                     );
                     ' )
            if @_ < 2;

        ## store additional game in player object
        push @{ $games_of{ident $self} }, $game_ref;

        return;
    }

    ## return all previously added games as a list of hash references
    sub get_all_games {
        my ($self) = @_;

        ## return list of games or throw an error if $self doesn't have games
        if ( $games_of{ident $self} ) {
            return @{ $games_of{ident $self} };
        }
        else {
            croak( 'There aren\'t any games played. Please use add_game().' )
        }
    }
    
    ## delete all previously added games
    sub remove_all_games {
        my ($self) = @_;
        $games_of{ident $self} = undef;
        return;
    }

    ## clean up attributes when object is destroyed
    sub DESTROY {
        my ($self) = @_;

        delete $rating_of{ident $self};
        delete $coefficient_of{ident $self};
        delete $games_of{ident $self};

        return;
    }
}
    
## return number of played games
sub get_number_of_games_played {
    my ($self) = @_;

    ## number of played games equals length of array of played games
    return scalar $self->get_all_games();
}

## calculate and return scored points
sub get_points_scored {
    my ($self) = @_;
    
    ## compute scored points from list of played games
    my $points_scored;
    foreach my $game_ref ( $self->get_all_games() ) {
        $points_scored += _get_numerical_result( $game_ref->{result} );
    }

    ## return scored points
    return $points_scored;
}

## calculate percentage score
sub get_percentage_score {
    my ($self) = @_;

    ## compute percentage score
    my $percentage_score = $self->get_points_scored() 
                           / $self->get_number_of_games_played();

    ## return percentage score
    return $percentage_score;
}

## calculate and return return average rating of opponents
sub get_average_rating_of_opponents {
    my ($self) = @_;
    
    ## calculate average rating of opponents from (list of) stored games
    my $rat_opps;
    foreach my $game_ref ( $self->get_all_games() ) {
        $rat_opps += $game_ref->{opponent_rating},
    }
    $rat_opps = sprintf( "%.f", $rat_opps 
                                / $self->get_number_of_games_played() );

    ## return average rating of opponents
    return $rat_opps;
}

## define lookup table for conversion 'verbal results' -> 'numerical results'
my %numerical_results = (
    win  =>   1,
    draw => 0.5,
    loss =>   0,
);

## get numerical result of $result (win, draw, loss)
sub _get_numerical_result {
    my ($result) = @_;

    ## numerical result is looked up in a small table (see above)
    my $numerical_result = $numerical_results{$result};

    ## return numerical result
    return $numerical_result;
}

1; # Magic true value required at end of module
__END__


=head1 NAME

Games::Ratings - generic methods for rating calculation (e.g. chess ratings)


=head1 VERSION

This document describes Games::Ratings version 0.0.5


=head1 SYNOPSIS

 ## not very useful, but one could do
 
 use Games::Ratings;
 my $player = Games::Ratings->new();
 $player->set_rating(2240);
 $player->add_game( {
                      opponent_rating => 2114,
                      result          => 'win',   ## or 'draw' or 'loss'
                    }
                  );
 my $n                = $player->get_number_of_games_played();
 my $points_scored    = $player->get_points_scored();
 my $opponents_rating = $player->get_average_rating_of_opponents();
 $player->remove_all_games;

  
=head1 DESCRIPTION

Games::Ratings provides some generic methods for other, more specific modules
(like Games::Ratings::Chess::FIDE or Games::Ratings::Chess::DWZ). It isn't
very useful for itself.


=head1 INTERFACE 

The following methods can be accessed from more specific modules -- like
Games::Ratings::Chess::FIDE. Also specific methods for rating calculation are
defined in those other modules.

=head2 new

  my $player = Games::Rating->new();

Create an object for storing rating and other data (like the FIDE development
coefficient) for one player as well as informations about rated games of this
player against some opponents.

=head2 set_rating

  $player->set_rating(2235);

Set rating of player.

=head2 get_rating

  my $own_rating = $player->get_rating();

Get rating of player.

=head2 set_coefficient

  $player->set_coefficient(15);

Set development coefficient of player. (A development coefficient is needed
for calculation of some ratings:
 * FIDE Elo (FIDE Handbook, B.02.10.52) 
 * German DWZ (Wertungsordnung des DSB, Punkt 4.9.2)).

=head2 get_coefficient

  my $own_coefficient = $player->get_coefficient();

Get development coefficient of player.

=head2 add_game

  $player->add_game( {
                       opponent_rating => 2184,
                       result          => 'draw',
                     }
                   );

Add rated game to object. We need opponents rating and the result of the game.
Results are one of 'win', 'draw' or 'loss'. The data is passed as hash
reference.

=head2 get_all_games

  my @list_of_games = $player->get_all_games();

Get list of previously added games. Each game is represented by a hash
reference (cmp. $player->add_game() ).

=head2 remove_all_games

  $player->remove_all_games();

Remove all games added (via 'add_game') so far.

=head2 DESTROY

  $player->DESTROY();

Remove object $player.

=head2 get_number_of_games_played

  my $n = $player->get_number_of_games_player();

Get number of games played.

=head2 get_points_scored

  my $points_scored = $player->get_points_scored();

Get total points scored in played games. A win gives 1 point, a draw gives 0.5
points, a loss gives 0 points.

=head2 get_percentage_score

  my $percentage_score = $player->get_percentage_score();

Get percentage score in played games.

=head2 get_average_rating_of_opponents

  my $opponents_rating = $player->get_average_rating_of_opponents();

Get average rating of opponents for played games.


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

=back

 
=head1 CONFIGURATION AND ENVIRONMENT

Games::Ratings requires no configuration files or environment variables.


=head1 DEPENDENCIES

Requires the C<Class::Std::Utils> module and the C<version> module. Needs Perl
5.6.1 or higher.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

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
