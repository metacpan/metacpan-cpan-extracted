#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Gin;
use Game::Gin::Bot;
use Game::Gin::Card qw(id_of name_of);

# THE MOVE LOG IS THE CANONICAL SERIALISATION, not the position.
#
# A snapshot of a gin table carries neither hand nor the stock order, and both
# decide the result. A game is its seed and its moves, and that is what makes
# a finished game checkable by anybody once the seed is published: they replay
# it and get the same answer or they do not.
#
# So the property under test is the one the whole design rests on: the same
# seed and the same moves give the same game, every time, anywhere.

sub seed { return Digest::SHA::sha256("replay:$_[0]") }

# Play a match and keep the moves, which is all a log needs to hold.
sub record {
    my ($n) = @_;
    my $g = Game::Gin->build(seed => seed($n), dealer => 'p1');
    my %bot = (p1 => Game::Gin::Bot->new(level => 2),
               p2 => Game::Gin::Bot->new(level => 1));
    my @log;
    my $moves = 0;
    while (!$g->over && $moves++ < 8000) {
        my $seat = $g->turn or last;
        my $move = $bot{$seat}->choose($g, $seat) or last;
        push @log, { seat => $seat, move => { %$move } };
        my @out = $g->apply($seat, $move);
        die 'refused: ' . $out[0]->code if ref $out[0] eq 'Game::Gin::Error';
    }
    return ($g, \@log);
}

# Replay a log against a fresh game from the same seed.
sub replay {
    my ($n, $log) = @_;
    my $g = Game::Gin->build(seed => seed($n), dealer => 'p1');
    for my $entry (@$log) {
        my @out = $g->apply($entry->{seat}, $entry->{move});
        return ($g, $out[0]) if ref $out[0] eq 'Game::Gin::Error';
    }
    return ($g, undef);
}

sub fingerprint {
    my ($g) = @_;
    my $r = $g->result or return 'unfinished';
    return join '|', $r->{winner} // '-', $r->{totals}{p1}, $r->{totals}{p2},
                     $r->{hands_won}{p1}, $r->{hands_won}{p2}, scalar @{ $g->hands };
}

# ---- the property -------------------------------------------------------------------

subtest 'a seed and a move list reproduce the game' => sub {
    my $N = $ENV{GIN_REPLAYS} || 15;
    plan tests => 4;

    my ($checked, @wrong, @refused) = (0);
    for my $n (1 .. $N) {
        my ($original, $log) = record($n);
        next unless $original->over;
        $checked++;

        my ($again, $err) = replay($n, $log);
        push @refused, { n => $n, code => $err->code } if $err && @refused < 5;
        push @wrong, { n => $n, was => fingerprint($original), now => fingerprint($again) }
            if !$err && fingerprint($again) ne fingerprint($original) && @wrong < 5;
    }

    is($checked, $N, "$checked matches were replayed");
    cmp_ok($checked, '>', 5, 'which is enough of them to mean something');
    is_deeply(\@refused, [], 'no honest log was refused') or diag(explain(\@refused));
    is_deeply(\@wrong, [], 'and every replay reached the same result')
        or diag(explain(\@wrong));
};

subtest 'the replay is of the moves, not of the outcome' => sub {
    plan tests => 2;
    # A log that reproduced the result by carrying it would pass the subtest
    # above and prove nothing. The log holds seats and moves and no result at
    # all, which is what makes the reproduction mean something.
    my (undef, $log) = record(1);
    my @keys = sort keys %{ $log->[0] };
    is_deeply(\@keys, [qw(move seat)], 'a log entry is a seat and a move');

    my %fields;
    $fields{$_}++ for map { keys %{ $_->{move} } } @$log;
    my @unexpected = grep { !/^(?:kind|card|knock)$/ } sort keys %fields;
    is_deeply(\@unexpected, [], 'and a move is a kind, a card and a knock, and nothing else')
        or diag("also found: @unexpected");
};

# ---- a log that was tampered with ------------------------------------------------------

subtest 'a tampered log does not reproduce the game' => sub {
    plan tests => 3;
    my ($original, $log) = record(2);
    ok($original->over, 'a finished match to tamper with');

    # Find a discard and change which card was thrown. Either the card is not
    # in the hand at that point, and the replay is refused outright, or it is
    # and the game diverges. Both are detections; what must not happen is the
    # tampered log quietly reproducing the original result.
    my ($at) = grep { $log->[$_]{move}{kind} eq 'discard' } 0 .. $#$log;
    ok(defined $at, 'there is a discard in the log');

    my @tampered = map { { seat => $_->{seat}, move => { %{ $_->{move} } } } } @$log;
    my $was = $tampered[$at]{move}{card};
    $tampered[$at]{move}{card} = $was == 52 ? 1 : $was + 1;

    my ($again, $err) = replay(2, \@tampered);
    ok($err || fingerprint($again) ne fingerprint($original),
       'the tampered log was refused or reached a different result')
        or diag('tampering changed nothing, which means the log is not the game');
};

subtest 'a log from another seed does not reproduce it either' => sub {
    plan tests => 1;
    my ($original, $log) = record(3);
    my ($again, $err) = replay(4, $log);      # same moves, different deal
    ok($err || fingerprint($again) ne fingerprint($original),
       'the same moves against a different deal are refused or differ');
};

done_testing();
