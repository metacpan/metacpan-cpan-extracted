package Games::Cards::Tk;
# Pieces of this came from the freecell.tk that Michael Houghton sent me

=head1 NAME

Games::Cards::Tk - Package to write Tk ports for Games::Cards card games

=head1 SYNOPSIS

See L<Games::Cards> for all the non-GUI aspects of writing card games.

    use Games::Cards;
    use Games::Cards::Tk;

    # Create a canvas and print background etc.
    $My_Game->set_canvas($c); # my game will use canvas $c

    # ... do lots of things you do in Games::Cards anyway
    # Cards' Tk images will be moved automatically!
    $Stock->give_cards($Waste, 3);

    # Mark clicked card
    $card = $My_Game->get_card_by_tag("current");
    $card->mark;

=head1 DESCRIPTION

=head2 WARNING!!!

This module is doubleplus alpha. It's entirely possible that large parts
of it will be changing as I learn more Tk, and if you try to write a game
that's much different from the included games, it may break. There's
still some stuff that needs to be better modularized, abstracted, and
otherwise made into good code.  However, the current games seem to be pretty
good for a first try, and I'd like to get comments in case I'm doing
anything really stupid.

=head2 Overview

Each class in Games::Cards had a corresponding Games::Cards::Tk class.
The classes are meant to be exactly the same, except that the Tk ones
also take care of moving actual card images around the screen.

The card images used were created by Oliver Xymoron (oxymoron@waste.org).

=cut

use strict;

{
package Games::Cards::Tk::Game;
@Games::Cards::Tk::Game::ISA = qw (Games::Cards::Game);

=head2 Class Games::Cards::Tk::Game

This class ends up holding information - such as the canvas that the game is
played on, card images - and methods like finding a card given its tag.

=over 4

=item card_width

=item card_height

The size of card images

=cut

sub card_width { shift->{"card_width"} }
sub card_height { shift->{"card_height"} }

=item load_card_images

Loads the card images and stores them to draw later.

=cut

sub load_card_images {

    my $image_dir = Tk::findINC("Games/Cards/images/");

    my $self = shift;
    my $canvas = $self->canvas;

    # Oxymoron's images are stored as two-char names.
    # First letter is [1-9tjqka], second is [cdhs]
    my %name_hash = (
	"Ace" => "a",
	10 => "t",
	"Jack" => "j",
	"Queen" => "q",
	"King" => "k",
    );

    # Load each card image
    my $im;
    foreach my $suit (@{$self->{"suits"}}) {
	my $s = substr($suit,0,1);
	foreach my $name (keys %{$self->{"cards_in_suit"}}) {
	    my $n = exists $name_hash{$name} ? $name_hash{$name} : $name;
	    my $f = $n . lc($s);
	    $im = $canvas->Photo(-file => "$image_dir/$f.gif");
	    my $key = $name.$suit;
	    $self->{"card_images"}->{$key} = $im;
	}
    }

    $im = $canvas->Photo(-file => "$image_dir/b.gif");
    $self->{"card_images"}->{"back"} = $im;
    $self->{"card_width"}  = $im->width;
    $self->{"card_height"} = $im->height;
}

=item card_image

Returns the card image associated with this card.

=cut

sub card_image {
    my ($self, $card) = @_;
    if (ref($card)) {
	my $key = $card->name("long") . $card->suit("long");
	if (exists ($self->{"card_images"}->{$key})) {
	    return $self->{"card_images"}->{$key};
	} else {
	    return undef;
	}
    } else {
        return undef unless $card eq "back";
	return $self->{"card_images"}->{"back"};
    }
}

=item get_card_by_tag

Given a tag, return the Card (on this Games' canvas) that has that tag, if any.

=cut

sub get_card_by_tag {
    my ($self, $tag) = @_;
    my $canvas = $self->canvas;
    my @ids = $canvas->find(withtag => $tag);
    # Find cardfront: or cardback: tag for each Id
    my @cards = grep /^card(back|front):/, map {$canvas->gettags($_)} @ids;

    if (@cards) {
	# TODO in fact, maybe we should allow multiple cards
	# Actually, this will probably break if front & back have the tag!
	warn "too many cards!" if @cards > 1;
	my $tag = $cards[0];
	$tag =~ s/^card(front|back)://;
	my $card = $self->get_card_by_truename($tag);
	return $card;
    } else {
        return undef;
    }
}

=item get_card_by_tag

Given a tag, return the CardSet (on this Games' canvas) that has that tag, if
any.

=cut

sub get_cardset_by_tag {
    my ($self, $tag) = @_;
    my $canvas = $self->canvas;
    my @ids = $canvas->find(withtag => $tag);
    my @sets = grep /^set:/, map {$canvas->gettags($_)} @ids;

    if (@sets) {
	warn "too many sets!" if @sets > 1;
	my $tag = $sets[0];
	$tag =~ s/^set://;
	my $card = $self->get_cardset_by_name($tag);
	return $card;
    } else {
    print "help!\n";
        return undef;
    }
}

=item get_marked_card

Is a card marked? If so, return it.

=cut

sub get_marked_card {
    my $self = shift;
    my $tag = "marked";
    return $self->get_card_by_tag($tag);
}

=item get_clicked_cardset

Return the set which was clicked on.  Do so by looking for the "current" tag,
but note that that tag may apply either to a CardSet or to a Card in that set.

=cut

sub get_clicked_cardset {
    my $self = shift;
    my $tag = "current";
    if (defined (my $card = $self->get_card_by_tag($tag))) {
        return $card->owning_cardset;
    } else {
	return $self->get_cardset_by_tag($tag);
    }
}

=item canvas

=item set_canvas(Canvas)

Return/set the Tk::Canvas associated with this Game

=back

=cut

sub canvas { return shift->{"canvas"}; }
sub set_canvas {
    my ($game, $canvas) = @_;
    $game->{"canvas"} = $canvas;
}


} # end package Games::Cards::Tk::Game

###############################################################################

{
package Games::Cards::Tk::Card;
@Games::Cards::Tk::Card::ISA = qw(Games::Cards::Card);

=head2 Class Games::Cards::Tk::Card

A Card is represented in GC::Tk as two rectangles, the front and back,
which are always moved around together. The card is "turned over" by
raising the front or back rectangle (but the face_up/face_down methods
do that automatically for you).

Lots of methods are basically the same as Games::Cards::Card methods. We
just have to add some GUI changes. But there are also some Tk-specific
methods.

=over 4

=cut

sub face_up {
    my $self = shift;
    $self->SUPER::face_up; # do GC::Card::face_up stuff
    $self->redraw;
}

sub face_down {
    my $self = shift;
    $self->SUPER::face_down; # do GC::Card::face_up stuff
    $self->redraw;
}

=item Tk_truename

This returns a Tk tag that's guaranteed to belong to just one Card. (However,
note this tag will include the card's front and back rectangles.)

Tk_truename_front and Tk_truename_back return tags that will access just
the front or back image.

=cut

# A tag that's guaranteed to return just one card (and its back!)
sub Tk_truename {
    my $self = shift;
    return "card:" . $self->truename;
}
# A tag that's guaranteed to return just one card front
sub Tk_truename_front {
    my $self = shift;
    return "cardfront:" . $self->truename;
}
# A tag that's guaranteed to return just one card back
sub Tk_truename_back {
    my $self = shift;
    return "cardback:" . $self->truename;
}
    
    
=item draw

Draw a card for the first time. Note that this draws the front and back
rectangle. The card is placed at 0,0.

=cut

sub draw {
    my $card = shift;
    my @tags;
    my $cname = $card->Tk_truename;
    push @tags, "card", $cname;

    my $game = &Games::Cards::Game::current_game;
    my $canvas = $game->canvas;
    my $id = $canvas->createImage(
	0,0,
	-anchor => 'nw', 
	-image  => $game->card_image($card),
	-tags => [@tags, "cardfront", $card->Tk_truename_front],
    );

    # now create back of card
    $id = $canvas->createImage(
	0,0,
	-anchor => 'nw', 
	-image  => $game->card_image("back"),
	-tags => [@tags, 'cardback', $card->Tk_truename_back],
    );
} # end sub Games::Cards::Tk::Card::draw
	
=item mark

Mark a card. This is currently done by placing a black rectangle around
it.

=cut

sub mark {
    my $self = shift;
    my $game = &Games::Cards::Game::current_game;
    my $canvas = $game->canvas;
    # Mark front or back of card, whichever's showing. (The front & back
    # are guaranteed to be in the same place. This just makes it easier
    # for clicking & stuff.)
    my $cname = $self->is_face_up ? 
        $self->Tk_truename_front :
        $self->Tk_truename_back; 
    $canvas->addtag("marked", withtag => $cname);

    # Put a rectangle around the marked card
    $canvas->createRectangle($canvas->bbox($cname),
        -outline => "black",
	-width => 3,
	-tags => ["outline"],
    );
    #$canvas->itemconfigure($cname, -fill => '#dddddd');
}

=item unmark

Unmark a card that was marked with the "mark" method.

=cut

sub unmark {
    my $self = shift;
    my $game = &Games::Cards::Game::current_game;
    my $canvas = $game->canvas;
    my $cname = $self->is_face_up ? 
        $self->Tk_truename_front :
        $self->Tk_truename_back; 
    $canvas->dtag($cname, "marked");
    # TODO if we can select > 1 card, this will be wrong
    $canvas->delete("outline");
}

=item place(X, Y)

Put a Card's images at X, Y.

=cut

sub place {
    my ($self, $x, $y) = @_;
    my $game = &Games::Cards::Game::current_game;
    my $canvas = $game->canvas;
    my $cardid = $self->Tk_truename;
    my @fromloc = $canvas->bbox($cardid);
    $canvas->move($cardid, $x-$fromloc[0], $y-$fromloc[1]); 
    $canvas->Subwidget("canvas")->raise($cardid);
}

=item redraw

Redraw (i.e. raise) the card & make sure you're showing front/back correctly.

=back

=cut

sub redraw {
    my $self = shift;
    my $game = &Games::Cards::Game::current_game;
    my $canvas = $game->canvas;
    # We might call this method before even creating a canvas. E.g., it
    # gets called by face_up, which might be called during game init.
    return unless defined $canvas;
    # Should card front or back be on top?
    my ($front, $back) = ($self->Tk_truename_front, $self->Tk_truename_back);
    my @order = $self->is_face_up ? ($front, $back) : ($back, $front);
    $canvas->Subwidget("canvas")->raise(@order);
}

} # end package Games::Cards::Tk::Card

###############################################################################

{
package Games::Cards::Tk::Deck;
@Games::Cards::Tk::Deck::ISA =
    qw (Games::Cards::Tk::Queue Games::Cards::Deck);

=head2 Class Games::Cards::Tk::Deck

This class exists but isn't terribly interesting. The main point is that
by calling this class' new instead of Games::Cards::Deck::new, you
automatically get a deck filled with Games::Cards::Tk::Cards instead of
regular cards.

=cut

# This is terrible coding! However, I need to make ISA have Tk methods first,
# so that we try using Tk methods before others. Yet, we *don't* want to
# use GC::Tk::Queue::new. Nonetheless, there's probably a better way to do it.
sub new {
    Games::Cards::Deck::new(@_);
}
} # end package Games::Cards::Tk::Deck

{
package Games::Cards::Tk::CardSet;
@Games::Cards::Tk::CardSet::ISA = qw(Games::Cards::CardSet);

=head2 Class Games::Cards::Tk::CardSet

This class has extra methods to do Tk stuff to CardSets, i.e. drawing
columns, rows, piles, hands of cards.

There are a few extra fields in the Tk version of the class:

=over 4

=item delta_x 

x distance between right side of one card and the next in the Set. 0 if you
want the cards to totally overlap, some number of pixels smaller than a card
if you want them to overlap some, larger than cardsize if you want them
to not overlap at all.

=item border_x 

A column may be slightly wider/higher than the cards in it, for example.

=back

Also delta_y and border_y. Fields are changed by the "attributes" method.

=over 4

=cut

# Extra fields for Tk CardSets
#
sub new {
    my $a = shift;
    my $class = ref($a) || $a;
    (my $non_Tk = $class) =~ s/Tk::// or die "weird class $class!\n";
    my $self = $non_Tk->new(@_); # Call the non-Tk new sub

    # Now add some Tk attributes
    $self->{"delta_x"} = 0;
    $self->{"delta_y"} = 0;
    $self->{"border_x"} = 0;
    $self->{"border_y"} = 0;

    # Now bless it to the Tk class
    bless $self, $class;
}

=item attributes(HASHREF)

This is a copout way of setting a bunch of CardSet attributes in one shot.
Settable attributes include: delta_x/y and border_x/y. Hashref's keys
are attributes and values are things to set them to.

=cut

sub attributes {
    my $self = shift;
    # Attributes that may be changed by this sub
    my @_changeable = qw (delta_y delta_x border_x border_y);
    my $aref = shift;
    foreach my $att (keys %$aref) {
        if (grep {$att eq $_} @_changeable) {
	    $self->{$att} = $aref->{$att};
	} else {
	    warn "not allowed to change attribute $att";
	}
    }
}

=item redraw

Redraw the Cards in this CardSet. This is the reason you have to set
things like delta_y and border_x.

=cut

# TODO alternatively, just draw *cards* that need to be redrawn?
sub redraw {
    my $self = shift;

    my $game = &Games::Cards::Game::current_game;
    my $canvas = $game->canvas;
    # redraw gets called by give_cards, which may be called during initial
    # setup before you've created the canvas. In that case, obviously
    # you can't redraw, and in fact, it will cause errors to try.
    return unless defined $canvas;

    my $name = $self->name;
    my $delta_y = $self->{"delta_y"};
    my $delta_x = $self->{"delta_x"};
    my $border_y = $self->{"border_y"};
    my $border_x = $self->{"border_x"};
    my ($x, $y) = $canvas->coords("set:$name"); 
    $x += $border_x;
    $y += $border_y;
    foreach my $card (@{$self->cards}) {
	$card->place($x, $y);
	$card->redraw;
	#$card->change_set($canvas, $name); # in case it has moved
	$y += $delta_y;
	$x += $delta_x;
    }
}

# Act just like Games::Cards::CardSet::splice but add Tk stuff
sub splice {
    my ($set, $offset, $length, $in_cards) = @_;
    shift; # shift out $set for SUPER call
    my $out_cards = $set->SUPER::splice(@_);

    # Splice is called twice: for splicing out & in, so we'll end up
    # redrawing the giving & receiving set.
    $set->redraw; 

    return $out_cards;
} # end sub Cards::Games::splice

} # end package Games::Cards::Tk::CardSet

###############################################################################
# Declare Tk subclass for each non-Tk Games::Cards class
{
# Note that non-Tk SUPER comes first, so that SUPER methods will use Tk
# parent classes if they exist
package Games::Cards::Tk::Queue;
@Games::Cards::Tk::Queue::ISA =
    qw (Games::Cards::Tk::Pile Games::Cards::Queue);

package Games::Cards::Tk::Stack;
@Games::Cards::Tk::Stack::ISA =
    qw (Games::Cards::Tk::Pile Games::Cards::Stack);

package Games::Cards::Tk::Pile;
@Games::Cards::Tk::Pile::ISA =
    qw (Games::Cards::Tk::CardSet Games::Cards::Pile);

package Games::Cards::Tk::Hand;
@Games::Cards::Tk::Hand::ISA =
    qw (Games::Cards::Tk::CardSet Games::Cards::Hand);
}

# return true to caller
1;
