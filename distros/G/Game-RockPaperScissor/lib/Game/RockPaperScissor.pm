package Game::RockPaperScissor;

use 5.006;
use strict;
use warnings;
use Carp qw/croak/;

=head1 NAME

Game::RockPaperScissor - object oriented  Game::RockPaperScissor!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

#see pod

sub new {
    my ($class, $args) = (@_);

    return (bless $args || {}, $class);
}

#see pod

sub get_result {
    my $self = shift;
    my $game = shift;

    $self->_validate($game);    #validate

    my $result = 0;

    my $win_matrix = {
        'r' => { 'p' => '-1', 's' => '1' },
        's' => { 'r' => '-1', 'p' => '1' },
        'p' => { 'r' => '1',  's' => '-1' }
    };

    return $result if ($game->{p1} eq $game->{p2});    #return for tie

    if (exists $game->{p1} && exists $game->{p2}) {
        my ($p1_choice, $p2_choice) = ($game->{p1}, $game->{p2});    #for readability
        $result = $win_matrix->{$p1_choice}->{$p2_choice};
    }
    return $result;
}
#see pod
sub get_result_modulus {
    my $self = shift;
    my $game = shift;

    $self->_validate($game);    #validate

    my $win_matrix = {
        's' => 0,
        'p' => 1,
        'r' => 2
    };

    my $result_map = {
        '1' => '-1', #p2 win
        '2' => '1',  #p1 win
        '0' => '0'   #tie
    };

    #use map
    my $value = ($win_matrix->{$game->{p1}} - $win_matrix->{$game->{p2}}) % 3 ;

    $value += 3 if($value < 0); #handle negative

    return $result_map->{$value};
}

#see pod

sub _validate {
    my $self = shift;
    my $game = shift;

    croak "Error Game hash needed eg. {'p1' =>'s' ,'p2' => 'r'}" unless (keys %{$game});

    foreach my $key (qw/p1 p2/) {
        if (!(defined $game->{$key} && exists $game->{$key})) {
            croak "Error Required key '$key' missing from hash params eg. {'p1' =>'s' ,'p2' => 'r'}";
        } else {
            $game->{$key} = lc(substr($game->{$key}, 0, 1));    #convert into subroutine specific format if not provided already
            if ($game->{$key} !~ /^(p|s|r)$/x) {
                croak 'Error Invalid symbol passed use "rock" or "paper" or "scissor"';
            }
        }
    }

    return;
}

1;

=head1 Game::RockPaperScissor

Game::RockPaperScissor package to output result for Rock - Paper - Scissor game.

=head1 SYNOPSIS

    use Game::RockPaperScissor;
    my $rps = Game::RockPaperScissor->new();
    my $game = {
        p1 => 'rock',
        p2 => 'scissor',
    };
   print $rps->get_result($game);

=head1 INTRODUCTION

Game::RockPaperScissor package ouputs the result of Rock - Paper - Scissor game for given choice by player 1 and player 2

=head1 METHODS

=head2 new

        use to create the instace of Game::RockPaperScissor class. Optional args can be passed
        Input : -
                Caller method
        Ouput :- 
                Game::RockPaperScissor class instance 
        
=head2 get_result

        used to return the result/ outcome of the game for player 1 only.
        Result belongs to the player 1. It validates the input before calculating outcome.
        Sub will die on invalid input stating the valid option to use.
        call _validate method see pod for more info
        Input :- 
                1) instance of class 
                2) hash ref of game with keys p1 and p2 with values as their respective choices.
        Mandatory input :-
         1) instance of class
         2) Keys p1 and p2
         {
            p1 => 'rock',  #valid choices ('rock|r' | 'paper|p' | 'scissor|s')
            p2 => 'paper'  #valid choices ('rock|r' | 'paper|p' | 'scissor|s')
        }
        Output :-
            return integer values :- 0 or 1 or -1
            0   => Tie
            1   => Win
           -1   => Loose

=head2 get_result_modulus

        #believe in TIMTOWTDI
        Yet another method using different algorithm that uses modulus
        used to return the result/ outcome of the game for player 1 only.
        Result belongs to the player 1. It validates the input before calculating outcome.
        Sub will die on invalid input stating the valid option to use.
        call _validate method see pod for more info
        Input :- 
                1) instance of class 
                2) hash ref of game with keys p1 and p2 with values as their respective choices.
        Mandatory input :-
         1) instance of class
         2) Keys p1 and p2
         {
            p1 => 'rock',  #valid choices ('rock|r' | 'paper|p' | 'scissor|s')
            p2 => 'paper'  #valid choices ('rock|r' | 'paper|p' | 'scissor|s')
        }
        Output :-
            return integer values :- 0 or 1 or -1
            0   => Tie
            1   => Win
           -1   => Loose
        
=head2 _validate

        internal private method not to be called outside,
        use to validate the input provided to get_result method
        Dies on invalid input
        Input :- hash ref of game with keys p1 and p2 with values as their respective choices.
                    Game hash needed eg. {'p1' =>'s' ,'p2' => 'r'} 
                                        or
                    Game hash needed eg. {'p1' =>'scissor' ,'p2' => 'Rock'}
        output :- 
                nothing

=cut


=head1 AUTHOR

Sushrut Pajai, C<< <spajai at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-rockpaperscissor at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-RockPaperScissor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::RockPaperScissor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-RockPaperScissor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Game-RockPaperScissor>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Game-RockPaperScissor>

=item * Search CPAN

L<https://metacpan.org/release/Game-RockPaperScissor>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Sushrut Pajai.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Game::RockPaperScissor
