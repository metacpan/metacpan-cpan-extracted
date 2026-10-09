use strict;
use warnings;
use Test::More;

use Game::Brandubh;
use Game::Brandubh::Error;
my $G = 'Game::Brandubh';
my $X = 'Game::Brandubh::Error';

# A TEST THAT ONLY PLAYS LEGAL MOVES LEAVES EVERY REFUSAL UNTESTED. Each of the
# fourteen is produced here by something written to produce it, the game is
# shown to be exactly as it was afterwards, and the refusal is asked every
# question it can answer.

# everything about a game that a refusal must not have touched
sub snapshot {
    my ($g) = @_;
    return join '|', $g->position, $g->ply, $g->status, ($g->turn // '-'), ($g->draw_offered_by // '-'),
        "@{ $g->log }", "@{ $g->shown }", $g->signature, $g->repeats,
        ($g->result ? $g->result->how : '-');
}

my @FLAGS = $X->flags;

sub refusal_is {
    my ($refused, $want, $why) = @_;
    subtest "$want: $why" => sub {
        ok($refused, 'something was handed back') or return;
        isa_ok($refused, $X);
        is($refused->code, $want, "its code is $want");
        ok($refused->$want, "and ->$want is true");
        my @others = grep { $_ ne $want && $refused->$_ } @FLAGS;
        is("@others", '', 'and every other accessor is false');
        is($refused->message, $X->message_for($want), 'it carries that refusal\'s sentence');
        cmp_ok(length $refused->message, '>', 10, 'which is a sentence: ' . $refused->message);
    };
}

# code, how to make the game, what to do to it
my $throne  = sub { $G->new(position => '7/7/7/a6/7/7/3k3 a') };
my $over    = sub { my $g = $G->new(position => '7/7/7/k6/7/7/3a3 d'); $g->play_or_die('a4a1'); $g };
my $offered = sub { my $g = $G->new; $g->offer_draw('p1'); $g };

my @CASES = (
    [ 'bad_move',       sub { $G->new }, sub { $_[0]->play('zz') },                 'a string that is not a move' ],
    [ 'bad_move',       sub { $G->new }, sub { $_[0]->play(undef) },                'no move at all' ],
    [ 'bad_move',       sub { $G->new }, sub { $_[0]->play('d1-d8') },              'a move to a rank the board has not got' ],
    [ 'bad_move',       sub { $G->new }, sub { $_[0]->play(['d1c1']) },             'a reference' ],
    [ 'game_over',      $over,           sub { $_[0]->play('d1c1') },               'a move in a finished game' ],
    [ 'game_over',      $over,           sub { $_[0]->resign('p1') },               'resigning a finished game' ],
    [ 'game_over',      $over,           sub { $_[0]->offer_draw('p1') },           'offering a draw in one' ],
    [ 'game_over',      $over,           sub { $_[0]->accept_draw('p1') },          'accepting one' ],
    [ 'not_a_seat',     sub { $G->new }, sub { $_[0]->play('d1c1', 'p3') },         'a move by a seat that does not exist' ],
    [ 'not_a_seat',     sub { $G->new }, sub { $_[0]->resign('attackers') },        'resigning as a side and not a seat' ],
    [ 'not_a_seat',     sub { $G->new }, sub { $_[0]->resign(undef) },              'resigning as nobody' ],
    [ 'not_a_seat',     sub { $G->new }, sub { $_[0]->offer_draw('P1') },           'offering as P1 in capitals' ],
    [ 'not_your_turn',  sub { $G->new }, sub { $_[0]->play('d1c1', 'p2') },         'p2 playing the attackers\' move on the attackers\' turn' ],
    [ 'not_your_turn',  sub { $G->new }, sub { $_[0]->play('d3c3', 'p2') },         'p2 playing its own piece out of turn' ],
    [ 'no_piece',       sub { $G->new }, sub { $_[0]->play('b2b3') },               'from an empty square' ],
    [ 'not_your_piece', sub { $G->new }, sub { $_[0]->play('d3c3') },               'a defender, on the attackers\' turn' ],
    [ 'not_your_piece', sub { $G->new }, sub { $_[0]->play('d4d4') },               'the king, on the attackers\' turn' ],
    [ 'no_move',        sub { $G->new }, sub { $_[0]->play('d1d1') },               'a piece to the square it stands on' ],
    [ 'not_a_line',     sub { $G->new }, sub { $_[0]->play('a4b5') },               'a diagonal' ],
    [ 'not_a_line',     sub { $G->new }, sub { $_[0]->play('d1e3') },               'a knight\'s move' ],
    [ 'path_blocked',   sub { $G->new }, sub { $_[0]->play('d1d3') },               'through a piece, onto a piece' ],
    [ 'path_blocked',   sub { $G->new }, sub { $_[0]->play('a4c4') },               'through one of its own' ],
    [ 'path_blocked',   sub { $G->new }, sub { $_[0]->play('d1d2') },               'onto one of its own' ],
    [ 'throne_closed',  $throne,         sub { $_[0]->play('a4d4') },               'an attacker stopping on the empty throne' ],
    [ 'throne_closed',  sub { $G->new(position => '7/7/7/2k4/7/7/3a3 d') },
                                         sub { $_[0]->play('c4d4') },               'the king going back to it' ],
    [ 'throne_closed',  sub { $G->new(position => '7/7/7/a6/7/7/3k3 a', variant => { throne_pass => 0 }) },
                                         sub { $_[0]->play('a4e4') },               'crossing it when the rule set says no' ],
    [ 'corner_closed',  sub { $G->new }, sub { $_[0]->play('a4a7') },               'an attacker onto a corner' ],
    [ 'corner_closed',  sub { $G->new(position => '7/7/7/d6/7/6a/3k3 d') },
                                         sub { $_[0]->play('a4a1') },               'a defender onto one' ],
    [ 'no_offer',       sub { $G->new }, sub { $_[0]->accept_draw('p1') },          'accepting a draw nobody offered' ],
    [ 'no_offer',       sub { $G->new }, sub { $_[0]->decline_draw('p2') },         'declining one' ],
    [ 'own_offer',      $offered,        sub { $_[0]->accept_draw('p1') },          'accepting your own offer' ],
    [ 'own_offer',      $offered,        sub { $_[0]->decline_draw('p1') },         'declining your own offer' ],
    [ 'offer_standing', $offered,        sub { $_[0]->offer_draw('p2') },           'offering when an offer is waiting' ],
    [ 'offer_standing', $offered,        sub { $_[0]->offer_draw('p1') },           'offering twice' ],
);

my %produced;
for my $case (@CASES) {
    my ($want, $make, $do, $why) = @$case;
    my $g = $make->();
    my $before = snapshot($g);
    my $refused = $do->($g);
    refusal_is($refused, $want, $why);
    is(snapshot($g), $before, "$want: and the game is exactly as it was");
    $produced{$want}++;
}

is(join(' ', sort keys %produced), join(' ', sort @FLAGS), 'every one of the refusals was produced');
is(scalar(@FLAGS), 14, 'and there are fourteen');

subtest 'the move that was refused is kept as it was given' => sub {
    my $g = $G->new;
    is($g->play('Kd1-d3')->move, 'Kd1-d3', 'as written, decoration and all');
    is($g->play('zz')->move, 'zz', 'even when it is not a move');
    is($g->play(undef)->move, undef, 'and nothing when there was nothing');
    is($g->resign('p3')->move, undef, 'a refusal that is not about a move has none');
};

subtest 'a refusal is true, and success is 0' => sub {
    my $g = $G->new;
    my $played = $g->play('d1c1');
    is($played, 0, 'a move that is played returns 0');
    ok(!$played, 'which is false');
    ok($g->play('d1c1'), 'and a refusal is true');
    is($g->offer_draw('p1'), 0, 'an offer made returns 0');
    is($g->decline_draw('p2'), 0, 'an offer declined returns 0');
    is($g->resign('p2'), 0, 'a resignation returns 0');
};

subtest 'play_or_die' => sub {
    my $g = $G->new;
    is($g->play_or_die('d1c1'), $g, 'returns the game, so that moves chain');
    ok(!eval { $g->play_or_die('d1c1'); 1 }, 'and croaks on a refusal');
    like($@, qr/'d1c1' was refused: there is no piece there/, 'with the move and the sentence');
    is($g->ply, 1, 'having changed nothing');
};

subtest 'the Error class itself' => sub {
    is($X->throw('no_piece')->code, 'no_piece', 'throw returns a refusal; it does not die');
    ok(!eval { $X->throw('no_such_thing'); 1 }, 'a name that is not a refusal croaks');
    like($@, qr/no such refusal as 'no_such_thing'/, 'naming it');
    ok(!eval { $X->throw(undef); 1 }, 'so does no name');
    ok(!eval { $X->new; 1 }, 'new with nothing croaks');
    ok(!eval { $X->new(no_piece => 1, bad_move => 1); 1 }, 'and so does a refusal that names two things');
    ok($X->known('throne_closed'), 'known: a refusal');
    ok(!$X->known('throne'), 'known: not one');
    ok(!$X->known(undef), 'known: undef');
    is($X->message_for('nothing'), undef, 'message_for something that is not a refusal');
    my %sentences = map { $X->message_for($_) => 1 } @FLAGS;
    is(scalar(keys %sentences), 14, 'fourteen refusals, fourteen different sentences');
};

done_testing();
