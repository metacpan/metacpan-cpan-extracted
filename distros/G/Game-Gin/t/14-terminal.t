#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Gin::Terminal;

# The terminal is tested with no terminal, which is the whole reason `in` and
# `out` are attributes. A user interface that can only be driven by a human is
# one that silently rots: nothing in the suite ever touches it, and it breaks
# the first time somebody changes the engine under it.

sub seed { return Digest::SHA::sha256("term:$_[0]") }

sub run {
    my (%o) = @_;
    my $input = $o{input} // '';
    open my $in,  '<', \$input      or die $!;
    open my $out, '>', \my $shown   or die $!;
    my $ui = Game::Gin::Terminal->new(
        in => $in, out => $out,
        mode  => $o{mode}  || 'watch',
        level => $o{level} || 2,
        seat  => $o{seat}  || 'p1',
    );
    my $game = $ui->play(seed => seed($o{n} // 1), limit => $o{limit} || 20_000);
    close $in; close $out;
    return ($ui, $game, $shown // '');
}

# ---- two bots, and a transcript ---------------------------------------------------

subtest 'a whole match can be watched with no terminal at all' => sub {
    plan tests => 6;
    my ($ui, $game, $shown) = run(mode => 'watch', n => 1);

    ok($game->over, 'the match finished');
    like($shown, qr/^deal 1, dealt by p1$/m, 'the transcript opens with the deal');
    like($shown, qr/discards \w\w/, 'and records discards');
    like($shown, qr/wins the hand by/, 'and who won each hand');
    like($shown, qr/wins: \d+ to \d+/, 'and the final score');
    cmp_ok(length $shown, '>', 500, 'there is a real transcript');
};

subtest 'nothing was written to the real STDOUT' => sub {
    plan tests => 1;
    # If `out` were ignored anywhere, this test would print the whole match
    # into the TAP stream and the harness would complain rather than pass.
    my (undef, undef, $shown) = run(mode => 'watch', n => 2);
    ok(length $shown, 'the transcript went to the handle it was given');
};

# ---- what a player is shown ----------------------------------------------------------

subtest 'a hand is shown grouped into its melds' => sub {
    plan tests => 5;
    open my $out, '>', \my $shown or die $!;
    my $ui = Game::Gin::Terminal->new(out => $out, mode => 'watch');
    $ui->game(Game::Gin->build(seed => seed('render'), dealer => 'p1'));

    my $lines = $ui->render('p2');
    like($lines->[0], qr/^deal 1, dealt by p1$/, 'the deal');
    like($lines->[1], qr/^score  p1 0   p2 0   \(to 100\)$/, 'the score and the target');
    ok(scalar(grep { /^stock 31 .*upcard \S+$/ } @$lines), 'the stock and the upcard');
    ok(scalar(grep { /loose \d+/ } @$lines), 'what is loose, and what it costs');
    ok(scalar(grep { /knock/ } @$lines), 'and how far off a knock it is');
};

# ---- the cards are drawn as cards --------------------------------------------------

subtest 'a hand is fanned, and every meld says what it is' => sub {
    plan tests => 9;
    open my $out, '>', \my $shown or die $!;
    my $ui = Game::Gin::Terminal->new(out => $out, mode => 'watch',
                                      ascii => 1, colour => 0);

    # 7H 7D 7C, 3S 4S 5S, and four loose: a set, a run, and the rest
    my $melding = Game::Gin::Deadwood::best([ 3, 4, 5, 20, 33, 46, 49, 26, 1, 28 ]);
    my @lines = $ui->hand_lines($melding);

    is(scalar @lines, 10, 'nine rows of card and the brackets under them');
    is(length $lines[0], $ui->fan_width(10),
       'ten cards fanned are the corners of nine and the whole of one');
    cmp_ok(length $lines[0], '<', 10 * 11,
           'which is narrower than ten cards drawn in full');

    # the corner is rank over suit, which is what makes a covered card
    # readable at all: four columns of it are drawn and no more
    like($lines[1], qr/\A\|7  \|7  \|7  \|3  /, 'each card shows its rank in the corner');
    like($lines[2], qr/\A\|H  \|D  \|C  \|S  /, 'and its suit under it');
    like($lines[7], qr/       10\|\z/, 'the last card is drawn whole, ten and all');

    like($lines[9], qr/set/,   'the three sevens are marked a set');
    like($lines[9], qr/run/,   'the three spades a run');
    like($lines[9], qr/loose \d+/, 'and what the rest of the hand costs');
};

subtest 'a card is drawn, named and typed' => sub {
    plan tests => 7;
    open my $out, '>', \my $shown or die $!;
    my $ui = Game::Gin::Terminal->new(out => $out, mode => 'watch',
                                      ascii => 1, colour => 0);

    my $art = $ui->card_art(26);            # the king of hearts
    is(scalar @$art, 9, 'a card is nine rows');
    is(length $art->[0], 11, 'and eleven columns');
    like($art->[1], qr/\|K        \|/, 'the rank in one corner');
    like($art->[7], qr/\|        K\|/, 'and in the other');

    # what is drawn can be typed back, and so can what the engine spells
    is($ui->card_named('KH'), 26, 'the engine spelling');
    is($ui->card_named('10c'), 49, 'the ten the card corner shows');
    is($ui->card_named('zz'), undef, 'and a word is not a card');
};

subtest 'without ascii the suits are the pips themselves' => sub {
    plan tests => 2;
    open my $out, '>', \my $shown or die $!;
    my $ui = Game::Gin::Terminal->new(out => $out, mode => 'watch', colour => 0);
    my $art = join "\n", @{ $ui->card_art(26) };
    like($art, qr/[^\x00-\x7f]/, 'the card is drawn with real pips');
    is($ui->card_named("K\x{2665}"), 26, 'and the pip can be typed back');
};

# ---- a person at the keyboard ----------------------------------------------------------

subtest 'a person can play, and the prompts accept what they are told to' => sub {
    plan tests => 4;
    # THE HUMAN IS p2, THE NON-DEALER, and that is the point of the seat.
    # Only the non-dealer is asked about the opening upcard, so a human in p1
    # never sees that prompt at all: the bot takes or refuses it first. The
    # first version of this asserted the upcard prompt with the human dealing,
    # and failed against perfectly correct code.
    my ($ui, $game, $shown) = run(mode => 'bot', seat => 'p2', n => 3,
                                  input => join("\n", ('n') x 40) . "\n");
    like($shown, qr/take the \S+\? \(y\/n\)/, 'the non-dealer is offered the upcard');
    like($shown, qr/\(d\)raw or \(t\)ake \S+\?/, 'and a draw on later turns');
    like($shown, qr/loose \d+/, 'the hand was drawn before each decision');
    ok(length $shown > 200, 'and a real transcript came back');
};

subtest 'a bad card is refused and asked again, not accepted' => sub {
    plan tests => 2;
    open my $in,  '<', \(my $script = "zz\n") or die $!;
    open my $out, '>', \my $shown or die $!;
    my $ui = Game::Gin::Terminal->new(in => $in, out => $out, mode => 'hotseat');
    $ui->game(Game::Gin->build(seed => seed('bad'), dealer => 'p1'));
    # Drive it into a discard so the card prompt is the live one.
    $ui->game->apply('p2', { kind => 'take' });

    my $move = $ui->human_move('p2');
    is($move, undef, 'input ran out rather than a bad card being accepted');
    like($shown, qr/not a card/, 'and it said so');
};

subtest 'input running out stops the game rather than looping' => sub {
    plan tests => 2;
    my ($ui, $game, $shown) = run(mode => 'hotseat', n => 4, input => '');
    ok(!$game->over, 'the match did not finish');
    like($shown, qr/unfinished/, 'and it said so rather than spinning');
};

done_testing();
