use strict;
use warnings;
use Test::More;

use Game::Xiangqi;
use Game::Xiangqi::Bot;
use Game::Xiangqi::Engine ':all';

my $G = 'Game::Xiangqi';
my $E = 'Game::Xiangqi::Engine';
my $B = 'Game::Xiangqi::Bot';
my $SEED = join '', map { chr } 0 .. 31;

$Game::Xiangqi::Bot::LEVEL = 400;

sub game { $G->new(seed => $SEED, red => 'p1', @_) }

sub played {
    my $g = game();
    for my $m (@_) {
        my $why = $g->play($m);
        die "the line refused $m: " . $why->code . "\n" if $why;
    }
    return $g;
}

sub bot_moves {
    my ($g) = @_;
    my @moves;
    for (1 .. 3) {
        my $m = $g->status eq 'active' ? $B->choose($g, $g->turn) : undef;
        push @moves, defined $m ? $m : '-';
        last unless defined $m;
        $g->play($m);
    }
    return \@moves;
}

sub round_trip {
    my ($name, $g) = @_;
    subtest $name => sub {
        my $text = $g->to_text;
        ok defined $text && !ref $text, 'to_text is a string';

        my $back = $G->from_text($text);
        isa_ok $back, $G;
        is $back->to_text, $text, 'save(load(save)) is save';
        is_deeply $back->legal, $g->legal, 'the same legal moves';
        is $back->status, $g->status, 'the same status';
        is_deeply $back->result, $g->result, 'the same result';
        is_deeply $back->log, $g->log, 'the same log';
        is $back->signature, $g->signature, 'the same position';
        is $back->turn, $g->turn, 'the same seat to move';

        my $other = $G->from_text($text);
        if ($other->status eq 'active') {
            $other->play($other->legal->[0]);
            is $g->to_text, $text, 'playing on the rebuilt game leaves the original alone';
        }
        else {
            $other->status('active');
            is $g->status, $back->status, 'changing the rebuilt game leaves the original alone';
        }

        is_deeply bot_moves($back), bot_moves($g), 'the next three bot moves are the same';
    };
}

round_trip('at the start', game());

round_trip('after three moves', played(qw(h2e2 h9g7 h0g2)));

round_trip('after a capture', played(qw(b2b9)));

round_trip('with p2 playing red', $G->new(seed => $SEED, red => 'p2'));

sub perpetual_check {
    my $p = $E->new(empty => 1);
    $p->put($E->point_of(@{$_}[0, 1]), $_->[2])
        for [4, 9, BLACK | GENERAL], [3, 1, RED | CHARIOT],
            [0, 8, RED | CHARIOT],   [5, 0, RED | GENERAL];
    my $g = game(position => $p);
    for (1 .. 20) {
        last unless $g->status eq 'active';
        my $q = $g->position;
        my $m;
        if ($q->side == RED) {
            my $f = $E->file_of($q->find(BLACK | GENERAL));
            ($m) = grep { $E->rank_of($E->move_from($_)) == 1
                       && $E->rank_of($E->move_to($_)) == 1
                       && $E->file_of($E->move_to($_)) == $f } $q->legal;
        }
        else {
            ($m) = grep { $E->move_from($_) == $q->find(BLACK | GENERAL) } $q->legal;
        }
        last unless defined $m;
        $g->play(Game::Xiangqi::Notation->iccs_of($m));
    }
    return $g;
}

{
    my $g = perpetual_check();
    is $g->result->{reason}, 'perpetual_check', 'the perpetual check line is ruled';
    round_trip('after a perpetual check ruling', $g);
    my @log = @{ $g->log };
    my $short = $g->replay([ @log[0 .. $#log - 1] ]);
    is $short->status, 'active', 'one move before the ruling the game is on';
    round_trip('one move before a perpetual check ruling', $short);
}

{
    my $g = played(qw(h2e2 h9g7));
    $g->status('finished');
    round_trip('after the caller ends it, as for a resignation', $g);
    like $g->to_text, qr/^status finished$/m, 'the text carries the status';
}

{
    my $g = game();
    while ($g->status eq 'active' && @{ $g->log } < 300) {
        $g->play($B->choose($g, $g->turn));
    }
    my @log = @{ $g->log };
    cmp_ok scalar @log, '>', 4, 'the bot plays a game of ' . scalar(@log) . ' moves';
    round_trip('late in a game the bot played', $g->replay([ @log[0 .. $#log - 3] ]));
    round_trip('at the end of a game the bot played', $g);
}

subtest 'a malformed string is refused with a sentence' => sub {
    my $good = played(qw(h2e2 h9g7))->to_text;
    my @bad = (
        [ undef,                                        qr/given nothing/ ],
        [ [],                                           qr/given a reference/ ],
        [ '',                                           qr/not a saved game of xiangqi/ ],
        [ "chess 1\n",                                  qr/not a saved game of xiangqi/ ],
        [ $good =~ s/^red .*\n//mr,                     qr/no red line/ ],
        [ $good . "moves h2e2\n",                       qr/gives moves twice/ ],
        [ $good . "colour blue\n",                      qr/does not know: 'colour blue'/ ],
        [ $good =~ s/^seed \w+/seed 1234/mr,            qr/sixty-four hex digits/ ],
        [ $good =~ s/^red p1/red p3/mr,                 qr/red must be 'p1' or 'p2'/ ],
        [ $good =~ s/^start .*/start nonsense/mr,       qr/start position was refused/ ],
        [ $good =~ s/^moves .*/moves h2e2 h2e2/mr,      qr/saved move 2, h2e2, was refused: no_piece/ ],
        [ $good =~ s/^moves .*/moves zz99/mr,           qr/saved move 1, zz99, was refused: bad_move/ ],
        [ $good =~ s/^status active/status over/mr,     qr/status must be/ ],
    );
    for my $case (@bad) {
        my ($text, $why) = @$case;
        my $ok = eval { $G->from_text($text); 1 };
        ok !$ok, 'refused: ' . (defined $text && !ref $text ? (split /\n/, $text)[0] // '(empty)' : 'not a string');
        like $@, qr/\AGame::Xiangqi: .*$why/s, '  with the sentence';
    }
};

done_testing;
