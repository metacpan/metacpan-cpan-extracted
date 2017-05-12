package Games::Wumpus::Cave;

use 5.010;

use strict;
use warnings;
no  warnings 'syntax';

our $VERSION = '2009112401';

#
# Cave for the wumpus game.
#
#    Cave will contain rooms, and connections to various rooms.
#    Rooms may contain hazards: wumpus, bats, pits.
#

#
# Default layout is the one of a dodecahedron: vertices are rooms,
#    edges are tunnels.
#

use Games::Wumpus::Constants;
use Games::Wumpus::Room;
use Hash::Util::FieldHash qw [fieldhash];
use List::Util            qw [shuffle];

fieldhash my %rooms;      # List of rooms.
fieldhash my %wumpus;     # Location of the wumpus.
fieldhash my %start;      # Start location.
fieldhash my %location;   # Location of the player.

#
# Accessors
#
sub     rooms       {@{$rooms    {$_ [0]}}}
sub     room        {  $rooms    {$_ [0]} [$_ [1] - 1]}
sub     random_room {  $rooms    {$_ [0]} [rand @{$rooms {$_ [0]}}]}

sub     location    {  $location {$_ [0]}}
sub set_location    {  $location {$_ [0]} = $_ [1]; $_ [0]}

sub     wumpus      {  $wumpus   {$_ [0]}}
sub set_wumpus      {  $wumpus   {$_ [0]} = $_ [1]; $_ [0]}

sub     start       {  $start    {$_ [0]}}

#
# Construction
#
sub new {bless \do {my $var} => shift}

sub init {
    my $self = shift;
    my %args = @_;

    #
    # Classical layout.
    #
    $self -> _create_rooms (scalar @CLASSICAL_LAYOUT);
    $self -> _classical_layout (%args);

    $self -> _name_rooms       (%args);
    $self -> _create_hazards   (%args);

    if ($::DEBUG) {
        my %h;
        foreach my $room (@{$rooms {$self}}) {
            if ($room -> has_hazard ($WUMPUS)) {
                push @{$h {Wumpus}} => $room -> name;
            }
            if ($room -> has_hazard ($BAT)) {
                push @{$h {Bat}} => $room -> name;
            }
            if ($room -> has_hazard ($PIT)) {
                push @{$h {Pit}} => $room -> name;
            }
        }
        local $, = " ";
        say STDERR "Wumpus in", @{$h {Wumpus}};
        say STDERR "Bats in",   @{$h {Bat}};
        say STDERR "Pits in",   @{$h {Pit}};
    }

    $self;
}

#
# Create the given number of rooms. 
# Note that the rooms aren't named here, nor are either exits or hazards set.
#
sub _create_rooms {
    my $self  = shift;
    my $rooms = shift;

    $rooms {$self} = [map {Games::Wumpus::Room -> new -> init} 1 .. $rooms];

    $self;
}

#
# Create the classical layout
#
sub _classical_layout {
    my $self = shift;

     for (my $i = 0; $i < @CLASSICAL_LAYOUT; $i ++) {
        foreach my $exit (@{$CLASSICAL_LAYOUT [$i]}) {
            $rooms {$self} [$i] -> add_exit ($rooms {$self} [$exit]);
        }
     }

    $self;
}


#
# Randomly name the rooms; then store them in order.
#
sub _name_rooms {
    my $self  = shift;
    my %args  = @_;

    my $rooms = @{$rooms {$self}};
    my @names = 1 .. $rooms;
       @names = shuffle @names if $args {shuffle_names};

    for (my $i = 0; $i < @names; $i ++) {
        $rooms {$self} [$i] -> set_name ($names [$i]);
    }

    $rooms {$self} = [sort {$a -> name <=> $b -> name} @{$rooms {$self}}];

    $self;
}

#
# Assign hazards to rooms. Initially, no room will have more than one hazard.
# This method also assigns the start location (hazard free).
#
sub _create_hazards {
    my $self  = shift;

    my @rooms = shuffle @{$rooms {$self}};

    my $wumpus_room = pop @rooms;
    $wumpus_room -> set_hazard ($WUMPUS);

    $self -> set_wumpus ($wumpus_room);

   (pop @rooms) -> set_hazard ($PIT)    for 1 .. $NR_OF_PITS;
   (pop @rooms) -> set_hazard ($BAT)    for 1 .. $NR_OF_BATS;

    $start {$self} = pop @rooms;

    $self;
}


#
# Describe the room the player is currently in.
#
sub describe {
    my $self = shift;

    my $text;

    my $room = $self -> location;

    $text  = "You are in room " . $room -> name . ".\n";
    $text .= "I smell a Wumpus!\n" if $room -> near_hazard ($WUMPUS);
    $text .= "I feel a draft.\n"   if $room -> near_hazard ($PIT);
    $text .= "Bats nearby!\n"      if $room -> near_hazard ($BAT);

    $text .= "Tunnels lead to " . join " ", sort {$a <=> $b}
                                            map  {$_ -> name} $room -> exits;
    $text .= ".\n";

    $text;
}


#
# Return whether player can move from current destination to new location.
#
# If the current location has an exit with the given name, then yes.
#
sub can_move_to {
    my $self = shift;
    my $new  = shift;

    $self -> location -> exit_by_name ($new) ? 1 : 0;
}


#
# Move the player to a new location. Return the hazards encountered.
# Since bats may move the player, encountering a new hazard, more
# than one hazard may be encountered.
#
sub move {
    my $self = shift;
    my $new  = shift;

    my @hazards;

    $self -> set_location ($self -> room ($new));

    if ($self -> location -> has_hazard ($WUMPUS)) {
        # Death.
        return $WUMPUS;
    }
    if ($self -> location -> has_hazard ($PIT)) {
        # Death.
        return $PIT;
    }
    if ($self -> location -> has_hazard ($BAT)) {
        # Moved.
        return $BAT, $self -> move ($self -> random_room -> name);
    }

    # Nothing special.
    return;
}


#
# Shoot an arrow. Return the first thing hit (ends shot). 
# If a tunnel doesn't exist, pick something at random.
#
sub shoot {
    my $self = shift;
    my @path = @_;

    my $cur  = $self -> location;

    foreach my $p (@path) {
        #
        # Is $p a valid exit of $cur?
        #
        my $e = $cur -> exit_by_name ($p);
        unless ($e) {
            #
            # Not a valid exit. Pick one at random.
            #
            my @e = $cur -> exits;
            $e = $e [rand @e];
        }
        $cur = $e;

        if ($cur -> has_hazard ($WUMPUS)) {return $WUMPUS}
        if ($cur == $self -> location)    {return $PLAYER}
    }
}



#
# Stir the Wumpus. It *may* move.
#
# Return true if it moves, false otherwise.
#
sub stir_wumpus {
    my $self = shift;

    if (rand (1) < $WUMPUS_MOVES) {
        #
        # He moves.
        #
        my @exits = $self -> wumpus -> exits;
        my $new   = $exits [rand @exits];

        if ($::DEBUG) {
            say STDERR "Wumpus moves to ", $new -> name;
        }

        $self -> wumpus -> clear_hazard ($WUMPUS);
        $new  -> set_hazard ($WUMPUS);
        $self -> set_wumpus ($new);
        return 1;
    }

    return 0;
}


__END__

=head1 NAME

Games::Wumpus::Cave - Cave used for Hunt the Wumpus

=head1 SYNOPSIS

 my $cave = Games::Wumpus::Cave -> new -> init;

 $survivor = $cave -> move  ($location);
 @hazards  = $cave -> shoot (@path);


=head1 DESCRIPTION

C<< Games::Wumpus::Cave >> is used to keep track of the cave system of
Hunt the Wumpus. It's used by C<< Games::Wumpus >> and should most likely
not be used outside of C<< Games::Wumpus >>.

The following methods are implemented:

=over 4

=item C<< new >>

Class method returning an unintialized object.

=item C<< init >>

Initializes the cave system. Creates layout mimicing a dodecahedron:
vertices are rooms, and edged are tunnels. After creating the layout,
hazards (Wumpus, bats, pits) are randomly placed in the cave system.
Then a start location is picked. The start location is garanteed not
to contain a hazard. 

=item C<< rooms >>

Accessor returning all rooms in the cave system.

=item C<< room >>

Accessor returning room with the given name (small, non-negative integer).

=item C<< random_room >>

Accessor returning a random room from the cave system.

=item C<< location >>

Accessor returning the current location (room) of the player.

=item C<< set_location >>

Accessor setting the current location of the player.

=item C<< wumpus >>

Accessor returning the location of the Wumpus.

=item C<< set_wumpus >>

Accessor setting the location of the Wumpus.

=item C<< start >>

Accessor returning the start location of the player.

=item C<< describe >>

Describes the location the player is currently in, including outgoing
tunnels, and nearby hazards. The description is returned as a string.

=item C<< can_move_to >>

Takes a location as argument. Returns true if there's a tunnel from the
players current location to the given location, false otherwise.

=item C<< move >>

Move the player to the location given as argument. If the new location
contains a bat, the player is dropped in a random location elsewhere in
the cave system. Returns a (possibly empty) list of hazards encountered.
If the list is non-empty, the last element of the list is either
C<< $WUMPUS >> or C<< $PIT >>; all other elements must be C<< $BAT >>.

=item C<< shoot >>

Shoot an arrow from the players current location following the given path.
Returns false if not hitting anything; the object hit (C<< $WUMPUS >> or
C<< $PLAYER >>) otherwise. If the path contains a room which cannot be
reached using a tunnel from the arrows current location, a random tunnel
will be choosen.

=item C<< stir_wumpus >>

Poke the Wumpus. With a certain chance (C<< $WUMPUS_MOVES >>), the Wumpus
picks a random tunnel and moves to the room at the other end. Returns
true if the Wumpus moved, false otherwise.

=back

=head1 BUGS

None known.

=head1 TODO

Configuration of the game should be possible.

=head1 SEE ALSO

L<< Games::Wumpus >>, L<< Games::Wumpus::Room >>,
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
