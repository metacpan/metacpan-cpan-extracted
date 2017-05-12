######################################################################
# Games::Blackjack -- 2003, Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings; use strict;

package Games::Blackjack;

our $VERSION = "0.04";

#==========================================
package Games::Blackjack::Shoe;
#==========================================

use Algorithm::GenerateSequence;
use Algorithm::Numerical::Shuffle 
    qw(shuffle);

###########################################
sub new {
###########################################
    my($class, @options) = @_;

    my $self = {nof_decks => 1, @options};

    bless $self, $class;
    $self->reshuffle();
    return $self;
}

###########################################
sub reshuffle {
###########################################
    my($self) = @_;

    my @cards = 
      (Algorithm::GenerateSequence->new(
       [qw( Heart Diamond Spade Club )],
       [qw( A 2 3 4 5 6 7 8 9 10 J Q K )])
       ->as_list()) x $self->{nof_decks};

    $self->{cards} = shuffle \@cards;
}

###########################################
sub remaining {
###########################################
    my($self) = @_;

    return scalar @{$self->{cards}};
}

###########################################
sub draw_card {
###########################################
    my($self) = @_;

    return shift @{$self->{cards}};
}

#==========================================
package Games::Blackjack::Hand;
#==========================================
use Quantum::Superpositions;
use Log::Log4perl qw(:easy);

###########################################
sub new {
###########################################
    my($class, @options) = @_;

    my $self = { cards => [], @options };

    die "No shoe" if !exists $self->{shoe};
    bless $self, $class;
}

###########################################
sub draw {
###########################################
    my($self) = @_;

    push @{$self->{cards}}, 
         $self->{shoe}->draw_card();
}

###########################################
sub count {
###########################################
    my($self, $how) = @_;

    my $counts = any(0);

    for(@{$self->{cards}}) {
        if($_->[1] =~ /\d/) {
            $counts += $_->[1];
        } elsif($_->[1] eq 'A') {
            $counts = any(
                map { eigenstates $_ } $counts+1, $counts+11);
        } else {
            $counts += 10;
        }
    }

    DEBUG "counts(before)=$counts";

       # Delete busted hands
    $counts = ($counts <= 21);
                             
    DEBUG "counts(after)=$counts";

       # Busted!!
    return undef if ! eigenstates($counts);

    return $counts unless defined $how;

    if($how eq "hard") {
            # Return minimum
        return int($counts <= 
               all(eigenstates($counts)));
    } elsif($how eq "soft") {
            # Return maxium
        return int($counts >= 
               all(eigenstates($counts)));
    }
}

###########################################
sub blackjack {
###########################################
    my($self) = @_;

    my $c = $self->count();

    return 0 unless defined $c;

    return 1 if $c == 21 and $c == 11 and 
             @{$self->{cards}} == 2;
    return 0;
}

###########################################
sub as_string {
###########################################
    my($self) = @_;

    return "[" . join(',', map({ "@$_" } 
                @{$self->{cards}})) .  "]";
}

###########################################
sub count_as_string {
###########################################
    my($self) = @_;

    return $self->busted() ?
     "Busted" : $self->blackjack() ?
     "Blackjack" : $self->count("soft");
}

###########################################
sub busted {
###########################################
    my($self) = @_;

    return ! defined $self->count();
}

###########################################
sub score {
###########################################
    my($self, $dealer) = @_;

    return -1 if $self->busted();

    return 1 if $dealer->busted();

    return 0 if $self->blackjack() and
                $dealer->blackjack();

    return 1.5 if $self->blackjack();

    return -1 if $dealer->blackjack();

    return $self->count("soft") <=>
           $dealer->count("soft");
}

1;

__END__

=head1 NAME

Games::Blackjack - Blackjack Utility Classes

=head1 SYNOPSIS

    use Games::Blackjack;

        # Create new shoe of cards
    my $shoe = Games::Blackjack::Shoe->new(nof_decks => 4);

        # Create two hands, player/dealer
    my $player = Games::Blackjack::Hand->new(shoe => $shoe);
    my $dealer = Games::Blackjack::Hand->new(shoe => $shoe);

        # Two dealer cards
    $dealer->draw();
    print "Dealer: ", $dealer->as_string(), "\n";
    $dealer->draw(); # 2nd card not shown

    $player->draw();
    $player->draw();
    print "Player: ", $player->as_string, "(", 
          $player->count_as_string, ")\n";

    # Let's assume player decides to stand. Dealer's turn.

       # Dealer plays Las Vegas rules
    while(!$dealer->busted() and 
          $dealer->count("soft") < 17) {
        $dealer->draw();
    }

       # Show winner (-1: Dealer, 1: Player, 1.5: Player Blackjack)
    print "Player score: ", $player->score($dealer), "\n";

=head1 DESCRIPTION

Games::Blackjack provides the plumbing for implementing Blackjack games.
It was originally published in the German "Linux-Magazin", the article is
available online at

    http://www.linux-magazin.de/Artikel/ausgabe/2003/12/perl/perl.html

The English version appeared in the British "Linux-Magazine" 01/2004 
on the newsstands and will be available online later at

    http://www.linux-magazine.com/issue/38

A sample program, available in the distribution as C<eg/blackjack>, 
shows a simple command line tool allowing a simplified game against 
a Las-Vegas-Style dealer.

The module uses Quantum::Superpositions under the hood for educational
purposes.

=head1 Classes and Methods

=head2 Games::Blackjack::Shoe

Abstracts the "shoe", the container which the dealer extracts the cards from.
A shoe typically holds a number of decks of cards.

=over 4

=item B<< $shoe = Games::Blackjack::Shoe->new(nof_decks => $n) >>

Create a new C<Games::Blackjack::Shoe> object, containing the specified
number of decks.

=item B<< $shoe->remaining() >>

Number of cards still available in the shoe.

=item B<< $shoe->reshuffle() >>

Refill the shoe with a number of decks, as specified in the constructor
call earlier and shuffle them with Fisher-Yates.

=item B<< $card = $shoe->draw_card() >>

Extract a card from the shoe. 
$card is a reference to an array containing the suit of the card
("Heart", "Diamond", "Spade", "Club") as the first element and the
value ("A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K")
as the second.
C<undef> is returned if no more cards are available.
This Method is being called by a Games::Blackjack::Hand object if its
draw() method gets called.

=back

=head2 Games::Blackjack::Hand

Abstracts a player's or the dealer's "hand", a number of cards held by
either party.

=over 4

=item B<< $hand = Games::Blackjack::Hand->new(shoe => $shoe) >>

Create a new C<Games::Blackjack::Hand> object, connected to a "shoe", which
will feed this "hand" via the C<draw()> method.

=item B<< $hand->draw() >>

Draw a card from the shoe and put it into the hand. This will change the count
of the hand. If the shoe runs out of cards, it automatically refills itself.

=item B<< $hand->as_string() >>

Show the cards of a hand as string, e.g. C<Heart A, Spade 10>.

=item B<< $hand->count_as_string() >>

Show the different counts of a hand as a string.

=item B<< $hand->count($how) >>

Count a hand. If C<$how> is set to "soft", the soft count of the hand is
calculated. If C<$how> is set to "hard", the hard count is returned.
If the hand is busted, undef is returned.

=item B<< $hand->busted() >>

Returns true if the hand is busted (hard count exceeds 21), 
and false otherwise.

=item B<< $hand->blackjack() >>

Returns true if the hand is a Blackjack and false otherwise.

=item B<< $player->score($dealer) >>

Returns the score of the player against the dealer hand object, passed in as
$dealer. According to the Blackjack rules, this can be -1, 0, 1 and 1.5
(if the Player has a Blackjack).

=back

=head1 Debugging with Log::Log4perl

C<Games::Blackjack> is C<Log::Log4perl>-enabled. To figure out what goes
on behind the scenes, simple put something like

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

in front of your program. For more detailed Log::Log4perl option,
check out 

    http://log4perl.sourceforge.net

=head1 LEGALESE

Copyright 2003 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2003, Mike Schilli <cpan@perlmeister.com>
