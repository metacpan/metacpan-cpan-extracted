package Games::Wumpus;

use 5.010;
use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2009112401';

use Hash::Util::FieldHash qw [fieldhash];

use Games::Wumpus::Constants;
use Games::Wumpus::Cave;
use Games::Wumpus::Room;

fieldhash my %cave;
fieldhash my %arrows;
fieldhash my %finished;

sub new  {bless \do {my $var} => shift}
sub init {
    my $self = shift;
    my %args = @_;

    $cave     {$self} = Games::Wumpus::Cave -> new -> init (%args);
    $arrows   {$self} = $NR_OF_ARROWS;

    $cave     {$self} -> set_location ($cave {$self} -> start);

    $self;
}

#
# Accessors
#
sub cave       {   $cave     {$_ [0]}}
sub arrows     {   $arrows   {$_ [0]}}
sub lose_arrow {-- $arrows   {$_ [0]}}
sub finished   {   $finished {$_ [0]}}
sub win        {   $finished {$_ [0]} = 1}
sub lose       {   $finished {$_ [0]} = 0}


#
# Describe the current situation
#
sub describe {
    my $self = shift;
    
    my $text = $self -> cave -> describe;
    $text .= "You have " . $self -> arrows . " arrows left.\n";

    $text;
}

#
# Try to move a different room. The argument is well formatted, 
# but not necessarely valid.
#
sub move {
    my $self = shift;
    my $new  = shift;

    unless ($self -> cave -> can_move_to ($new)) {
        return (0, "There's no tunnel to $new.");
    }

    my @hazards = $self -> cave -> move ($new);

    my @messages;
    foreach (@hazards) {
        when ($WUMPUS) {
            $self -> lose;
            push @messages => "Oops! Bumped into a Wumpus!";
        }
        when ($PIT) {
            $self -> lose;
            push @messages => "YYYIIIIEEEE! Fell in a pit!";
        }
        when ($BAT) {
            push @messages => "ZAP! Super bat snatch! Elsewhereville for you!";
        }
    }
    return 1, @messages;

}


#
# Try to move a different room. The argument is well formatted, 
# but not necessarely valid.
#
sub shoot {
    my $self  = shift;
    my @rooms = @_;

    if ($self -> arrows < 1) {
        #
        # This shouldn't be able to happen.
        #
        $self -> lose;
        return 0, "You are out of arrows";
    }

    unless ($self -> cave -> can_move_to ($rooms [0])) {
        return (0, "There's no tunnel to " . $rooms [0]);
    }

    for (my $i = 2; $i < @rooms; $i ++) {
        if ($rooms [$i] eq $rooms [$i - 2]) {
            return 0, "Arrows aren't that crooked - try another path";
        }
    }

    my $hit = $self -> cave -> shoot (@rooms);

    my @mess;
    given ($hit) {
        when ($WUMPUS) {
            $self -> win;
            return 1, "Ha! You got the Wumpus!";
        }
        when ($PLAYER) {
            $self -> lose;
            return 1, "Ouch! Arrow got you!";
        }
        default {
            push @mess => "Missed!";
        }
    }

    $self -> cave -> stir_wumpus;

    if ($self -> cave -> wumpus == $self -> cave -> location) {
        $self -> lose;
        return 1, @mess, "Tsk Tsk Tsk - Wumpus got you!";
    }

    if ($self -> lose_arrow < 1) {
        $self -> lose;
        return 1, @mess,
                 "You ran out of arrows. Wumpus will eventually eat you."
    }

    return 1, @mess;
}


1;

__END__

=head1 NAME

Games::Wumpus - Play Hunt the Wumpus

=head1 SYNOPSIS

 my $game = Games::Wumpus -> new -> init;

 while (!defined $game -> finished) {
    ($status, @messages) = $game -> move  ($someplace);
    say for @messages;
    ($status, @messages) = $game -> shoot (@somewhere);
    say for @messages;
 }

 if ($game -> finished) {say "Won!"}
 else                   {say "Lost!"}

=head1 DESCRIPTION

This class can be used to play a game of Hunt the Wumpus. It will keep
state, perform action, and deduce whether a game is won or lost.

The following methods are available:

=over 4

=item C<< new >>

Class methods that returns an uninitialized object.

=item C<< init >>

Initializes an object. Creates a C<< Games::Wumpus::Cave >> object,
fills the players quiver with arrows, and places the player at the
start location. Returns the initialized object.

=item C<< cave >>

Accessor returning the cave used in the current game.

=item C<< item >>

Accessor returning the number of arrows.

=item C<< lose_arrow >>

Accessor to reduce the number of arrows by one.

=item C<< finished >>

Accessor returning the win/lose state of the game. If an undefined value
is returned, the game isn't finished yet. A false but defined value means
the player has lost the game (eaten by the Wumpus, fallen in a pit, shot
by an arrow, ran out of arrows). A true value means the game was won 
(the Wumpus was shot).

=item C<< win >>

Accessor setting a win for the player.

=item C<< lose >>

Accessor setting the game lost for the player.

=item C<< describe >>

Returns a string describing where the player is in the cave, the tunnels
leading from the current location, any hints regarding nearby hazards, 
and the number of arrows left.

=item C<< move >>

Takes a new location as argument. It assumes the argument is well formatted - 
that is, exactly one, defined, argument is parsed. Returns a status and a
list of strings. If the player cannot move to the specified location
C<< 0 >> is returned as status, and the reason why as a string. Otherwise
C<< 1 >> is returned, and a (possibly empty) list of strings describing
encounters with hazards. If the Wumpus or a pit is encountered, the game
is declared a loss.

=item C<< shoot >>

Takes a list (1 to 5) of locations as argument -- the path a shot arrow
must follow. It assumes the argument is well formatted, 1 to 5 defined
values. Returns a status and a list of strings. If the shot cannot be
performed (no arrows, path goes through the same tunnel twice in succession,
first location isn't connected to current location), C<< 0 >> and the reason
why the shot cannot be performed is returned as status and list of strings.
Otherwise, C<< 1 >> is returned, and list of strings describing interesting
events. If the Wumpus is shot, the game is won. If the player is shot, the
game is lost. Shooting an arrow may cause the Wumpus to move (and eat you).

=back

=head1 BUGS

None known.

=head1 TODO

Configuration of the game should be possible.

=head1 SEE ALSO

L<< Games::Wumpus::Cave >>, L<< Games::Wumpus::Room >>,
L<< Games::Wumpus::Constants >>

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Games--Wumpus.git >>.

=head1 AUTHOR

Abigail, L<< mailto:wumpus@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2009 by Abigail.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),   
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the 
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
