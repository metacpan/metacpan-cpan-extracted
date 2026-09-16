package Game::Gin::Meld;

use strict;
use warnings;

use Exporter 'import';

use Game::Gin::Card qw(rank_of suit_of);

our $VERSION = '0.01';
our @EXPORT_OK = qw(melds_in is_meld is_set is_run MIN_MELD);

use constant MIN_MELD => 3;

sub is_set {
    my ($cards) = @_;
    return 0 unless @$cards >= MIN_MELD && @$cards <= 4;
    my $rank = rank_of($cards->[0]);
    my %suit;
    for my $c (@$cards) {
        return 0 unless rank_of($c) == $rank;
        return 0 if $suit{ suit_of($c) }++;
    }
    return 1;
}

sub is_run {
    my ($cards) = @_;
    return 0 unless @$cards >= MIN_MELD;
    my $suit = suit_of($cards->[0]);
    my @rank;
    for my $c (@$cards) {
        return 0 unless suit_of($c) eq $suit;
        push @rank, rank_of($c);
    }
    @rank = sort { $a <=> $b } @rank;
    for my $i (1 .. $#rank) {
        return 0 unless $rank[$i] == $rank[ $i - 1 ] + 1;
    }
    return 1;
}

sub is_meld { my ($cards) = @_; return is_set($cards) || is_run($cards) ? 1 : 0 }

sub melds_in {
    my ($cards) = @_;
    my @out;

    my %by_rank;
    push @{ $by_rank{ rank_of($_) } }, $_ for @$cards;
    for my $rank (sort { $a <=> $b } keys %by_rank) {
        my @same = sort { $a <=> $b } @{ $by_rank{$rank} };
        next unless @same >= MIN_MELD;
        push @out, [@same];
        if (@same == 4) {
            for my $skip (0 .. 3) {
                push @out, [ map { $same[$_] } grep { $_ != $skip } 0 .. 3 ];
            }
        }
    }

    my %by_suit;
    push @{ $by_suit{ suit_of($_) } }, $_ for @$cards;
    for my $suit (sort keys %by_suit) {
        my @same = sort { rank_of($a) <=> rank_of($b) } @{ $by_suit{$suit} };
        next unless @same >= MIN_MELD;

        my $start = 0;
        for my $i (1 .. @same) {
            my $breaks = $i == @same
                || rank_of($same[$i]) != rank_of($same[ $i - 1 ]) + 1;
            next unless $breaks;
            my @stretch = @same[ $start .. $i - 1 ];
            for my $len (MIN_MELD .. scalar @stretch) {
                for my $at (0 .. @stretch - $len) {
                    push @out, [ @stretch[ $at .. $at + $len - 1 ] ];
                }
            }
            $start = $i;
        }
    }

    return @out;
}

1;

__END__

=head1 NAME

Game::Gin::Meld - the sets and runs that can be made from a hand

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Gin::Meld qw(melds_in is_meld is_set is_run);

    my @candidates = melds_in(\@cards);   # every meld, sub-melds included

    is_set([ $s7, $h7, $d7 ]);            # 1
    is_run([ $s5, $s6, $s7 ]);            # 1
    is_run([ $sq, $sk, $sa ]);            # 0, the ace is low

=head1 DESCRIPTION

A meld is three or more cards: a B<set> of one rank in different suits, or a
B<run> of consecutive ranks in one suit.

=head2 The ace is low and only low

A-2-3 is a run and Q-K-A is not. This module gets that from
L<Game::Gin::Card>, which holds ranks as 1 to 13 with no wraparound, rather
than by testing for it.

=head2 Sub-melds are enumerated on purpose

C<melds_in> returns the four-card set B<and> each of its triples, and a run of
five B<and> every shorter window inside it. Listing only the longest meld of
each kind is the obvious implementation and gives the wrong answer, because a
shorter meld can release a card that is worth more elsewhere. The candidate
lists stay small enough that L<Game::Gin::Deadwood> can search them exactly.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 melds_in

    my @melds = melds_in(\@cards);

Every meld that can be formed, as arrayrefs of card ids, sub-melds included.
Order is not significant.

=head2 is_meld

Whether these cards form a set or a run.

=head2 is_set

Three or four cards of one rank, no suit repeated.

=head2 is_run

Three or more cards of one suit in consecutive ranks. The cards need not be
given in order.

=head2 MIN_MELD

3.

=head1 SEE ALSO

L<Game::Gin::Deadwood>, which chooses between these; L<Game::Gin::Card>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
