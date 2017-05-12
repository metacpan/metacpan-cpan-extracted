package Games::Poker::TexasHold'em;
use strict;
our $VERSION = '1.4';
use Carp;

my @stages = qw( preflop flop turn river showdown);

=head1 NAME

Games::Poker::TexasHold'em - Abstract state in a Hold'em game

=head1 SYNOPSIS

  use Games::Poker::TexasHold'em;
  my $game = Games::Poker::TexasHold'em->new(
        players => [
            { name => "lathos", bankroll => 500 },
            { name => "MarcBeth", bankroll => 500 },
            { name => "Hectate", bankroll => 500 },
            { name => "RichardIII", bankroll => 500 },
        ],
        button => "Hectate",
        bet => 10,
        limit => 50
  );
  $game->blinds; # Puts in both small and large blinds
  print $game->pot; # 15

  $game->call; # Hecate puts in 10
  $game->bet_raise(15) # RichardIII sees the 10, raises another 5
  ...

=head1 DESCRIPTION

This represents a game of Texas Hold'em poker. It maintains the state of
the pot, who's in to what amount, who's folded, what the bankrolls look
like, and so on. It's meant to be used in conjunction with
L<Games::Poker::OPP>, but can be used stand-alone as well for analysis.

=head1 METHODS

=head2 new

Starts a new game. 

=cut

sub new {
    my ($self, %args) = @_;
    my @players = @{$args{players}};
    $args{seats} = { map { $players[$_]->{name} => $_ } 0..$#players };
    $args{button} = $args{next} = $args{seats}->{$args{button}};
    for (@players) { $_->{in} = $_->{in_this_round} = 0 }
    $args{unfolded} = @players;
    $args{board} = [];
    $args{hole} = [];
    $args{stage} = 0;
    bless \%args, $self;
}

=head2 General information about the game

=head3 seat2name

Returns the name of the player at the specified seat. Seats are numbered
from zero.

=cut

sub seat2name {
    my ($self, $seat) = @_;
    $self->{players}->[$seat]->{name};
}

=head3 players

Returns the names of all players in the game.

=cut

sub players {
    my $self = shift;
    map { $self->seat2name($_) } 0...$#{$self->{players}};
}

=head3 bet

Returns the initial bet.

=head2 limit

Returns the raise limit or 0 for unlimited.

=cut

sub bet { $_[0]->{bet} }
sub limit { $_[0]->{limit} || 0 }


=head2 Information about the current state of play

=head3 next_to_play

Returns the name of the player who's next to act in the game.

=cut

sub next_to_play { 
    my $self = shift;
    return $self->seat2name($self->{next});
}

=head3 stage

Returns the stage of play. (preflop, flop, turn, river, showdown)

=cut

sub stage {
    my $self = shift;
    return $stages[$self->{stage}];
}

=head3 bankroll

Returns the bankroll of a given player.

=cut

sub bankroll {
    my ($self, $player) = @_;
    $player = $self->_rationalise_player($player);
    $self->{players}->[$player]->{bankroll};
}

=head3 in

Returns the investment in the pot of a given player.

=cut

sub in {
    my ($self, $player) = @_;
    $player = $self->_rationalise_player($player);
    $self->{players}->[$player]->{in}
}

=head2 folded

Returns whether or not the given player has folded. Players may be
specified by name or seat number.

=cut

sub folded {
    my $self = shift;
    my $player = shift;
    $player = $self->_rationalise_player($player);
    return $self->{players}->[$player]->{folded};
}

sub _rationalise_player {
    my ($self, $player) = @_;
    return $player if $player =~ /^-?\d+$/ and $self->{players}->[$player];
    my $seat = $self->{seats}{$player};
    return $seat if defined $seat;
    croak "Couldn't find player $player";
}

sub _advance { 
    my $self = shift;
    do { 
        return if $self->{unfolded} < 2; # Shouldn't be here anyway.
        $self->{next}++; 
        $self->{next} = 0 if $self->{next} > $#{$self->{players}};
    } until ! $self->folded($self->{next});
} 

=head3 pot

Returns the current amount of cash in the pot

=cut

sub pot {
    # The total of each player's interest in the game.
    my $self = shift;
    my $pot = 0;
    for (@{$self->{players}}) { $pot += $_->{in} };
    return $pot;
}

=head3 pot_square

Returns whether or not the pot is square and the current stage should be
ended.

=cut

sub pot_square {
    # Everyone (who is still in) is in to the tune of the current bet.
    my $self = shift;
    for (@{$self->{players}}) { 
        next if $_->{folded};
        return 0 if $_->{in_this_round} != $self->{current_bet} 
    }
    return 1;
}

=head3 board

Returns the current board, if you're using one; this is the set of
things which have been passed in to L</next_stage>.

=cut

sub board {
    return @{$_[0]->{board}};
}

=head3 hole

Similar to C<board>, this is an opaque area where you can store your
hole cards in whatever format you want to, if you want to.

=cut

sub hole {
    my $self = shift;
    if (@_) { $self->{hole} = [@_] }
    @{$self->{hole}}
}

=head3 status

Returns a nice table summarizing what's going on in the game.

=cut

sub status {
    my $self = shift;
    my @players = @{$self->{players}};
    my $output = "Pot: ".$self->pot." Stage: ".$self->stage."\n";
    $output .= "? ". sprintf("%20s %6s %6s", qw[Name Bankroll InPot])."\n";
    for (0..$#players) {
        my $p = $players[$_];
        my $status;
        if ($p->{folded}) { $status = "F" }
        elsif ($self->{next} != $_) { $status = " " }
        elsif ($self->pot_square) { $status="." }
        else { $status = "*" }
        $output .= "$status ";
        $output .= sprintf("%20s \$% 5d \$% 5d", $p->{name}, $p->{bankroll}, $p->{in});
        $output .="\n";
    }
    return $output;
}

=head2 Actions

These actions all apply to he current person who is next to act. No
playing out of turn! After an action, play is advanced to the next
player except in the case of C<blinds>.

=head3 blinds

Puts in both small and large blinds. Play is not advanced, because
blinds are taken from the left of the button. It's all so confusing.

=cut

sub blinds {
    my $self = shift;
    my $big = $self->{bet};
    my $small = $big / 2;
    $self->{current_bet} = $big;
    # Play *is* advanced, but it goes backwards two first
    $self->{next}-=2;
    $self->_put_in($small);
    $self->_advance;
    $self->_put_in($big);
    $self->_advance;
}

sub _put_in {
    my ($self, $amount) = @_;
    my $who = $self->{players}->[$self->{next}];
    $who->{bankroll} -= $amount;
    $who->{in} += $amount;
    $who->{in_this_round} += $amount;
}

=head3 fold

Folds, taking the player out of the game.

=cut

sub fold {
    my $self = shift;
    $self->{players}->[$self->{next}]->{folded}++;
    $self->{unfolded}--;
    $self->_advance;
}

=head3 check_call

Either checks, putting nothing in the pot, or calls, putting in however
much the current player is short. Returns the amount put into the pot.

You can call the C<check> or C<call> methods if you feel happier with
that, but they're identical.

=cut

sub check_call {
    my $self = shift;
    my $player = $self->{players}->[$self->{next}];
    my $short = $self->{current_bet} - $player->{in_this_round};
    $self->_put_in($short);
    $self->_advance;
    return $short;
}

*check = *check_call;
*call = *check_call;

=head3 bet_raise ($amount)

Bets, if there's currently no bet, or raises an amount up, up to the
limit if there is one. The amount must include the call; that is, if
you're short 10, you call

    $self->bet_raise(20);

to see the 10 and raise another 10. (You'll get an error if it's less
than you're short.) If you don't say how much to raise, it'll be raised
by the intial bet.

As with C<check> and C<call>, you can call this either as C<bet> or
C<raise> if you prefer.

=cut

sub bet_raise {
    my ($self, $amount) = @_;
    if (!$amount or $amount < $self->{bet}) { $amount = $self->{bet} };
    my $player = $self->{players}->[$self->{next}];
    my $short = $self->{current_bet} - $player->{in_this_round};
    if ($self->{limit} and $amount > $self->{limit}) { 
        $amount = $self->{limit} 
    }
    if ($amount < $short) { croak "You need to raise more than the call!" }
    $self->{current_bet} += $amount-$short;
    $self->_put_in($amount);
    $self->_advance;
    return $amount;
}

*bet = *bet_raise;
*raise = *bet_raise;

=head2 "Control" actions

These are actions taken by the server or "dealer" rather than an
individidual player.

=head3 next_stage (@cards)

Checks that the pot is square, and if so, advances to the next stage.
Returns 1 if an advance was made, otherwise 0. The optional "cards"
argument is treated as an opaque array which is added to the current
board.

=cut

sub next_stage {
    my $self = shift;
    return 0 unless $self->pot_square;
    $self->{current_bet} = 0;
    for (@{$self->{players}}) { $_->{in_this_round} = 0 }
    $self->{stage}++;
    my @cards = @_ unless $self->stage eq "showdown"; # No more cards now!
    push @{$self->{board}}, @cards;
    return 1;
}

=head1 AUTHOR

Simon Cozens, E<lt>simon@kasei.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
