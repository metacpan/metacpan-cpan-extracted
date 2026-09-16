package Game::Backgammon::Dice;

use strict;
use warnings;

use Digest::SHA ();
use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(roll_for opening_for);

sub _faces {
    my ($seed, $n) = @_;
    my @out;
    my $counter = 0;
    while (@out < 2) {
        my $bytes = Digest::SHA::sha256($seed . "roll:$n:$counter");
        for my $byte (unpack 'C*', $bytes) {
            next if $byte >= 252;
            push @out, ($byte % 6) + 1;
            last if @out == 2;
        }
        $counter++;
        die 'Game::Backgammon::Dice: no usable bytes in 256 rounds' if $counter > 256;
    }
    return @out;
}

sub roll_for {
    my ($seed, $n) = @_;
    die 'Game::Backgammon::Dice: roll_for wants a seed' unless defined $seed && length $seed;
    die 'Game::Backgammon::Dice: a roll number is a non-negative integer'
        unless defined $n && $n =~ /\A\d+\z/;
    return _faces($seed, $n);
}

sub dice_for {
    my ($seed, $n) = @_;
    my ($a, $b) = roll_for($seed, $n);
    return $a == $b ? ($a) x 4 : ($a, $b);
}

sub opening_for {
    my ($seed) = @_;
    my $n = 0;
    while ($n < 64) {
        my ($white, $black) = roll_for($seed, $n);
        $n++;
        next if $white == $black;
        return ($white > $black ? 'white' : 'black'), [ $white, $black ], $n;
    }
    die 'Game::Backgammon::Dice: the opening roll tied 64 times, which is not chance';
}

1;

__END__

=head1 NAME

Game::Backgammon::Dice - the rolls, as a pure function of the seed

=head1 SYNOPSIS

    use Game::Backgammon::Dice qw(roll_for opening_for);

    my ($a, $b) = roll_for($seed, 0);          # the same, always
    my @dice    = Game::Backgammon::Dice::dice_for($seed, 3);   # four on doubles
    my ($first, $dice, $used) = opening_for($seed);

=head1 DESCRIPTION

C<roll_for($seed, $n)> is the C<$n>th roll of the game whose seed is
C<$seed>, as two faces. It is a pure function, so the same inputs give the
same roll on every machine and at any time.

=head2 Hashed per roll, not drawn from a stream

Both are reproducible. Only this one is unpredictable to somebody who learns
the seed while the game is still going, which in a game decided by dice is
the difference between a checkable record and a solved game. The same choice
and the same reasoning are in L<P2PGames::Game::Ludo::Dice>.

=head2 The opening roll

C<opening_for> plays the real opening: one die each, higher starts and plays
the pair, ties re-rolled. Each tie consumes a roll number so the log's
numbering stays honest.

=head1 FUNCTIONS

=head2 roll_for($seed, $n)

The C<$n>th roll, as two faces.

=head2 dice_for($seed, $n)

What that roll actually plays: two faces, or four of the same on doubles.

=head2 opening_for($seed)

C<($player, [$d1, $d2], $rolls_used)>: one die each, higher starts, ties
re-rolled.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
