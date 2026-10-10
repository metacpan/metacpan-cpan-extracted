use strict;
use warnings;
use Test::More;

use Game::RoyalUr;
use Game::RoyalUr::Notation qw(parse_record format_record);
my $G = 'Game::RoyalUr';

# A whole game, the move chosen by a counter so that the same seed is always
# the same game.
sub played {
    my (%arg) = @_;
    my $stop = delete $arg{stop};
    my $game = $G->new(%arg);
    my $pick = 0;
    until ($game->is_over) {
        last if defined $stop && $game->ply >= $stop;
        my @moves = $game->legal;
        $game->play_or_die($moves[ $pick++ % @moves ]);
    }
    return $game;
}

sub same {
    my ($one, $two) = @_;
    return [] unless $one && $two;
    return [ $one->position, $one->key, $one->ply, $one->rolls, $one->first, $one->is_over ? 1 : 0 ] if @_ == 1;
    return $one->position eq $two->position && $one->key eq $two->key && $one->ply == $two->ply
        && $one->rolls == $two->rolls && $one->first eq $two->first;
}

subtest 'two hundred games a rule set, recorded and replayed' => sub {
    for my $rules ('finkel', 'masters') {
        my ($plies, @bad) = (0);
        for my $n (1 .. 200) {
            my $game = played(seed => "replay $rules $n", rules => $rules, ($n % 2 ? (first => 'light') : ()));
            my $text = $game->to_record;
            my ($again, $error) = $G->replay($text);
            if (!$again) { push @bad, "game $n would not replay: " . $error->code; next }
            push @bad, "game $n replayed to a different game" unless same($game, $again);
            push @bad, "game $n has a different log" unless join('|', map { join ',', map { defined $_ ? $_ : '-' } @{$_}{qw(ply side throw roll faces move)} } @{ $again->log })
                                                         eq join('|', map { join ',', map { defined $_ ? $_ : '-' } @{$_}{qw(ply side throw roll faces move)} } @{ $game->log });
            push @bad, "game $n wrote a different record the second time" unless $again->to_record eq $text;
            push @bad, "game $n lost its result" unless $again->result && $again->result->winner eq $game->result->winner;
            $plies += $game->ply;
        }
        is(scalar @bad, 0, "$rules: two hundred games, $plies plies") or diag(join "\n", @bad[0 .. ($#bad > 5 ? 5 : $#bad)]);
    }
};

subtest 'a game that is not finished, and one that was resigned' => sub {
    my $game = played(seed => 'half way', first => 'light', stop => 30);
    ok(!$game->is_over, 'thirty plies in');
    my $text = $game->to_record;
    unlike($text, qr/\[result/, 'its record has no result');
    my ($again) = $G->replay($text);
    ok(same($game, $again), 'and replays to the same place');
    is($again->roll, $game->roll, 'with the same roll waiting');
    is(join(' ', map { $_->from . '-' . $_->to } $again->legal), join(' ', map { $_->from . '-' . $_->to } $game->legal),
        'and the same moves to choose from');

    $game->resign;
    like($game->to_record, qr/\[result (?:light|dark) resign\]\n\z/, 'resigned, the record says who won');
    my ($resigned) = $G->replay($game->to_record);
    ok($resigned->is_over, 'and the replay is over');
    is($resigned->result->how, 'resign', 'by resignation');
    is($resigned->result->winner, $game->result->winner, 'to the same side');
};

subtest 'the opening throw is part of the record' => sub {
    my $game = played(seed => 'facade 1', stop => 12);
    my $text = $game->to_record;
    like($text, qr/^\[first dark\]\n\[seed [0-9a-f]+\]\n\[opening 4\]$/m, 'dark first, after four opening throws');
    my ($again, $error) = $G->replay($text);
    ok($again, 'it replays') or diag($error && $error->code);
    is(scalar @{ $again->opening }, 4, 'with its four opening throws');
    ok(same($game, $again), 'to the same place');

    (my $lied = $text) =~ s/^\[first dark\]$/[first light]/m;
    my ($none, $why) = $G->replay($lied);
    ok(!$none, 'a record that says light moved first is refused');
    is($why->code, 'bad_record', 'as a bad record');
};

# The record below is a real game. Then one thing is changed, and the replay
# must stop AT THAT TURN and say why.
subtest 'a record that has been edited' => sub {
    my $game = played(seed => 'edited', first => 'light', stop => 40);
    my $record = (parse_record($game->to_record))[0];
    my @moves = grep { defined $record->{turns}[$_]{move} } 0 .. $#{ $record->{turns} };
    my $ply = $moves[10];

    my ($ok) = $G->replay($record);
    ok($ok, 'the record as it was played replays, given as a structure');

    {
        my $edited = { %$record, turns => [ map { { %$_ } } @{ $record->{turns} } ] };
        $edited->{turns}[$ply]{roll} = ($edited->{turns}[$ply]{roll} % 4) + 1;
        delete $edited->{turns}[$ply]{faces};
        my ($none, $error) = $G->replay($edited);
        ok(!$none, 'one roll changed: refused');
        is($error->code, 'bad_record', 'as a bad record');
        is($error->detail->{ply}, $ply, "at ply $ply, where the roll was changed");
        is($error->detail->{why}, 'roll', 'because of the roll');

        my ($text_none, $text_error) = $G->replay(format_record($edited));
        ok(!$text_none, 'and as text it is refused before it is played');
        is($text_error->detail->{why}, 'roll', 'for the same reason');
    }
    {
        my $edited = { %$record, turns => [ map { { %$_ } } @{ $record->{turns} } ] };
        my ($from) = $edited->{turns}[$ply]{move} =~ /\A([a-z0-9]+)-/;
        $edited->{turns}[$ply]{move} = "$from-" . ($edited->{turns}[$ply]{move} =~ /-h3\z/ ? 'h2' : 'h3');
        my ($none, $error) = $G->replay($edited);
        ok(!$none, 'one destination changed: refused');
        is($error->detail->{ply}, $ply, "at ply $ply");
        like($error->code, qr/\A(?:wrong_distance|own_piece)\z/, 'with the reason the move is not one: ' . $error->code);
        is($error->detail->{to}, ($edited->{turns}[$ply]{move} =~ /-(\w+)\z/)[0], 'naming the square');
    }
    {
        my $edited = { %$record, turns => [ map { { %$_ } } @{ $record->{turns} } ] };
        $edited->{turns}[$ply]{side} = $edited->{turns}[$ply]{side} eq 'light' ? 'dark' : 'light';
        my ($none, $error) = $G->replay($edited);
        is($error && $error->detail->{why}, 'side', 'the wrong side on a line: refused for the side');
        is($error && $error->detail->{ply}, $ply, "at ply $ply");
    }
    {
        my $edited = { %$record, turns => [ map { { %$_ } } @{ $record->{turns} } ] };
        $edited->{turns}[$ply]{move} = undef;
        my ($none, $error) = $G->replay($edited);
        is($error && $error->detail->{why}, 'forfeit', 'a move turned into a lost turn: there was a move to make');
        is($error && $error->detail->{ply}, $ply, "at ply $ply");
    }
};

subtest 'a lost turn that the record says was a move' => sub {
    my $game = played(seed => 'facade 46', first => 'light', stop => 3);
    my $record = (parse_record($game->to_record))[0];
    is($record->{turns}[1]{move}, undef, 'ply 1 of that game is a lost turn');
    $record->{turns}[1]{move} = 'hand-d3';
    my ($none, $error) = $G->replay($record);
    ok(!$none, 'refused');
    is($error->detail->{why}, 'move', 'because nothing could be moved there');
    is($error->detail->{ply}, 1, 'at ply 1');
};

# A RECORD OF ONE RULE SET PLAYED AS ANOTHER is refused where the two first
# part company, and not at the end.
subtest 'a finkel record replayed as masters' => sub {
    my $game = played(seed => 'which rules', first => 'light');
    my $turns = scalar @{ $game->log };
    cmp_ok($turns, '>', 60, "a finished finkel game of $turns plies");
    my ($none, $error) = $G->replay($game->to_record, rules => 'masters');
    ok(!$none, 'is refused under masters');
    ok(defined $error->detail->{ply}, 'at a named ply');
    cmp_ok($error->detail->{ply}, '<', 10, 'near the start, where the dice first differ: ply ' . $error->detail->{ply});
    my ($same) = $G->replay($game->to_record, rules => 'finkel');
    ok($same, 'and replays under its own rules when they are named');
};

# NO SEED: the rolls are taken as written. This is how a game played with real
# dice is replayed. It can be read; it cannot be played on.
subtest 'a record with no seed' => sub {
    my $game = played(seed => 'real dice', first => 'dark', stop => 25);
    (my $text = $game->to_record) =~ s/^\[seed [0-9a-f]+\]\n//m;
    unlike($text, qr/seed/, 'the seed is taken out of the record');
    my ($again, $error) = $G->replay($text);
    ok($again, 'it still replays') or diag($error && $error->code . ' ' . join(',', %{ $error->detail }));
    is($again->position, $game->position, 'to the same position');
    is($again->ply, $game->ply, 'at the same ply');
    is($again->seed, undef, 'with no seed');
    is($again->roll, undef, 'and no roll waiting: nobody can say what would have been thrown');
    is(scalar($again->legal), 0, 'so no moves');
    ok(!$again->play('hand-d1'), 'and a move is refused');
    is($again->error->code, 'no_roll', 'for want of a roll');
    is($again->to_record, $text, 'it writes the record it was read from');

    my $bent = $text;
    $bent =~ s/^(\d+)\. ([ld]) ([1-4])( [01]+)?: hand-(\w+)$/"$1. $2 " . ($3 == 4 ? 1 : $3 + 1) . ": hand-$5"/me
        or die 'no entering move to bend';
    my ($none, $why) = $G->replay($bent);
    ok(!$none, 'but its moves are still checked: an entry at the wrong distance is refused');
    is($why->code, 'wrong_distance', 'as the wrong distance');
};

subtest 'text that is not a record' => sub {
    my ($none, $error) = $G->replay("not a record\n");
    ok(!$none, 'is refused');
    is($error->code, 'bad_record', 'as a bad record');
    is($error->detail->{line}, 1, 'at its first line');
    is($error->detail->{why}, 'rules', 'for having no rules');
};

done_testing();
