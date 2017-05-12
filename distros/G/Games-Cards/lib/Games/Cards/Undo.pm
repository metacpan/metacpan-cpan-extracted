package Games::Cards::Undo;

# part of Games::Cards by Amir Karger (See Cards.pm for details)

=pod

=head1 NAME

Games::Cards::Undo -- undoing/redoing moves in Games::Cards games

=head1 SYNOPSIS

    use Games::Cards::Undo;
    $Undo = new Games::Cards::Undo(100); # Make undo engine to save 100 moves
    $Undo->undo; # undo last move
    $Undo->redo; # redo last undone move
    $Undo->end_move; # tell undo engine we're done with a move

=head1 DESCRIPTION

This is the package for methods to undo & redo moves. The GC::Undo object has
no publicly accessible fields.  But it stores an array of the
preceding moves. Note that a "move" is made up of several "atoms" (objects of
the private class GC::Undo::Atom and its subclassess).  For example, moving a
card from one column to another in solitaire involves one or more Splice atoms
(removing or adding card(s) to a CardSet) and possibly a Face atom (turning a
card over).

Many of the GC::Undo methods (and all of the GC::Undo::Atom methods) will be
called by other Games::Cards methods, but not by the actual games. Here are
the publicly accesssible methods:

=over 4

=cut

# TODO write Undo::Sort?


# sub-packages
{
package Games::Cards::Undo;
package Games::Cards::Undo::Atom;
package Games::Cards::Undo::Splice;
package Games::Cards::Undo::Face;
package Games::Cards::Undo::End_Move;
}

# How does Games::Cards handle undo?
#
# Undo_List is just an array of (objects from derived classes of) Undo::Atoms.
# E.g. in solitaire one "move" might include moving cards from one column to
# another (two Undo::Splice objects) and turning a card over (a Undo::Face
# object) The undo list will store those Atoms as well as an End_Move object,
# which is just a placeholder saying that move is over.

# Global private variables
# Can't keep this info in an object, because private GC subroutines
# (like CardSet::splice) need access to the Undo list, and I shouldn't have
# to pass the undo object around to every sub.
# GC::Undo::Undo_List holds all previous moves in GC::Undo::Atom objects
# GC::Undo::Current_Atom is the index of the current Atom in @Undo_List
# GC::Undo::Max_Size is the maximum size (moves, not Atoms!) of the undo list
# GC::Undo::In_Undo says that we're currently doing (or undoing) an Undo, so we
# shouldn't store undo information when we move cards around
my (@Undo_List, $Current_Atom, $Max_Size, $In_Undo);

=item new(MOVES)

Initialize the Undo engine. MOVES is the number of atoms to save.
0 (or no argument) allows infinite undo.

This method must be called before any undo-able moves are made (i.e., it can be
called after the hands are dealt).  This method will also re-initialize the
engine for a new game.

=cut

    sub new {
	my $class = shift;
	# (re)set global private variables
	$Max_Size = shift || 0;
        $Current_Atom = -1;
	@Undo_List = ();
	$In_Undo = 0;

	# Make the (dummy) object to give a "handle" for methods
	my $thing = {};
	bless $thing, $class;
	return $thing;
    }

=item end_move

End the current move. Everything between the last call to end_move and now
is considered one move. This tells undo how much to undo.

=cut

    sub end_move {
	# Don't store anything if no atoms have been stored since the
	# last End_Move atom. This could happen e.g. if someone does
	# an illegal move & then wants to undo it.
	if (! defined $Current_Atom || 
	   $Current_Atom == -1 ||
	   ref($Undo_List[$Current_Atom]) eq "Games::Cards::Undo::End_Move") {
	       return;
	}

	# calling with just "store(foo)" there aren't enough args!
	my $atom = new Games::Cards::Undo::End_Move;
	$atom->store;
    } # end sub Games::Cards::Undo::end_move

    sub store {
    # Stores a move in the undo list, which can later be undone or redone. The
    # first argument is the type of move to store, other args give details about
    # the move depending on the move type.
    #
    # arg1 is a subclass of Undo::Atom
	# Don't store moves if the undo engine hasn't been initialized
	return unless defined $Current_Atom;

	# don't store undo moves when we're currently implementing an undo/redo
	return if $In_Undo; 

        shift; # ignore class
	my $atom = shift; # the Undo::Atom to store

	# If we undid some moves & then do a new move instead of redoing,
	# then erase the moves we undid
	$#Undo_List = $Current_Atom;

	# Now add the move to the undo list
	push @Undo_List, $atom;

	# If the list is too big, remove a whole move (not just an Atom)
	# from the beginning of the list (oldest undos)
	my $end_class = "Games::Cards::Undo::End_Move";
	if ($Max_Size && grep {ref eq $end_class} @Undo_List > $Max_Size) {
	    $atom = shift @Undo_List until ref($atom) eq $end_class;
	}

	$Current_Atom = $#Undo_List;

        return 1;
    } # end sub Games::Cards::Undo::store

=item undo

Undo a move.

=cut

    sub undo {
    # undoing a move means undoing all the Atoms since the last
    # End_Move Atom
    # Note that this sub can (?) also undo from the middle of a move
	# If called w/ class instead of object, and we never called new(),
	# then return. This shouldn't happen.
	return unless defined $Current_Atom; # never called new
	return if $Current_Atom == -1;
	$In_Undo = 1; # Don't store info when moving cards around

	# Loop until the next End_Move Atom or until we exhaust the undo list
	my $end_class= "Games::Cards::Undo::End_Move";
	$Current_Atom-- if ref($Undo_List[$Current_Atom]) eq $end_class;
	for (;$Current_Atom > -1; $Current_Atom--) {
	   my $atom = $Undo_List[$Current_Atom];
	   last if ref($atom) eq $end_class;
	   $atom->undo;
	}
	# now $Current_Atom is on the End_Move at the end of the last move

	$In_Undo = 0; # done undoing. Allowed to store again.
	return 1;
    } # end sub Games::Cards::Undo::undo


=item redo

Redo a move that had been undone with undo.

=cut

    sub redo {
    # redoing a move means redoing every Atom from the current atom
    # (which should be an End_Move) until the next End_Move atom
	# If called w/ class instead of object, and we never called new(),
	# then return. This shouldn't happen.
	return unless defined $Current_Atom; 
	return if $Current_Atom == $#Undo_List;
	$In_Undo = 1; # Don't store info when moving cards around

	# Loop until the next End_Move Atom or until we exhaust the undo list
	my $atom;
	my $end_class = "Games::Cards::Undo::End_Move";
	$Current_Atom++ if ref($Undo_List[$Current_Atom]) eq $end_class;
	for (;$Current_Atom <= $#Undo_List; $Current_Atom++) {
	   my $atom = $Undo_List[$Current_Atom];
	   last if ref($atom) eq $end_class;
	   $atom->redo;
	}
	# now $Current_Atom is on the End_Move at the end of this move

	$In_Undo = 0; # done redoing. Allowed to store again.
	return 1;
    } # end sub Games::Cards::Undo::redo

=back

=cut

{
package Games::Cards::Undo::Atom;
# A CG::Undo::Atom object stores the smallest indivisible amount of undo
# information. The subclasses of this class implement different kinds of atoms,
# as well as the way to undo and redo them.

    sub new {
    # This new will be used by subclasses
    # arg0 is the class. arg1 is a hashref containing various fields. Just
    # store 'em.
        my $class = shift;
	my $atom = shift || {};

	# turn it into an undo move
	bless $atom, $class;
    } # end sub Games::Cards::Undo::Atom::new

    sub store {
    # Store this Atom in the Undo List
        Games::Cards::Undo->store(shift);
    } # end sub Games::Cards::Undo::Atom::store

} # end package Games::Cards::Undo::Atom

{
package Games::Cards::Undo::End_Move;
# An Undo::End_Move is just a marker. Everything in the Undo_List from just
# after the last End_Move until this one is one "move". 

    @Games::Cards::Undo::End_Move::ISA = qw(Games::Cards::Undo::Atom);

    # inherit SUPER::new
    # No other methods necessary!

} # end package Games::Cards::Undo::End_Move

{
package Games::Cards::Undo::Face;
# This object stores the act of turning a card over

    @Games::Cards::Undo::Face::ISA = qw(Games::Cards::Undo::Atom);

    # inherit SUPER::new

    sub undo {
        my $face = shift;
	my ($card, $direction) = ($face->{"card"}, $face->{"direction"});
	if ($direction eq "up") {
	    $card->face_down;
	} elsif ($direction eq "down") {
	    $card->face_up;
	} else {
	    my $func = (caller(0))[3];
	    die ("$func called with unknown direction $direction\n");
	}
    } # end sub Games::Cards::Undo::Face::undo

    sub redo {
        my $face = shift;
	my ($card, $direction) = ($face->{"card"}, $face->{"direction"});
	if ($direction eq "up") {
	    $card->face_up;
	} elsif ($direction eq "down") {
	    $card->face_down;
	} else {
	    my $func = (caller(0))[3];
	    die ("$func called with unknown direction $direction\n");
	}
    } # end sub Games::Cards::Undo::Face::redo

} # end package Games::Cards::Undo::Face

{
package Games::Cards::Undo::Splice;
# This object stores the act of adding or removing cards from a CardSet, i.e.
# one of these objects gets created each time GC::CardSet::splice is called.
# This stores most of the actions in a card game.

    @Games::Cards::Undo::Splice::ISA = qw(Games::Cards::Undo::Atom);

    # inherit SUPER::new

    sub undo {
    # If we changed ARRAY by doing:
    # RESULT = splice(ARRAY, OFFSET, LENGTH, LIST);
    # then we can return ARRAY to its original form by
    # splice(ARRAY, OFFSET, scalar(LIST), RESULT);
    #
    # (sub splice also made sure that for calls to splice without 
    # all the arguments, the missing arguments were added, and that OFFSET
    # would be >= 0)

	my $splice = shift;
	# Could do this quicket with no strict refs :)
	my ($set, $offset, $in_cards, $out_cards) = 
	    map {$splice->{$_}} qw(set offset in_cards out_cards);

	# Do the anti-splice and return its return value
	# (Return will actually be in_cards!)
	$set->splice ($offset, scalar(@$in_cards), $out_cards);
    } # end sub Cards::Games::Undo::Splice::undo

    sub redo {
    # we changed ARRAY by doing:
    # RESULT = splice(ARRAY, OFFSET, LENGTH, LIST);
    # Just redo the splice.
    # (sub splice also made sure that for calls to splice without 
    # all the arguments, the missing arguments were added, and that OFFSET
    # would be >= 0)

	my $splice = shift;
	# Could do this quicket with no strict refs :)
	my ($set, $offset, $in_cards, $length) = 
	    map {$splice->{$_}} qw(set offset in_cards length);

	# Do the splice and return its return value
	# (Return will actually be out_cards!)
	$set->splice ($offset, $length, $in_cards);
    } # end sub Cards::Games::Undo::Splice::redo

} # end package Games::Cards::Undo::Splice

1; # end package Games::Cards::Undo
