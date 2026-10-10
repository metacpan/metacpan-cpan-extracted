package Game::RoyalUr::Dice;

use 5.010;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use Exporter 'import';
use Scalar::Util ();

our $VERSION = '0.01';

our @EXPORT_OK = qw(throw_for marked roll_of roll_for opening_for);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my $field = sub {
    my ($variant, $name) = @_;
    my $value;
    if (Scalar::Util::blessed($variant) && $variant->can($name)) {
        $value = $variant->$name;
    }
    elsif (ref $variant eq 'HASH') {
        $value = $variant->{$name};
    }
    else {
        Carp::croak("Game::RoyalUr::Dice: a rule set is a hash reference or an object with $name");
    }
    Carp::croak("Game::RoyalUr::Dice: the rule set has no $name") unless defined $value;
    return $value;
};

sub throw_for {
    my ($seed, $n, $dice) = @_;
    Carp::croak('Game::RoyalUr::Dice: throw_for wants a seed')
        unless defined $seed && length $seed;
    Carp::croak('Game::RoyalUr::Dice: a throw number is a non-negative integer')
        unless defined $n && $n =~ /\A\d+\z/;
    Carp::croak('Game::RoyalUr::Dice: there are three dice or four')
        unless defined $dice && $dice =~ /\A[34]\z/;
    my $bytes = "$seed";
    Carp::croak('Game::RoyalUr::Dice: a seed is bytes, and that one holds a character above 255')
        unless utf8::downgrade($bytes, 1);
    my $byte = unpack 'C', Digest::SHA::sha256($bytes . "roll:$n");
    return [ map { ($byte >> $_) & 1 } 0 .. $dice - 1 ];
}

sub marked {
    my ($throw) = @_;
    my $count = 0;
    $count += $_ for @$throw;
    return $count;
}

sub roll_of {
    my ($marked, $variant) = @_;
    Carp::croak('Game::RoyalUr::Dice: a count of marked dice is 0 to 4')
        unless defined $marked && $marked =~ /\A[0-4]\z/;
    my $zero = $field->($variant, 'zero_rolls');
    Carp::croak('Game::RoyalUr::Dice: zero_rolls is 0 or 4')
        unless $zero =~ /\A[04]\z/;
    return $marked == 0 ? $zero + 0 : $marked + 0;
}

sub roll_for {
    my ($seed, $n, $variant) = @_;
    my $throw = throw_for($seed, $n, $field->($variant, 'dice'));
    return roll_of(marked($throw), $variant);
}

sub opening_for {
    my ($seed, $dice) = @_;
    my ($n, @throws) = (0);
    while ($n < 128) {
        my $light = throw_for($seed, $n++, $dice);
        my $dark  = throw_for($seed, $n++, $dice);
        push @throws, $light, $dark;
        my ($l, $d) = (marked($light), marked($dark));
        next if $l == $d;
        return (($l > $d ? 'light' : 'dark'), $n, \@throws);
    }
    Carp::croak('Game::RoyalUr::Dice: the opening throw tied 64 times, which is not chance');
}

1;

__END__

=head1 NAME

Game::RoyalUr::Dice - the dice of the Royal Game of Ur, as a pure function of a seed

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::RoyalUr::Dice qw(throw_for marked roll_of roll_for opening_for);

    my $throw = throw_for($seed, 0, 4);        # [1, 0, 1, 1], the same always
    my $count = marked($throw);                # 3
    my $roll  = roll_of($count, { zero_rolls => 0 });

    my $again = roll_for($seed, 0, { dice => 4, zero_rolls => 0 });

    my ($first, $used, $throws) = opening_for($seed, 4);

=head1 DESCRIPTION

The game is played with three or four dice, each of which lands marked or
unmarked with equal chance. This module says how they fell, for a given seed
and a given throw of the game, and what that is worth.

Every function here is pure. The same seed and the same throw number give the
same dice in every process, on every machine, at any time, whoever asks. There
is no state, and nothing here reads a clock or a random number generator.

=head2 A throw is not a roll

A B<throw> is the dice as they fell: which are marked. A B<roll> is what that
is worth in steps on the board.

Usually they are the same number, the count of marked dice. They part company
in the rule set where a throw with nothing marked is worth four steps and not
none. C<roll_of> is the one place the difference is decided, and every name in
this distribution says which of the two it holds.

=head2 The seed is bytes

A seed is a string of bytes and is used as it is given: not decoded, not
trimmed, not turned into hexadecimal. A string holding a character above 255
is not bytes, and is refused.

=head2 A throw number belongs to the game, not to a player

Throws are numbered from 0 through the whole game: an opening throw, a throw
that could not be played, an extra throw earned on a rosette each take the
next number. Which side a throw belongs to is a fact of the game and not of
the dice, so a game picked up again at the same number gets the same throw.

=head2 Not the rolls of another game

The throws of a seed here have nothing to do with what L<Game::Backgammon>
makes of the same seed. Two games sharing a seed do not share their dice.

=head1 A RULE SET

C<roll_of> and C<roll_for> take a rule set: a hash reference, or any object,
that answers C<zero_rolls> (0 or 4: what a throw with nothing marked is worth)
and, for C<roll_for>, C<dice> (3 or 4).

=head1 FUNCTIONS

None is exported unless asked for. C<:all> exports all five.

=head2 throw_for

    my $throw = throw_for($seed, $n, $dice);

Throw number C<$n> of the game whose seed is C<$seed>, as a reference to an
array of C<$dice> values, each 1 for a marked die and 0 for an unmarked one.
The faces are returned and not only their sum, so that a caller can draw them.

B<Croaks> without a seed, on a throw number that is not a whole number from 0
up, and on a number of dice that is not 3 or 4.

=head2 marked

    my $count = marked($throw);

How many dice of a throw are marked.

=head2 roll_of

    my $roll = roll_of($count, $rules);

What a count of marked dice is worth in steps: the count itself, except that a
count of 0 is worth the rule set's C<zero_rolls>.

=head2 roll_for

    my $roll = roll_for($seed, $n, $rules);

The three above in one call: the roll that throw C<$n> is worth under a rule
set.

=head2 opening_for

    my ($first, $used, $throws) = opening_for($seed, $dice);

The throw that decides who moves first. Light throws, then dark, and the side
with more dice marked is C<$first>, C<'light'> or C<'dark'>. On a tie both
throw again.

C<$used> is how many throws that took, always an even number, so that the
game's own throws carry on from there. C<$throws> is every throw made, in
order.

B<The count of marked dice is compared, and not what the throw would be worth
as a move.> In the rule set where nothing marked is worth four steps, nothing
marked still loses the opening to one.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
