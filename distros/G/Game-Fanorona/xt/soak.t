#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256);

use Game::Fanorona;
use Game::Fanorona::Bot;
use Game::Fanorona::Engine;
use Game::Fanorona::Rules;

# ---- WRITTEN DOWN BEFORE THE RUN ---------------------------------------------
#
#   GAMES     five thousand, the program against itself. Everything a game
#             does follows from its number, so the run is the same run every
#             time and any one game can be played again on its own.
#
#   OPENINGS  THE PROGRAM HAS NO CHANCE IN IT: two levels that both search
#             play one game however often they meet. So each game opens with
#             two to nine steps drawn from the steps the rules allow, by the
#             game's number, and only then do the two sides play. The run
#             counts how many DIFFERENT games it played and asserts most are.
#
#   LEVELS    each side's level is drawn on its own. Mostly the bottom two,
#             because a move at the top costs a hundred times as much: about
#             one side in fifty plays at 10,000 positions and one in five at
#             1,000. The top level, 30,000, is not in the soak.
#
#   ASSERTED  every game ends; the board is sound after EVERY step, not only
#             the last move; a game written out and read back is the same
#             game, to the position, the ending and the winner; every game
#             made is destroyed; and nothing warns.
#
#   REPORTED  who won, how the games ended, how long they ran and how much
#             memory the process held at the end. None of that is asserted.
#
#     FANORONA_SOAK=1 prove -b xt/soak.t
#     FANORONA_SOAK=1 FANORONA_SOAK_GAMES=200 prove -b xt/soak.t

plan skip_all => 'set FANORONA_SOAK to run the soak: it plays thousands of games'
    unless $ENV{FANORONA_SOAK};

my $GAMES = $ENV{FANORONA_SOAK_GAMES} || 5000;
my @LEVELS = Game::Fanorona::Bot->levels;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

sub level_of {
    my ($n) = @_;
    return $LEVELS[3] if $n % 50 == 0;
    return $LEVELS[2] if $n % 5 == 0;
    return $LEVELS[ $n % 2 ];
}

# What is wrong with the board, as sentences. An empty list is a sound board.
# $before is the count of each side before the step, $mover the side that
# made it.
sub unsound {
    my ($g, $before, $mover) = @_;
    my @bad;
    my ($board) = split / /, $g->position;
    push @bad, 'a position that is not five ranks: ' . $g->position unless ($board =~ tr{/}{}) == 4;
    my %seen = (white => 0, black => 0);
    for my $rank (1 .. 5) {
        for my $file ('a' .. 'i') {
            my $what = $g->at("$file$rank");
            next unless defined $what;
            if (!exists $seen{$what}) { push @bad, "a '$what' on $file$rank"; next }
            $seen{$what}++;
        }
    }
    for my $side (qw(white black)) {
        push @bad, "$side counted as " . $g->stones($side) . " and seen as $seen{$side}" unless $g->stones($side) == $seen{$side};
        push @bad, "$seen{$side} $side stones" if $seen{$side} > 22;
    }
    push @bad, "$mover lost a stone by its own step" if $seen{$mover} != $before->{$mover};
    my $rival = $mover eq 'white' ? 'black' : 'white';
    push @bad, "$rival gained a stone" if $seen{$rival} > $before->{$rival};
    return @bad;
}

my (%winner, %how, %pairing, %game_seen, @broken, @unfinished, @differ);
my ($plies, $longest, $steps_seen) = (0, 0, 0);
my ($games_at_start, $boards_at_start) = (Game::Fanorona::Rules->live, Game::Fanorona::Engine->live);

for my $i (1 .. $GAMES) {
    my $seed = sha256("xt/soak.t game $i");
    my ($white, $black, $opening, @draw) = unpack 'N12', sha256("xt/soak.t levels $i") . sha256("xt/soak.t opening $i");
    my %level = (white => level_of($white), black => level_of($black));
    $pairing{"$level{white} against $level{black}"}++;
    my $g = Game::Fanorona->new;
    my $free = 2 + $opening % 8;

    my $guard = 0;
    until ($g->over) {
        my $mover = $g->turn;
        my %before = map { $_ => $g->stones($_) } qw(white black);
        my @made;
        if ($free > 0) {
            my @steps = $g->steps;
            my $pick = $steps[ $draw[ $free % @draw ] % @steps ];
            $free--;
            if ($g->step($pick->{string})) {
                @made = ($pick->{string});
                $g->stop if !$g->over && $g->in_chain;
            }
            else {
                push @broken, "game $i: the offered step $pick->{string} was refused: " . $g->error->code;
            }
        }
        else {
            my $thought = eval { Game::Fanorona::Bot->play($g, seed => $seed, level => $level{$mover}) };
            if (!$thought) {
                push @broken, "game $i, move " . ($g->ply + 1) . ': ' . ($@ || 'the program had no move');
                last;
            }
            @made = map { $_->{string} } @{ $thought->{steps} };
        }
        last unless @made;
        $steps_seen += @made;
        push @broken, map { "game $i after move " . $g->ply . ": $_" } unsound($g, \%before, $mover);
        push @broken, "game $i: a move was left open" if !$g->over && $g->in_chain;
        last if ++$guard > 3100 || @broken > 50;
    }
    if (!$g->over) {
        push @unfinished, $i;
        next;
    }

    my $r = $g->result;
    $winner{ $r->winner // 'draw' }++;
    $how{ $r->how }++;
    $plies += $g->ply;
    $longest = $g->ply if $g->ply > $longest;
    $game_seen{ join ' ', $g->moves }++;

    my ($again, $why, $line) = Game::Fanorona->from_text($g->as_text);
    if (!$again) {
        push @differ, "game $i could not be read back: $why, line " . ($line // '?');
        next;
    }
    my $s = $again->result;
    push @differ, "game $i: " . join(' / ', $g->position, $again->position)
        unless $s
            && $again->position eq $g->position
            && $again->signature eq $g->signature
            && $s->how eq $r->how
            && ($s->winner // 'draw') eq ($r->winner // 'draw')
            && $again->ply == $g->ply
            && join(' ', $again->moves) eq join(' ', $g->moves);
}

my $played = 0;
$played += $_ for values %winner;

is(scalar(@unfinished), 0, "all of $GAMES games ended") or diag("did not end: @unfinished[0 .. ($#unfinished > 9 ? 9 : $#unfinished)]");
is($played, $GAMES, 'and each has a result');
is(scalar(@broken), 0, "the board was sound after every one of $steps_seen steps, and none was refused")
    or diag(join "\n", @broken[0 .. ($#broken > 9 ? 9 : $#broken)]);
is(scalar(@differ), 0, 'every game written out and read back is the same game')
    or diag(join "\n", @differ[0 .. ($#differ > 9 ? 9 : $#differ)]);
is(scalar(@warnings), 0, 'and nothing warned') or diag(join '', @warnings[0 .. ($#warnings > 9 ? 9 : $#warnings)]);
cmp_ok(scalar(keys %pairing), '>=', $GAMES >= 1000 ? 12 : 4, 'the levels met each other in ' . scalar(keys %pairing) . ' pairings');
cmp_ok(scalar(keys %game_seen), '>=', int($GAMES * 0.9), scalar(keys %game_seen) . " of the $GAMES games were different games");
is(Game::Fanorona::Rules->live, $games_at_start, 'every game made has been destroyed');
is(Game::Fanorona::Engine->live, $boards_at_start, 'and every board');

if ($played) {
    diag(sprintf('white %d, black %d, drawn %d', map { $winner{$_} // 0 } qw(white black draw)));
    diag('ended by: ' . join(', ', map { "$_ $how{$_}" } sort keys %how));
    diag(sprintf('a mean of %.1f moves a game, the longest %d', $plies / $played, $longest));
    diag('pairings: ' . join(', ', map { "$_ ($pairing{$_})" } sort keys %pairing));
    my ($rss) = `ps -o rss= -p $$ 2>/dev/null` =~ /(\d+)/;
    diag("resident memory at the end: $rss KB") if $rss;
}

done_testing();
