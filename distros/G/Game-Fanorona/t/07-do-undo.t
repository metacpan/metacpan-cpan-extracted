use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use FnT qw(sq name text texts board roller);
my $E = 'Game::Fanorona::Engine';

subtest 'a step is made and unmade' => sub {
    my $bd = $E->new;
    my $before = $bd->to_string;
    my $key = $bd->key_hex;
    my ($step) = grep { text($_) eq 'e2-e3Axe4,e5' } $bd->steps;

    my ($token, $removed) = $bd->do_step($step);
    ok(defined $token, 'do_step hands back a token');
    is($removed, 2, 'and says two stones went');
    is($bd->at(sq('e2')), EMPTY, 'the stone left e2');
    is($bd->at(sq('e3')), WHITE, 'and stands on e3');
    is($bd->at(sq('e4')), EMPTY, 'e4 is gone');
    is($bd->at(sq('e5')), EMPTY, 'e5 is gone');
    is($bd->count(BLACK), 20, 'twenty black stones');
    is($bd->count(WHITE), 22, 'twenty-two white ones');
    is($bd->side, BLACK, 'the turn passed');
    is($bd->to_string, 'bbbb1bbbb/bbbb1bbbb/bwbwwbwbw/wwww1wwww/wwwwwwwww b', 'the position after');
    is($bd->key_hex, $bd->key_full_hex, 'the key kept up');
    isnt($bd->key_hex, $key, 'and moved');

    is(ref($bd->undo_step($token)), $E, 'undo_step returns the board');
    is($bd->to_string, $before, 'and the position is the set-up again');
    is($bd->key_hex, $key, 'with the set-up\'s key');
    is($bd->count(BLACK), 22, 'and all twenty-two black stones');
};

subtest 'do_step judges nothing' => sub {
    my $bd = board('9/9/3w1b3/9/w8 w');
    is($bd->step_why(sq('a1'), N, PAIKA), WHY_MUST_CAPTURE, 'a1-a2 is not a legal step');
    my $token = $bd->do_step(sq('a1'), N, PAIKA);
    ok(defined $token, 'and do_step makes it anyway');
    is($bd->to_string, '9/9/3w1b3/w8/9 b', 'the stone moved and the turn passed');
    $bd->undo_step($token);

    my $other = $bd->do_step(sq('f3'), W, APPROACH);
    ok(defined $other, 'do_step moves a stone that is not the mover\'s');
    is($bd->at(sq('d3')), EMPTY, 'and it takes as its own colour would: d3 is gone');
    $bd->undo_step($other);
    is($bd->to_string, '9/9/3w1b3/9/w8 w', 'and undo puts all of it back');

    my $quiet = $bd->step(sq('d3'), E, PAIKA);
    is_deeply($quiet->{taken}, [], 'step builds a paika with nothing taken, even where the step would take');
    my $q = $bd->do_step($quiet);
    is($bd->at(sq('f3')), BLACK, 'and do_step, given that, takes nothing');
    $bd->undo_step($q);
    is($bd->to_string, '9/9/3w1b3/9/w8 w', 'undone');
};

subtest 'what cannot be built or done' => sub {
    my $bd = board('9/9/3w1b3/9/w8 w');
    my $before = $bd->to_string;
    is($bd->step(sq('e3'), N, PAIKA), undef, 'no step from an empty point');
    is($bd->step(sq('a1'), S, PAIKA), undef, 'none off the edge');
    is($bd->step(sq('d3'), NE, PAIKA), undef, 'none along a diagonal a weak point does not have');
    is($bd->step(sq('d3'), E, WITHDRAWAL), undef, 'no withdrawal with nothing behind');
    is($bd->step(sq('d3'), E, 5), undef, 'no step of a kind that is not one');
    is($bd->step(sq('d3'), 9, PAIKA), undef, 'nor in a direction that is not one');
    is($bd->step(0, N, PAIKA), undef, 'nor from the ring');
    is(scalar(my @none = $bd->do_step(sq('e3'), N, PAIKA)), 0, 'do_step of no step does nothing and returns nothing');
    is($bd->to_string, $before, 'and the board is as it was');

    my $full = board('9/9/3ww4/9/9 w');
    is($full->step(sq('d3'), E, PAIKA), undef, 'no step onto a stone');

    ok(!eval { $bd->undo_step('not a token'); 1 }, 'undo_step croaks on something that is not a token');
    like($@, qr/not an undo token/, 'and says so');
    is($bd->to_string, $before, 'and the board is still as it was');
};

# A WALK. Five thousand steps taken at random from the legal list, the board
# checked after each, and then every one of them undone in turn. Undo restores
# from the record and never by working it out again, so a stone it puts back
# on the wrong point shows here as a string that does not match.
subtest 'five thousand steps, done and undone' => sub {
    my $roll = roller(7102026);
    my ($done, $games, $captures, $most, @bad) = (0, 0, 0, 0);
    while ($done < 5000) {
        my $bd = $E->new;
        $games++;
        my @trail;
        while ($done < 5000) {
            my @steps = $bd->steps;
            last unless @steps;
            $most = @steps if @steps > $most;
            my $s = $steps[ $roll->(scalar @steps) ];
            my ($white, $black) = ($bd->count(WHITE), $bd->count(BLACK));
            my $mover = $bd->side;
            push @trail, [ $bd->to_string, $bd->key_hex ];
            my ($token, $removed) = $bd->do_step($s);
            push @{ $trail[-1] }, $token;
            $done++;
            $captures++ if $removed;
            push @bad, "step $done: removed $removed, the step names " . scalar(@{ $s->{taken} })
                unless $removed == @{ $s->{taken} };
            push @bad, "step $done: the key drifted" unless $bd->key_hex eq $bd->key_full_hex;
            push @bad, "step $done: the turn did not pass" unless $bd->side == other($mover);
            my ($w2, $b2) = ($bd->count(WHITE), $bd->count(BLACK));
            my $lost = $mover == WHITE ? $black - $b2 : $white - $w2;
            my $kept = $mover == WHITE ? $white - $w2 : $black - $b2;
            push @bad, "step $done: the mover lost a stone" if $kept;
            push @bad, "step $done: the count fell by $lost, not $removed" unless $lost == $removed;
            push @bad, "step $done: a taken point is not empty"
                if grep { $bd->at($_) != EMPTY } @{ $s->{taken} };
            last if @trail >= 400;
        }
        for my $was (reverse @trail) {
            my ($string, $key, $token) = @$was;
            $bd->undo_step($token);
            push @bad, "undo: wanted $string, got " . $bd->to_string unless $bd->to_string eq $string;
            push @bad, 'undo: the key did not come back' unless $bd->key_hex eq $key;
        }
        push @bad, 'a walk did not unwind to the set-up' unless $bd->to_string eq $E->new->to_string;
    }
    is($done, 5000, 'five thousand steps');
    cmp_ok($games, '>=', 10, "over $games walks from the set-up");
    cmp_ok($captures, '>', 500, "$captures of them captures");
    cmp_ok($most, '<=', $E->steps_max, "the longest list was $most, inside the 216 a caller keeps room for");
    is(scalar(@bad), 0, 'every step kept the board sound, and every undo restored it exactly')
        or diag join "\n", @bad[0 .. ($#bad < 5 ? $#bad : 5)];
};

done_testing();
