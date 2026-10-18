package Game::Senet::Sticks;

use 5.010;
use strict;
use warnings;

use Carp ();
use Digest::SHA ();
use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT_OK = qw(throw_for light_of roll_of roll_for extra_throw);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub throw_for {
    my ($seed, $n) = @_;
    Carp::croak('Game::Senet::Sticks: throw_for wants a seed')
        unless defined $seed && length $seed;
    Carp::croak('Game::Senet::Sticks: a throw number is a non-negative integer')
        unless defined $n && $n =~ /\A\d+\z/;
    my $bytes = "$seed";
    Carp::croak('Game::Senet::Sticks: a seed is bytes, and that one holds a character above 255')
        unless utf8::downgrade($bytes, 1);
    my $byte = unpack 'C', Digest::SHA::sha256($bytes . "throw:$n");
    return [ map { ($byte >> $_) & 1 } 0 .. 3 ];
}

sub light_of {
    my ($sticks) = @_;
    Carp::croak('Game::Senet::Sticks: light_of wants the four sticks')
        unless ref $sticks eq 'ARRAY' && @$sticks == 4;
    my $count = 0;
    $count += $_ for @$sticks;
    return $count;
}

sub roll_of {
    my ($throw) = @_;
    Carp::croak('Game::Senet::Sticks: a throw is a count of light faces, 0 to 4')
        unless defined $throw && $throw =~ /\A[0-4]\z/;
    return $throw == 0 ? 5 : $throw + 0;
}

sub roll_for {
    my ($seed, $n) = @_;
    return roll_of(light_of(throw_for($seed, $n)));
}

sub extra_throw {
    my ($roll) = @_;
    Carp::croak('Game::Senet::Sticks: a roll is a number of houses, 1 to 5')
        unless defined $roll && $roll =~ /\A[1-5]\z/;
    return ($roll == 1 || $roll == 4 || $roll == 5) ? 1 : 0;
}

1;

__END__

=head1 NAME

Game::Senet::Sticks - the four throwing sticks of Senet, as a pure function of a seed

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Senet::Sticks qw(throw_for light_of roll_of roll_for extra_throw);

    my $seed   = 'any bytes at all';
    my $sticks = throw_for($seed, 0);      # [1, 1, 1, 0], the same always
    my $throw  = light_of($sticks);        # 3
    my $roll   = roll_of($throw);          # 3

    my $again  = roll_for($seed, 0);       # 3
    print "throw again\n" if extra_throw($again);

=head1 DESCRIPTION

Senet is played with four flat sticks, each light on one face and dark on the
other, each landing either way with equal chance. This module says how they
fell, for a given seed and a given throw of the game, and what that is worth.

Every function here is pure. The same seed and the same throw number give the
same sticks in every process, on every machine, at any time, whoever asks.
There is no state, and nothing here reads a clock or a random number
generator.

=head2 A throw is not a roll

A B<throw> is the sticks as they fell, counted: how many landed light face up,
0 to 4. A B<roll> is what that is worth in houses, 1 to 5.

For one to four light faces they are the same number. They part company at
none: a throw of 0 is a roll of 5. C<roll_of> is the one place the difference
is decided, and every name in this distribution says which of the two it holds.
A throw of 5 does not exist and neither does a roll of 0, so C<roll_of> croaks
on a 5 and C<extra_throw> on a 0: confusing the two is an error and never a
quiet wrong answer.

    throw   0  1  2  3  4
    roll    5  1  2  3  4
    again   y  y  .  .  y

=head2 Another throw

A roll of 1, 4 or 5 gives the side another throw, whatever is done with it.
C<extra_throw> is asked of the ROLL, as the sources state it.

=head2 The seed is bytes

A seed is a string of bytes and is used as it is given: not decoded, not
trimmed, not turned into hexadecimal. A string holding a character above 255
is not bytes, and is refused. The same bytes stored with the UTF-8 flag on or
off give the same sticks.

=head2 A throw number belongs to the game, not to a player

Throws are numbered from 0 through the whole game, one a ply: a throw that is
played, one that is forfeit, and an extra throw each take the next number.
There is no opening throw, so the first throw of every game is number 0. Which
side a throw belongs to is a fact of the game and not of the sticks, so a game
picked up again at the same number gets the same throw.

=head2 Not the throws of another game

The throws of a seed here have nothing to do with what L<Game::RoyalUr> makes
of the same seed, and are not meant to. Two games sharing a seed do not share
their throws. Changing how a seed becomes sticks would change every game ever
recorded with one, which is why the sticks are pinned by a test.

=head1 FUNCTIONS

None is exported unless asked for. C<:all> exports all five.

=head2 throw_for

    my $sticks = throw_for($seed, $n);

Throw number C<$n> of the game whose seed is C<$seed>, as a reference to an
array of four values, each 1 for a stick that landed light face up and 0 for
one that landed dark. The sticks are returned and not only their count, so that
a caller can draw them.

B<Croaks> without a seed, on a seed that is not bytes, and on a throw number
that is not a whole number from 0 up.

=head2 light_of

    my $throw = light_of($sticks);

How many of the four sticks landed light face up: the throw.

=head2 roll_of

    my $roll = roll_of($throw);

What a throw is worth in houses: the throw itself, except that a throw of 0 is
worth 5. B<Croaks> on anything but 0 to 4.

=head2 roll_for

    my $roll = roll_for($seed, $n);

The three above in one call: the roll that throw C<$n> is worth.

=head2 extra_throw

    my $again = extra_throw($roll);

1 when a roll gives the side another throw: a roll of 1, 4 or 5. 0 for 2 and 3.
B<Croaks> on anything but 1 to 5.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
