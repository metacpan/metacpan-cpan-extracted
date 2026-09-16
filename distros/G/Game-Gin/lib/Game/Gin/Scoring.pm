package Game::Gin::Scoring;

use strict;
use warnings;

use Exporter 'import';

use Game::Gin::Card qw(deadwood_of);
use Game::Gin::Meld qw(is_meld);
use Game::Gin::Deadwood qw(best);

our $VERSION = '0.01';
our @EXPORT_OK = qw(best_layoff settle match_result
                    GIN_BONUS UNDERCUT_BONUS BIG_GIN_BONUS
                    TARGET BOX_BONUS GAME_BONUS);

use constant GIN_BONUS      => 25;
use constant UNDERCUT_BONUS => 25;
use constant BIG_GIN_BONUS  => 31;

use constant TARGET     => 100;
use constant BOX_BONUS  => 25;
use constant GAME_BONUS => 100;

sub best_layoff {
    my ($unmatched, $melds) = @_;
    $unmatched ||= [];
    $melds     ||= [];

    my $total = 0;
    $total += deadwood_of($_) for @$unmatched;
    return { laid => [], melds => [ map { [@$_] } @$melds ], deadwood => $total }
        unless @$unmatched && @$melds;

    my (@best_laid, $best_value, @best_melds);
    $best_value = 0;
    @best_melds = map { [@$_] } @$melds;

    my $walk;
    $walk = sub {
        my ($i, $piles, $laid, $value) = @_;
        if ($value > $best_value) {
            $best_value = $value;
            @best_laid  = @$laid;
            @best_melds = map { [@$_] } @$piles;
        }
        return if $i > $#$unmatched;

        my $card = $unmatched->[$i];

        $walk->($i + 1, $piles, $laid, $value);

        for my $m (0 .. $#$piles) {
            my @grown = (@{ $piles->[$m] }, $card);
            next unless is_meld(\@grown);
            my @next = map { [@$_] } @$piles;
            $next[$m] = \@grown;
            $walk->($i + 1, \@next, [ @$laid, $card ], $value + deadwood_of($card));
        }
        return;
    };
    $walk->(0, [ map { [@$_] } @$melds ], [], 0);

    return {
        laid     => \@best_laid,
        melds    => \@best_melds,
        deadwood => $total - $best_value,
    };
}

sub settle {
    my (%o) = @_;
    my ($knocker, $defender) = @o{qw(knocker defender)};
    my $k_dead = $o{knocker_deadwood} // 0;

    my $d_best = best($o{defender_cards} || []);
    my $d_dead = $d_best->{deadwood};
    my @laid;

    unless ($o{gin}) {
        my $lay = best_layoff($d_best->{unmatched}, $o{knocker_melds} || []);
        $d_dead = $lay->{deadwood};
        @laid   = @{ $lay->{laid} };
    }

    if ($o{big_gin}) {
        return { winner => $knocker, loser => $defender, kind => 'big_gin',
                 points => BIG_GIN_BONUS + $d_dead,
                 knocker_deadwood => 0, defender_deadwood => $d_dead, laid_off => [] };
    }
    if ($o{gin}) {
        return { winner => $knocker, loser => $defender, kind => 'gin',
                 points => GIN_BONUS + $d_dead,
                 knocker_deadwood => 0, defender_deadwood => $d_dead, laid_off => [] };
    }

    if ($d_dead <= $k_dead) {
        return { winner => $defender, loser => $knocker, kind => 'undercut',
                 points => UNDERCUT_BONUS + ($k_dead - $d_dead),
                 knocker_deadwood => $k_dead, defender_deadwood => $d_dead,
                 laid_off => \@laid };
    }

    return { winner => $knocker, loser => $defender, kind => 'knock',
             points => $d_dead - $k_dead,
             knocker_deadwood => $k_dead, defender_deadwood => $d_dead,
             laid_off => \@laid };
}

sub match_result {
    my (%o) = @_;
    my @hands  = @{ $o{hands} || [] };
    my $target = $o{target} // TARGET;

    my (%points, %won, $winner);
    for my $h (@hands) {
        my $seat = $h->{winner} or next;
        $points{$seat} += $h->{points};
        $won{$seat}++;
        $winner = $seat if !$winner && $points{$seat} >= $target;
    }

    my @seats = sort keys %{ { map { $_ => 1 } (keys %points, keys %won, 'p1', 'p2') } };
    my $loser = $winner ? ($winner eq 'p1' ? 'p2' : 'p1') : undef;

    my $shutout = ($winner && !($won{$loser} || 0)) ? 1 : 0;

    my %totals;
    for my $seat (@seats) {
        my $p = $points{$seat} || 0;
        $p *= 2 if $shutout;
        $totals{$seat} = $p + BOX_BONUS * ($won{$seat} || 0);
    }
    $totals{$winner} += GAME_BONUS if $winner;

    return {
        winner      => $winner,
        loser       => $loser,
        hand_points => { map { $_ => ($points{$_} || 0) } @seats },
        hands_won   => { map { $_ => ($won{$_}    || 0) } @seats },
        shutout     => $shutout,
        totals      => \%totals,
        target      => $target,
    };
}

1;

__END__

=head1 NAME

Game::Gin::Scoring - lay-offs, and what a hand was worth

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Gin::Scoring qw(best_layoff settle);

    my $lay = best_layoff($unmatched, $knocker_melds);
    $lay->{laid};       # the cards laid off
    $lay->{deadwood};   # what the defender is left with

    my $r = settle(
        knocker          => 'p1',
        defender         => 'p2',
        knocker_deadwood => 4,
        knocker_melds    => $melds,
        defender_cards   => $cards,
    );
    $r->{winner};  $r->{points};  $r->{kind};   # knock, gin, big_gin, undercut

=head1 DESCRIPTION

=head2 The numbers, and which ruleset they are from

Gin 25, undercut 25, big gin 31: the modern set, as Wikipedia states it. The
older published set, which Pagat gives and Wikipedia calls the early official
rules, is gin 20 and undercut 10. Mixing the two would give scoring that no
publication describes and no vector to test against.

=head2 Lay-offs are computed, not offered

Laying off only ever reduces the defender's deadwood, so declining is never
right and it is not a decision worth a turn. It is searched rather than taken
greedily, because a card can extend two melds and the choice matters.

=head2 An undercut includes equal counts

A knock that merely ties the defender scores the defender, not the knocker.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 best_layoff

    my $lay = best_layoff(\@unmatched, \@melds);

The lay-off that leaves the defender with the least deadwood. Returns C<laid>,
the grown C<melds>, and the resulting C<deadwood>.

=head2 settle

Who won a hand and by how much, given the knocker, the defender's cards and
whether it was gin. Lay-offs are applied unless it was gin.

=head2 match_result

    my $m = match_result(hands => \@hand_results, target => 100);

What a whole match came to, given the results of its hands in order. Returns
C<winner>, C<loser>, C<hand_points>, C<hands_won>, C<shutout>, C<totals> and
the C<target>.

B<The winner is the player who reached the target>, and the bonuses decide the
margin rather than the winner. The totals can invert: a player who wins eight
small hands collects eight box bonuses and may finish with the higher number
without having won the game.

A shutout doubles each player's hand points B<before> the box bonuses are
added, which is the order the source gives. Doubling afterwards would pay the
boxes twice.

A cancelled hand was won by nobody, so it pays no box bonus and does not break
a shutout.

=head2 GIN_BONUS, UNDERCUT_BONUS, BIG_GIN_BONUS

25, 25 and 31.

=head2 TARGET, BOX_BONUS, GAME_BONUS

100, 25 and 100: the score a match runs to, what each hand won is worth at the
end, and what winning the match is worth.

=head1 SEE ALSO

L<Game::Gin::Deadwood>, L<Game::Gin::Meld>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
