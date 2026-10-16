#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256);

use Game::Sternhalma;
use Game::Sternhalma::Bot;
use Game::Sternhalma::Engine;

# ---- WRITTEN DOWN BEFORE THE RUN ---------------------------------------------
#
#   GAMES     five thousand, the program in every seat. Everything a game does
#             follows from its number, so the run is the same run every time
#             and any one game can be played again on its own.
#
#   SEATS     two, three, four and six, drawn by the game's number; fifteen
#             pieces in one game in ten where the seat count allows it.
#
#   OPENINGS  two searching rungs play one game however often they meet, so
#             each game opens with two to nine moves drawn from the legal
#             ones by the game's number. The run counts how many DIFFERENT
#             games it played and asserts most are.
#
#   RUNGS     each seat's rung is drawn on its own: mostly 0 and 1, rung 2 one
#             seat in five, rung 3 one in fifty, because a move there costs a
#             hundred times one at rung 1.
#
#   ASSERTED  every game ends; after EVERY move each seat has its pieces on
#             the board and no more, and a seat placed stays placed; a game's
#             log replayed is the same game, to the key, the places and how
#             it ended; every board made is destroyed; nothing warns.
#
#   REPORTED  how the games ended, how long they ran at each seat count, how
#             many reached the cap, and how much memory the process held at
#             the end. None of that is asserted.
#
#     STERNHALMA_SOAK=1 prove -b xt/soak.t
#     STERNHALMA_SOAK=1 STERNHALMA_SOAK_GAMES=200 prove -b xt/soak.t

plan skip_all => 'set STERNHALMA_SOAK to run the soak: it plays thousands of games'
    unless $ENV{STERNHALMA_SOAK};

my $GAMES = $ENV{STERNHALMA_SOAK_GAMES} || 5000;
my @SEATS = (2, 3, 4, 6);

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

sub rung_of {
    my ($n) = @_;
    return 3 if $n % 50 == 0;
    return 2 if $n % 5 == 0;
    return $n % 2;
}

# What is wrong with the game after a move, as sentences.
sub unsound {
    my ($g, $placed) = @_;
    my @bad;
    my %count;
    for my $h (0 .. 120) {
        my $seat = $g->at($h);
        next unless defined $seat;
        if ($seat !~ /\A[0-9]\z/ || $seat >= $g->seats) { push @bad, "a '$seat' in hole $h"; next }
        $count{$seat}++;
    }
    for my $seat (0 .. $g->seats - 1) {
        my $n = $count{$seat} // 0;
        push @bad, "seat $seat has $n pieces, not " . $g->pieces if $n != $g->pieces;
    }
    my @places = $g->places;
    for my $seat (0 .. $#places) {
        push @bad, "seat $seat was placed $placed->[$seat] and is now $places[$seat]"
            if $placed->[$seat] && $places[$seat] != $placed->[$seat];
    }
    @$placed = @places;
    return @bad;
}

my (%how, %pairing, %seen, %length, @broken, @unfinished, @differ);
my $moves_seen = 0;
my $boards_at_start = Game::Sternhalma::Engine->live;

for my $i (1 .. $GAMES) {
    my @draw = unpack 'N8', sha256("xt/soak.t game $i");
    my $seats = $SEATS[ $draw[0] % @SEATS ];
    my $pieces = $seats <= 3 && $draw[1] % 10 == 0 ? 15 : 10;
    my @rung = map { rung_of($draw[ 2 + $_ ]) } 0 .. $seats - 1;
    $pairing{"$seats seats, rungs " . join('', sort @rung)}++;
    my $g = Game::Sternhalma->new(seats => $seats, pieces => $pieces);
    my $free = 2 + $draw[7] % 8;
    my @placed = (0) x $seats;

    my $guard = 0;
    until ($g->over) {
        my $move;
        if ($free-- > 0) {
            my @legal = $g->legal;
            $move = $legal[ ($draw[ $free % 8 ] + $g->ply) % @legal ];
        }
        else {
            $move = eval { Game::Sternhalma::Bot->choose($g, rung => $rung[ $g->to_move ], seed => $i) };
            if (!$move) {
                push @broken, "game $i, move " . ($g->ply + 1) . ': ' . ($@ || 'the program had no move');
                last;
            }
        }
        my $flag = $g->play($move);
        if (defined $flag) {
            push @broken, "game $i, move " . ($g->ply + 1) . ": refused, $flag";
            last;
        }
        $moves_seen++;
        push @broken, map { "game $i after move " . $g->ply . ": $_" } unsound($g, \@placed);
        last if ++$guard > 6 * 1000 + 10 || @broken > 50;
    }
    if (!$g->over) {
        push @unfinished, $i;
        next;
    }

    $how{ $g->how }++;
    push @{ $length{$seats} }, $g->ply;
    $seen{ join ' ', $g->moves }++;

    my $again = eval { Game::Sternhalma->replay($g->log) };
    if (!$again) {
        push @differ, "game $i could not be replayed: $@";
        next;
    }
    push @differ, "game $i: " . join(' / ', $g->position, $again->position)
        unless $again->key eq $g->key
            && $again->over
            && $again->how eq $g->how
            && join(',', $again->places) eq join(',', $g->places)
            && $again->ply == $g->ply;
}

my $played = 0;
$played += $_ for values %how;

is(scalar(@unfinished), 0, "all of $GAMES games ended") or diag("did not end: @unfinished[0 .. ($#unfinished > 9 ? 9 : $#unfinished)]");
is($played, $GAMES, 'and each has a result');
is(scalar(@broken), 0, "the board was sound after every one of $moves_seen moves, and none was refused")
    or diag(join "\n", @broken[0 .. ($#broken > 9 ? 9 : $#broken)]);
is(scalar(@differ), 0, 'every game replayed from its log is the same game')
    or diag(join "\n", @differ[0 .. ($#differ > 9 ? 9 : $#differ)]);
is(scalar(@warnings), 0, 'and nothing warned') or diag(join '', @warnings[0 .. ($#warnings > 9 ? 9 : $#warnings)]);
cmp_ok(scalar(keys %seen), '>=', int($GAMES * 0.9), scalar(keys %seen) . " of the $GAMES games were different games");
is(Game::Sternhalma::Engine->live, $boards_at_start, 'every board made has been destroyed');

if ($played) {
    diag('ended by: ' . join(', ', map { "$_ $how{$_}" } sort keys %how));
    for my $seats (sort { $a <=> $b } keys %length) {
        my @l = sort { $a <=> $b } @{ $length{$seats} };
        my $at = sub { $l[ int($_[0] * $#l) ] };
        diag(sprintf('%d seats, %d games: plies median %d, p95 %d, p99.9 %d, max %d',
            $seats, scalar(@l), $at->(0.5), $at->(0.95), $at->(0.999), $l[-1]));
    }
    diag(scalar(keys %pairing) . ' different line-ups of seats and rungs');
    my ($rss) = `ps -o rss= -p $$ 2>/dev/null` =~ /(\d+)/;
    diag("resident memory at the end: $rss KB") if $rss;
}

done_testing();
