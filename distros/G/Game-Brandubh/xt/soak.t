#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256);

use Game::Brandubh;
use Game::Brandubh::Bot;

# ---- WRITTEN DOWN BEFORE THE RUN ---------------------------------------------
#
#   GAMES     five thousand, the program against itself, each seed derived from
#             the game's number, so the run is the same run every time and any
#             one game can be played again on its own.
#
#   LEVELS    each side's level is drawn on its own from the game's number, so
#             two levels meet from both sides. Mostly the bottom level, because
#             a move at the top costs a hundred times as much: about one side
#             in fifty plays at the top and one in five in the middle.
#
#   ASSERTED  every game ends; the board is sound after EVERY move, not only
#             the last one; a game written out and read back is the same game,
#             to the position, the ending and the winner; and nothing warns.
#
#   REPORTED  who won, how the games ended and how long they ran. None of that
#             is asserted: it is the program's opinion of the game.
#
#     BRANDUBH_SOAK=1 prove -b xt/soak.t
#     BRANDUBH_SOAK=1 BRANDUBH_SOAK_GAMES=200 prove -b xt/soak.t

plan skip_all => 'set BRANDUBH_SOAK or RELEASE_TESTING to run the soak: it plays thousands of games'
    unless $ENV{BRANDUBH_SOAK} || $ENV{RELEASE_TESTING};

my $GAMES = $ENV{BRANDUBH_SOAK_GAMES} || 5000;
my @LEVELS = Game::Brandubh::Bot->levels;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

sub level_of {
    my ($n) = @_;
    return $LEVELS[-1] if $n % 50 == 0;
    return $LEVELS[ @LEVELS > 2 ? 1 : 0 ] if $n % 5 == 0;
    return $LEVELS[0];
}

# What is wrong with the board, as sentences. An empty list is a sound board.
sub unsound {
    my ($g) = @_;
    my $pieces = $g->pieces;
    my %count = (attacker => 0, defender => 0, king => 0);
    my @bad;
    for my $square (keys %$pieces) {
        my $piece = $pieces->{$square};
        push @bad, "something that is not a piece on $square" unless exists $count{$piece};
        $count{$piece}++;
        push @bad, "a square called $square" unless $square =~ /\A[a-g][1-7]\z/;
        push @bad, "a $piece on the corner $square"
            if $piece ne 'king' && $square =~ /\A[ag][17]\z/;
        push @bad, "a $piece on the throne" if $piece ne 'king' && $square eq 'd4';
    }
    push @bad, "$count{attacker} attackers" if $count{attacker} > 8;
    push @bad, "$count{defender} defenders" if $count{defender} > 4;
    push @bad, "$count{king} kings" if $count{king} > 1;
    push @bad, 'no king in a game still being played'
        if !$count{king} && $g->status eq 'active';
    return @bad;
}

my (%winner, %how, %pairing, @broken, @unfinished, @differ);
my ($plies, $longest, $moves_seen) = (0, 0, 0);

for my $i (1 .. $GAMES) {
    my $seed = sha256("xt/soak.t game $i");
    my ($att, $def) = map { level_of($_) } unpack 'NN', sha256("xt/soak.t levels $i");
    $pairing{"$att against $def"}++;
    my $g = Game::Brandubh->new(seed => $seed, attackers => ($i % 2 ? 'p2' : 'p1'));

    my $guard = 0;
    while ($g->status eq 'active') {
        my $level = $g->side_to_move eq 'attackers' ? $att : $def;
        my $move = Game::Brandubh::Bot->choose($g, seed => $seed, level => $level);
        my $refused = defined $move ? $g->play($move) : 'no move was offered';
        if ($refused) {
            push @broken, "game $i, move " . ($g->ply + 1) . ': ' . (ref $refused ? $refused->code : $refused);
            last;
        }
        $moves_seen++;
        push @broken, map { "game $i after move " . $g->ply . ": $_" } unsound($g);
        last if ++$guard > 5000;
    }
    if ($g->status ne 'finished') {
        push @unfinished, $i;
        next;
    }

    my $r = $g->result;
    $winner{ $r->winner // 'draw' }++;
    $how{ $r->how }++;
    $plies += $r->ply;
    $longest = $r->ply if $r->ply > $longest;

    my $again = Game::Brandubh->from_text($g->as_text, attackers => $g->attackers, seed => $seed);
    if (!$again) {
        push @differ, "game $i could not be read back";
        next;
    }
    my $s = $again->result;
    push @differ, "game $i: " . join(' / ', $g->position, $again->position)
        unless $again->status eq 'finished'
            && $again->position eq $g->position
            && $again->signature eq $g->signature
            && $s->how eq $r->how
            && ($s->winner // 'draw') eq ($r->winner // 'draw')
            && $s->ply == $r->ply;
}

my $played = 0;
$played += $_ for values %winner;

is(scalar(@unfinished), 0, "all of $GAMES games ended") or diag("did not end: @unfinished[0 .. ($#unfinished > 9 ? 9 : $#unfinished)]");
is($played, $GAMES, 'and each has a result');
is(scalar(@broken), 0, "the board was sound after every one of $moves_seen moves, and none was refused")
    or diag(join "\n", @broken[0 .. ($#broken > 9 ? 9 : $#broken)]);
is(scalar(@differ), 0, 'every game written out and read back is the same game')
    or diag(join "\n", @differ[0 .. ($#differ > 9 ? 9 : $#differ)]);
is(scalar(@warnings), 0, 'and nothing warned') or diag(join '', @warnings[0 .. ($#warnings > 9 ? 9 : $#warnings)]);
cmp_ok(scalar(keys %pairing), '>=', @LEVELS > 1 ? 4 : 1, 'the levels met each other in ' . scalar(keys %pairing) . ' pairings');

if ($played) {
    my ($att_wins, $def_wins) = map { $winner{$_} // 0 } qw(attackers defenders);
    diag(sprintf('attackers %d, defenders %d, drawn %d', $att_wins, $def_wins, $winner{draw} // 0));
    diag('ended by: ' . join(', ', map { "$_ $how{$_}" } sort keys %how));
    diag(sprintf('a mean of %.1f moves a game, the longest %d', $plies / $played, $longest));
    diag('pairings: ' . join(', ', map { "$_ ($pairing{$_})" } sort keys %pairing));
}

done_testing();
