use strict;
use warnings;
use Test::More;

use Game::Brandubh;
use Game::Brandubh::Bot;
use Digest::SHA qw(sha256);

my $G = 'Game::Brandubh';
my $B = 'Game::Brandubh::Bot';
my $SEED = sha256('t/27-round-trip.t');

sub save { $_[0]->as_text }

sub load {
    my ($text) = @_;
    my ($game, $refused) = $G->from_text($text, seed => $SEED);
    die 'the text was refused: ' . ($refused ? $refused->code : 'no game') if !$game || $refused;
    return $game;
}

sub bot_moves {
    my ($game, $n) = @_;
    my @moves;
    for (1 .. $n) {
        my $move = $B->choose($game, seed => $SEED, level => 1_000);
        push @moves, $move;
        last unless defined $move;
        $game->play_or_die($move);
    }
    return \@moves;
}

sub legal_of { join ' ', sort map { $_->{move} } @{ $_[0]->legal } }

sub round_trip {
    my ($g, $name) = @_;
    subtest $name => sub {
        my $text = save($g);
        ok(defined $text && !ref $text, 'the text is a plain string');
        my $again = load($text);
        is(save($again), $text, 'save(load(save)) is save');
        is(legal_of($again), legal_of($g), 'the same legal moves');
        is($again->status, $g->status, 'the same status');
        is($again->turn, $g->turn, 'the same turn');
        is($again->draw_offered_by, $g->draw_offered_by, 'the same offer');
        is($again->repeats, $g->repeats, 'the same count of repeats');
        is_deeply($again->shown, $g->shown, 'the same moves as shown');
        my $theirs = bot_moves($again, 3);
        is(save($g), $text, 'playing on the rebuilt game leaves the original alone');
        is_deeply(bot_moves($g, 3), $theirs, 'the next three bot moves are the same');
    };
}

my $start = $G->new(seed => $SEED);
round_trip($start, 'at the start');

my $three = $G->new(seed => $SEED);
bot_moves($three, 3);
round_trip($three, 'after three moves');

my $capture = $G->new(seed => $SEED);
for (1 .. 200) {
    bot_moves($capture, 1);
    last if $capture->status ne 'active' || $capture->shown->[-1] =~ /x/;
}
like($capture->shown->[-1], qr/x/, 'a game reaches a capture');
round_trip($capture, 'after a capture');

my $offer = $G->new(seed => $SEED);
bot_moves($offer, 3);
$offer->offer_draw('p1');
like(save($offer), qr/^offer p1$/m, 'a waiting offer is written');
round_trip($offer, 'with a draw offer waiting');
{
    $offer = $G->new(seed => $SEED);
    bot_moves($offer, 3);
    $offer->offer_draw('p1');
    my $again = load(save($offer));
    is($again->accept_draw('p2'), 0, 'the offer on the rebuilt game can be accepted');
    is($again->result->how, 'agreed', 'and ends it');
}

my $p2 = $G->new(attackers => 'p2', seed => $SEED);
bot_moves($p2, 3);
like(save($p2), qr/^attackers p2$/m, 'the seat with the attackers is written when it is p2');
is(load(save($p2))->attackers, 'p2', 'and read back');
round_trip($p2, 'with the attackers at p2');

my $end = $G->new(seed => $SEED, variant => { ply_cap => 160 });
bot_moves($end, 400);
is($end->status, 'finished', 'a game played out by the bot ends');
round_trip($end, 'at the end of a game played out');

my $resigned = $G->new(seed => $SEED);
bot_moves($resigned, 3);
$resigned->offer_draw('p2');
$resigned->resign('p2');
round_trip($resigned, 'after a resignation');
{
    my $again = load(save($resigned));
    is($again->status, 'finished', 'a game saved after a resignation loads ended');
    is($again->result->how, 'resign', 'by resignation');
    is($again->winner, 'p1', 'with the same winner');
    ok($again->undo, 'undo on it takes back the resignation');
    is($again->status, 'active', 'and the game is active again');
    is($again->ply, 3, 'with the moves still played');
}

my $agreed = $G->new(seed => $SEED);
bot_moves($agreed, 4);
$agreed->offer_draw('p1');
$agreed->accept_draw('p2');
round_trip($agreed, 'after an agreed draw');
is(load(save($agreed))->result->how, 'agreed', 'an agreed draw loads ended by agreement');

subtest 'the old form, with no attackers or offer line, still loads' => sub {
    my $again = load("variant brandubh\nmoves d1c1\nresult resign defenders\n");
    is($again->result->how, 'resign', 'ended by resignation');
    is($again->attackers, 'p1', 'the attackers at p1');
};

subtest 'text that is not a game is refused' => sub {
    for my $bad ("variant brandubh\nattackers p3\nmoves\n",
                 "variant brandubh\nmoves d1c1\noffer nobody\n",
                 "variant brandubh\nmoves d1c1\nresult agreed\noffer p1\n",
                 "variant brandubh\nmoves\noffer p1\noffer p2\n") {
        (my $shown = $bad) =~ s/\n/\\n/g;
        my ($game, $refused) = $G->from_text($bad);
        ok(!$game && $refused, "'$shown': no game");
        like($refused && $refused->message, qr/\w+ \w+/, 'and a refusal that says why in a sentence');
    }
};

done_testing();
