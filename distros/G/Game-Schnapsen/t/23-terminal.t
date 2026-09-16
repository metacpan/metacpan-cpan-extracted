#!perl
use 5.010; use strict; use warnings;
use Test::More;
use Digest::SHA ();

use Game::Schnapsen ();
use Game::Schnapsen::Card qw(id_of name_of);
use Game::Schnapsen::Terminal ();
use Game::Schnapsen::Variant qw(variants);
use FindBin ();

# THE TERMINAL, DRIVEN WITH NO TERMINAL.
#
# `in` and `out` are attributes rather than STDIN and STDOUT precisely so this
# file can exist. A version that reached for the real handles would be exercised
# only by a person sitting in front of it, which is to say never, in the only
# module of the distribution that a player actually touches.

sub seed { return Digest::SHA::sha256($_[0]) }
my @VARIANTS = variants();

# A terminal writing into a string and reading from one.
sub term {
    my (%o) = @_;
    my $out = '';
    open my $wh, '>', \$out or die $!;
    my $input = delete($o{input}) // '';
    open my $rh, '<', \$input or die $!;
    my $t = Game::Schnapsen::Terminal->new(
        variant => $o{variant} // 'schnapsen',
        mode    => $o{mode} // 'watch',
        level   => $o{level} // 2,
        seat    => $o{seat} // 'p1',
        ascii   => 1,
        colour  => 0,
        in      => $rh,
        out     => $wh,
    );
    return ($t, \$out);
}

sub started {
    my (%o) = @_;
    my ($t, $out) = term(%o);
    my $g = Game::Schnapsen->build(
        variant => $o{variant} // 'schnapsen',
        seed => seed($o{tag} // 'term'), dealer => 'p1');
    $t->game($g);
    return ($t, $g, $out);
}

# ---- a whole match, with nobody watching -------------------------------------------

subtest 'a watched match plays to the end and says who won' => sub {
    plan tests => 5 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($t, $out) = term(variant => $v);
        my $g = $t->play(seed => seed("watch $v"));

        isa_ok($g, 'Game::Schnapsen', "$v: it returned a game");
        is($g->over, 1, "$v: which finished");
        cmp_ok(length $$out, '>', 400, "$v: and printed " . length($$out) . ' characters');
        like($$out, qr/win(?:s)? the match/, "$v: including who won it");
        unlike($$out, qr/\e\[/, "$v: with no colour, because colour was turned off");
    }
};

subtest 'a bad variant is refused before anything is printed as a game' => sub {
    plan tests => 2;
    my ($t, $out) = term(variant => 'bezique');
    my $r = $t->play(seed => seed('bad'));
    isa_ok($r, 'Game::Schnapsen::Error', 'play returns the error');
    like($$out, qr/Cannot start/, 'and says so rather than dying');
};

# ---- THE SCORE LINE, which is where the two games would start to blur ------------------

subtest 'the score line runs the way its game runs' => sub {
    # Showing both as a count up would be the first place Schnapsen and Sixty-Six
    # started to look like one game, and a Schnapsen player expects to watch a
    # number fall to zero.
    plan tests => 6;

    my ($s) = started(variant => 'schnapsen');
    like($s->score_line, qr/Game points left/, 'schnapsen counts what is left');
    like($s->score_line, qr/down to zero/, 'and says which way that runs');
    like($s->score_line, qr/you 7\b/, 'starting at seven');

    my ($x) = started(variant => 'sixtysix');
    like($x->score_line, qr/Game points\s+you 0/, 'sixtysix counts up from nothing');
    like($x->score_line, qr/first to 7/, 'and says where it is going');
    unlike($x->score_line, qr/left/, 'and never calls it what is left');
};

subtest 'the table says what is on it' => sub {
    plan tests => 5 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($t, $g) = started(variant => $v, tag => "table $v");
        my $lines = join "\n", @{ $t->table_lines('p1') };
        like($lines, qr/Deal 1/, "$v: which deal this is");
        like($lines, qr/trump [SHDC]/, "$v: the trump suit");
        like($lines, qr/talon \d+/, "$v: and how many cards are left");
        like($lines, qr/Card points\s+you \d+\s+them \d+/, "$v: with both counts, openly");
        unlike($lines, qr/closed/, "$v: and it does not say closed while it is open");
    }
};

subtest 'a closed talon says so' => sub {
    plan tests => 2 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($t, $g) = started(variant => $v, tag => "closed $v");
        $g->deal->closed(1);
        $g->deal->drawn(1);
        my $lines = join "\n", @{ $t->table_lines('p1') };
        like($lines, qr/\(closed\)/, "$v: the table says the talon is closed");
        unlike($lines, qr/Turn-up/, "$v: and stops showing the turn-up");
    }
};

# ---- the cards ------------------------------------------------------------------------

subtest 'a card is drawn as seven rows and reads as two characters' => sub {
    plan tests => 6;
    my ($t) = started();
    my $art = $t->card_art(id_of('AH'));
    is(scalar @$art, 7, 'seven rows');
    is(scalar(grep { length($_) == length($art->[0]) } @$art), 7, 'all the same width');
    like($art->[1], qr/A/, 'with the rank in the corner');
    like($art->[3], qr/H/, 'and the pip in the middle, as a letter in ascii mode');

    is($t->pretty(id_of('TD')), 'TD', 'a card in a sentence is two characters');
    is($t->pretty(undef), '-', 'and nothing at all is a dash');
};

subtest 'a face-down card gives nothing away' => sub {
    plan tests => 2;
    my ($t) = started();
    my $back = $t->card_back;
    is(scalar @$back, 7, 'the back is the same height as a face');
    unlike(join('', @$back), qr/[AKQJT9SHDC]/, 'and says nothing about any card');
};

# ---- what a player may type -------------------------------------------------------------

subtest 'a card is named however a player writes it' => sub {
    plan tests => 6;
    my ($t) = started();
    my $hand = [ map { id_of($_) } qw(TH KS 9C) ];

    is($t->card_named('TH', $hand), id_of('TH'), 'TH');
    is($t->card_named('th', $hand), id_of('TH'), 'lower case');
    is($t->card_named('10H', $hand), id_of('TH'), '10H, because the card itself says 10');
    is($t->card_named(' KS ', $hand), id_of('KS'), 'with spaces round it');
    is($t->card_named('AS', $hand), undef, 'a card not in the hand is undef');
    is($t->card_named('', $hand), undef, 'and so is nothing');
};

subtest 'the prompt takes a card, and refuses what is not on offer' => sub {
    plan tests => 4;
    my ($t, $g, $out) = started(mode => 'hotseat', tag => 'prompt');
    my $seat = $g->turn;
    my $card = $g->deal->hand_of($seat)->cards->[0];

    # Two lines: something meaningless, then a real card. The first must be
    # refused with an explanation and the second accepted.
    my $input = "wat\n" . name_of($card) . "\n";
    open my $rh, '<', \$input or die $!;
    my $t2 = Game::Schnapsen::Terminal->new(
        variant => 'schnapsen', mode => 'hotseat', seat => $seat,
        ascii => 1, colour => 0, in => $rh, out => $t->out);
    $t2->game($g);

    my $move = $t2->human_move($seat);
    is(ref $move, 'HASH', 'a move came back');
    is($move->{kind}, 'lead', 'a lead');
    is($move->{card}, $card, 'of the card that was typed');
    like($$out, qr/did not follow that/, 'and the nonsense was refused with a word about it');
};

subtest 'the prompt lists what is legal when asked' => sub {
    plan tests => 3;
    my ($t, $g, $out) = started(mode => 'hotseat', tag => 'help');
    my $seat = $g->turn;
    my $card = $g->deal->hand_of($seat)->cards->[0];

    my $input = "?\n" . name_of($card) . "\n";
    open my $rh, '<', \$input or die $!;
    my $t2 = Game::Schnapsen::Terminal->new(
        variant => 'schnapsen', mode => 'hotseat', seat => $seat,
        ascii => 1, colour => 0, in => $rh, out => $t->out);
    $t2->game($g);
    $t2->human_move($seat);

    like($$out, qr/You may:/, 'it lists the kinds of move available');
    like($$out, qr/\blead\b/, 'which here includes leading');
    like($$out, qr/out to claim 66/, 'and explains the words for the declarations');
};

subtest 'claiming is typed in full and is never one letter' => sub {
    # A false claim loses the deal and the screen already shows the player their
    # own count, so the only way to make one is a slip. It is deliberately not a
    # keystroke away from anything else.
    plan tests => 3;
    my ($t, $g, $out) = started(mode => 'hotseat', tag => 'claimword');
    $g->deal->tricks([ { leader => 'p2', lead => 1, follow => 2, winner => 'p2' } ]);
    my $seat = $g->turn;

    for my $word (qw(out claim 66)) {
        my $input = "$word\n";
        open my $rh, '<', \$input or die $!;
        my $t2 = Game::Schnapsen::Terminal->new(
            variant => 'schnapsen', mode => 'hotseat', seat => $seat,
            ascii => 1, colour => 0, in => $rh, out => $t->out);
        $t2->game($g);
        my $move = $t2->human_move($seat);
        is(($move // {})->{kind}, 'claim', "'$word' claims");
    }
};

subtest 'a prompt with nothing to read gives up rather than spinning' => sub {
    plan tests => 1;
    my ($t, $g) = started(mode => 'hotseat', tag => 'eof');
    is($t->human_move($g->turn), undef, 'end of input ends the move');
};

# ---- what it says happened ----------------------------------------------------------------

subtest 'it describes a move from the point of view of the seat being played' => sub {
    plan tests => 6;
    my ($t) = started(seat => 'p1');
    is($t->describe({ kind => 'lead', card => id_of('AH') }, 'p1'), 'You led AH', 'your lead');
    is($t->describe({ kind => 'lead', card => id_of('AH') }, 'p2'), 'They led AH', 'and theirs');
    is($t->describe({ kind => 'marriage', suit => 'H' }, 'p1'),
       'You declared a marriage in H', 'a marriage');
    is($t->describe({ kind => 'exchange' }, 'p2'),
       'They exchanged for the trump card', 'an exchange');
    is($t->describe({ kind => 'close' }, 'p1'), 'You closed the talon', 'a close');
    is($t->describe({ kind => 'claim' }, 'p1'), 'You claimed 66', 'and a claim');
};

subtest 'it names every way a deal can end' => sub {
    plan tests => 7;
    my ($t) = started(seat => 'p1');
    my %line = map { $_ => $t->deal_result_line(
        { how => $_, winner => 'p1', game_points => 2, drawn => 0 }) }
        qw(claim closed_out false_claim beat_closer failed_close last_trick);

    like($line{claim}, qr/claiming 66/, 'a claim');
    like($line{closed_out}, qr/closed the talon/, 'a successful close');
    like($line{false_claim}, qr/claim was false/, 'a false claim');
    like($line{beat_closer}, qr/beating the closer/, 'beating a closer');
    like($line{failed_close}, qr/close failed/, 'a failed close');
    like($line{last_trick}, qr/last trick/, 'and the last trick');

    like($t->deal_result_line({ how => 'drawn', winner => undef,
                                game_points => 0, drawn => 1 }),
         qr/drawn.*Nobody scores/, 'and a drawn deal, which only sixtysix can produce');
};

subtest 'the match result reads correctly in both directions' => sub {
    # "You win the match, 0 to 1" is true of a countdown and reads like a loss.
    # So a countdown says what is still to find instead.
    plan tests => 4;

    my ($x, $xg) = started(variant => 'sixtysix', seat => 'p1');
    $xg->scores({ p1 => 7, p2 => 5 });
    $xg->result({ winner => 'p1', loser => 'p2', scores => $xg->scores, deals => 6 });
    like($x->result_line, qr/You win the match, 7 to 5/, 'a count up reads as a score');

    my ($s, $sg) = started(variant => 'schnapsen', seat => 'p1');
    $sg->scores({ p1 => 0, p2 => 3 });
    $sg->result({ winner => 'p1', loser => 'p2', scores => $sg->scores, deals => 5 });
    like($s->result_line, qr/You win the match over 5 deals/, 'a countdown reads as a win');
    like($s->result_line, qr/3 still to find against you/, 'and says how far behind they were');
    unlike($s->result_line, qr/0 to 3/, 'rather than a number that looks like a loss');
};

# ---- rendering does not need a game to be interesting ----------------------------------------

subtest 'render puts the screen together without printing it' => sub {
    plan tests => 3 * @VARIANTS;
    for my $v (@VARIANTS) {
        my ($t, $g) = started(variant => $v, tag => "render $v");
        my $lines = $t->render('p1');
        is(ref $lines, 'ARRAY', "$v: render returns lines");
        cmp_ok(scalar @$lines, '>', 8, "$v: " . scalar(@$lines) . ' of them');
        is(scalar(grep { !defined } @$lines), 0, "$v: and none of them is undef");
    }
};

# ---- the script, which EXE_FILES ships and nothing else here touches ------------------

subtest 'bin/schnapsen runs, and insists on a variant' => sub {
    # It is thin on purpose - Getopt::Long and a constructor, with no game logic
    # at all - but it is the file a player actually types, and it is installed.
    # Nothing else in this suite would notice if it stopped parsing.
    plan tests => 5;
    my $script = "$FindBin::Bin/../bin/schnapsen";
    my $lib    = "$FindBin::Bin/../lib";
    ok(-e $script, 'the script is where EXE_FILES says it is');

    my $help = `$^X -I$lib $script --help 2>&1`;
    like($help, qr/--variant schnapsen/, 'the usage names both games');

    my $none = `$^X -I$lib $script --mode watch 2>&1`;
    like($none, qr/--variant must be/, 'and it refuses to guess which one you meant');

    for my $v (variants()) {
        my $out = `$^X -I$lib $script --variant $v --mode watch --seed t --ascii --nocolour 2>&1`;
        like($out, qr/win(?:s)? the match/, "$v: a watched match plays to the end");
    }
};

done_testing();
