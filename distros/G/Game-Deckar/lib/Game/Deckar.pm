# -*- Perl -*-
# a module for managing decks of cards
package Game::Deckar;
our $VERSION = '0.02';
use 5.26.0;
use warnings;
use Object::Pad 0.66;

sub fisher_yates_shuffle {
    my ($deck) = @_;
    my $i;
    for ( $i = @$deck; --$i; ) {
        my $j = int rand( $i + 1 );
        next if $i == $j;
        @$deck[ $i, $j ] = @$deck[ $j, $i ];
    }
}

class Game::Deckar::Card {
    field $data :param :reader;
    field %meta;

    BUILD {
        my (%param) = @_;
        %meta = $param{meta}->%* if exists $param{meta};
    }

    method meta ($name) { $meta{$name} }

    method set_meta ( $name, $value ) {
        my $old = $meta{$name};
        $meta{$name} = $value;
        return sub { $self->set_meta( $name, $old ); };
    }
}

class Game::Deckar {
    use Carp 'croak';
    field %decks;

    BUILD {
        my (%param) = @_;
        if ( exists $param{decks} ) {
            for my $d ( $param{decks}->@* ) {
                $decks{$d} = [];
            }
        }
        if ( exists $param{initial} ) {
            for my $d ( keys $param{initial}->%* ) {
                croak "no such deck $d" unless exists $decks{$d};
                push $decks{$d}->@*, $param{initial}->{$d}->@*;
            }
        }
        if ( exists $param{initial_cards} ) {
            for my $d ( keys $param{initial_cards}->%* ) {
                push $decks{$d}->@*, map {
                    Game::Deckar::Card->new(
                        data => $_,
                        ( exists $param{meta} ? ( meta => $param{meta} ) : () )
                    )
                } $param{initial_cards}->{$d}->@*;
            }
        }
    }

    method add_deck ($name) {
        croak 'deck already exists' if exists $decks{$name};
        $decks{$name} = [];
        return sub { $self->del_deck($name); };
    }

    method del_deck ($name) {
        croak 'no such deck' unless exists $decks{$name};
        croak 'deck is not empty' if $decks{$name}->@*;
        my $orig = $decks{$name};
        delete $decks{$name};
        return sub { $decks{$name} = $orig; };
    }

    method collect ( $name, @rest ) {
        croak 'not enough decks' unless @rest;
        for my $d ( $name, @rest ) {
            croak "no such deck $d" unless exists $decks{$d};
        }
        my @rcards = [ $decks{$name}, [ $decks{$name}->@* ] ];
        for my $d (@rest) {
            next if $d eq $name;    # so can collect on "get_decks"
            push @rcards, [ $decks{$d}, [ $decks{$d}->@* ] ];
            # cards are put onto the "top" of the target deck, which is
            # how some humans might do it with real stacks of cards
            unshift $decks{$name}->@*, splice $decks{$d}->@*;
        }
        return sub {
            for my $r (@rcards) { $r->[0]->@* = $r->[1]->@* }
        };
    }

    method deal ( $src, $dst, $index = 0, $top = 1 ) {
        croak 'no such deck'
          unless exists $decks{$src} and exists $decks{$dst};
        my ( $sref, $dref ) = @decks{ $src, $dst };
        croak 'index out of range' if $index < 0 or $index > $sref->$#*;
        my $card = splice $sref->@*, $index, 1;
        splice $dref->@*, ( $top ? 0 : $dref->@* ), 0, $card;
        return $card, sub {
            splice $sref->@*, $index, 0, splice $dref->@*, ( $top ? 0 : $dref->$#* ), 1;
        };
    }

    method empty ($name) {
        croak 'no such deck'  unless exists $decks{$name};
        croak 'deck is empty' unless $decks{$name}->@*;
        my @orig = $decks{$name}->@*;
        $decks{$name}->@* = ();
        return sub { $decks{$name}->@* = @orig; };
    }

    method get_decks () {
        croak 'no decks' unless %decks;
        return sort keys %decks;
    }

    method get ($name) {
        croak 'no such deck' unless exists $decks{$name};
        return $decks{$name};
    }

    method move ( $src, $dst, $count, $index = 0, $top = 1 ) {
        croak 'no such deck'
          unless exists $decks{$src} and exists $decks{$dst};
        my ( $sref, $dref ) = @decks{ $src, $dst };
        croak 'index out of range' if $index < 0 or $index > $sref->$#*;
        croak 'count out of range' if $count < 1 or $index + $count > @$sref;
        my @cards = splice $sref->@*, $index, $count;
        splice $dref->@*, ( $top ? 0 : $dref->@* ), 0, @cards;
        return \@cards, sub {
            splice $decks{$src}->@*, $index, 0, splice $dref->@*,
              ( $top ? 0 : $dref->@* - $count ), $count;
        };
    }

    method pick ( $src, $dst, $indices, $top = 1 ) {
        croak 'no such deck'
          unless exists $decks{$src} and exists $decks{$dst};
        croak 'no indices' unless $indices->@*;
        my ( $sref, $dref ) = @decks{ $src, $dst };
        croak 'too many indices' if $indices->@* > $sref->@*;
        my ( @icard, %seen );
        for my $index ( $indices->@* ) {
            croak 'index out of range' if $index < 0 or $index > $sref->$#*;
            croak 'duplicate index'    if $seen{$index}++;
            push @icard, [$index];
        }
        for my $r ( sort { $b->[0] <=> $a->[0] } @icard ) {
            $r->[1] = splice $sref->@*, $r->[0], 1;
        }
        my @cards = map { $_->[1] } @icard;
        splice $dref->@*, ( $top ? 0 : $dref->@* ), 0, @cards;
        return \@cards, sub {
            my $len = @icard;
            splice $dref->@*, ( $top ? 0 : -$len ), $len;
            for my $r ( sort { $a->[0] <=> $b->[0] } @icard ) {
                splice $sref->@*, $r->[0], 1, $r->[1];
            }
        };
    }

    method shuffle ($name) {
        croak 'no such deck' unless exists $decks{$name};
        my $deck = $decks{$name};
        croak 'deck is empty' unless $deck->@*;
        my @orig = $deck->@*;
        fisher_yates_shuffle( $decks{$name} );
        return sub { $deck->@* = @orig; };
    }
}

1;
__END__

=head1 Name

Game::Deckar - a module for wrangling decks of cards

=head1 SYNOPSIS

  use Game::Deckar;
  
  # Card object (optional)
  my $card = Game::Deckar::Card->new( data => "Turn Left" );
  
  my $undo = $card->set_meta( hidden => 1 );
  
  say for $card->data, $card->meta('hidden');    # "Turn Left", 1
  
  $undo->() say $card->meta('hidden');           # undef
  
  
  # Deck object
  my $deck = Game::Deckar->new(
      decks   => [qw/new player1 player2 discard/],
      initial => { new => [ "Turn Left", "Stand Up" ] },
  );
  
  $deck->shuffle('new');
  
  ( $card, $undo ) = $deck->deal( new => 'player1' );
  say $card;
  
  $undo->();    # undeal the card
  
  
  # Deck with card object wrapping (all not visible)
  $deck = Game::Deckar->new(
      decks         => [qw/new player1 player2 discard/],
      initial_cards => { new     => [ 'A' .. 'F' ] },
      meta          => { visible => 0 },
  );
  
  ( $card, $undo ) = $deck->deal( new => 'player1' );
  $card->set_meta( visible => 1 );

=head1 DESCRIPTION

Deckar provides for arrays of cards and various supporting methods to
deal with them. An optional card object allows metadata such as card
visibility or whatever to be associated with cards. Means to undo
changes are provided.

The various "decks" represent stacks (or queues) of cards, so a "deck of
cards" might be split into various named decks such as a pile to draw
from, individual decks for each of the player's hands, discard piles,
etc. Naming of these decks is left to the caller. The deck names are
assumed to be strings.

The "top" of a deck is arbitrarily index C<0>, and the bottom the last
element of the array. Therefore interactions with the top involve
C<shift>, C<unshift>, or splicing at index C<0>; interactions with the
bottom use C<push>, C<pop>, or splicing at C<@array> or C<$#array>.

=head1 CLASSES

=head2 Game::Deckar::Card

An optional container object for cards (of whatever content) that also
provides for metadata about a card, such as whether the card is visible,
counters on the card, etc.

=over 4

=item B<data>

Returns the card data.

=item B<new> B<data> => I<card-data>, [ B<meta> => { I<default metadata> } ]

Constructor. Card data must be provided. This could be a number, text
such as "Ace of Spades" or "Repulse the Monkey", or a reference to an
object or data structure. This data is only held onto by this module.

Changes made by the constructor are not available for undo.

=item B<meta> I<key>

Returns the value for the meta I<key> associated with the card.

=item B<set_meta> I<key> I<value>

Sets metadata for a card. Returns an undo code reference.

=back

=head2 Game::Deckar

This class organizes cards into decks and provides methods for moving
and shuffling cards. The caller can either use their own card data or
instead host that data within C<Game::Deckar::Card> objects.

=over 4

=item B<add_deck> I<name>

Adds an empty named deck. Returns an undo code reference.

=item B<collect> I<target> I<source1> [I<source2> ..]

Moves all cards from the source deck(s) onto the top of the target deck.
The target deck can be specified in the source list and will be ignored.
Returns an undo code reference.

=item B<del_deck> I<name>

Deletes a named deck. Decks must be empty to be deleted. Returns an undo
code reference.

=item B<deal> I<source-deck> I<dest-deck> [ I<index> ] [ I<to-top?> ]

Deals from by default the top of the source deck to the destination
deck. I<index> specifies the index used to pick from the source deck,
C<0> or the top by default. The I<to-top?> boolean controls whether the
card goes to the top of the destination (the default) or to the bottom.

Returns the card dealt (so that card metadata can be changed, if need
be) and an undo code reference.

=item B<empty> I<name>

Removes all cards from the named deck. Returns an undo code reference.

=item B<get> I<name>

Returns an array reference to the cards in the deck I<name>. The
contents of the array should not be modified; if you do modify it,
undo code references may do unexpected things, unless you also handle
that yourself.

The count of elements in a deck can be obtained by using the array
reference in scalar context.

  my $hand  = $deck->get('player1');
  my $count = @$hand;

Pains are taken to preserve the array reference through the various
methods, so it should be safe for a caller to hold onto a deck reference
over time.

=item B<get_decks>

Returns a sorted list of the decks present in the object.

=item B<move> I<src> I<dst> I<count> [ I<index> ] [ I<to-top?> ]

Like B<deal> but instead moves I<count> cards from I<src> to I<dst>,
starting from I<index> and going by default to the top of I<dst>.
Returns a reference to the list of cards moved and an undo code
reference.

I<Since version 0.02.>

=item B<new>

Constructor. With I<decks> creates those deck names from the list given.
With I<initial> puts the given card lists into the given deck name. With
I<initial-card> and possibly also I<meta> does the same as I<initial>
but wraps the cards in C<Game::Deckar::Card> objects.

See the L</"SYNOPSIS"> or the C<t/> directory code for examples.

Changes made by the constructor are not available for undo.

=item B<pick> I<src> I<dst> I<indices> [ I<to-top?> ]

Picks a number of cards out of I<src> and places them at either the top
(the default) or the bottom of I<dst>. Returns the cards picked and an
undo code reference. The returned cards will be in the same order as the
I<indices> provided.

  my ( $cards, $undo ) = $deck->pick( hand => 'played', [ 3, 5, 0 ] );
  for my $c (@$cards) { ...

I<Since version 0.02.>

=item B<shuffle> I<name>

Shuffles the deck. Returns an undo code reference.

=back

=head1 FUNCTION

Not exported.

=over 4

=item B<fisher_yates_shuffle>

Used to in-place shuffle decks. Uses Perl's C<rand()> for the
"random" numbers.

=back

=head1 BUGS

It's new code, so various necessary methods are likely missing.

=head1 SEE ALSO

L<Games::Cards> however the documentation claimed that undo was not
available following a desk shuffle, and the module looked biased towards
a conventional deck of cards.

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
