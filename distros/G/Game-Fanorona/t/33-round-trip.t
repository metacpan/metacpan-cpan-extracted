use strict;
use warnings;
use Test::More;

use Game::Fanorona;
use Game::Fanorona::Bot;

my $G = 'Game::Fanorona';
my $B = 'Game::Fanorona::Bot';
my $SEED = 't/33-round-trip.t';
my $LEVEL = 2_000;

sub save { $_[0]->as_text }

sub load {
    my ($text) = @_;
    my ($game, $why, $line) = $G->from_text($text);
    die "the text was refused: $why at line $line" unless $game;
    return $game;
}

sub bot_moves {
    my ($game, $n) = @_;
    my @moves;
    for (1 .. $n) {
        my $thought = $B->play($game, level => $LEVEL, seed => $SEED);
        push @moves, $thought ? $thought->{move} : undef;
        last unless $thought;
    }
    return \@moves;
}

sub legal_of { join ' ', $_[0]->over ? () : $_[0]->legal_strings }

sub steps_of { join ' ', map { $_->{string} } $_[0]->steps }

sub round_trip {
    my ($g, $name) = @_;
    subtest $name => sub {
        my $text = save($g);
        ok(defined $text && !ref $text, 'the text is a plain string');
        my $again = load($text);
        is(save($again), $text, 'save(load(save)) is save');
        is(legal_of($again), legal_of($g), 'the same legal moves');
        is(steps_of($again), steps_of($g), 'the same steps');
        is($again->turn, $g->turn, 'the same turn');
        is($again->in_progress, $g->in_progress, 'the same move half made');
        is($again->draw_offered_by, $g->draw_offered_by, 'the same offer');
        is($again->position_counted, $g->position_counted, 'the same position and counts');
        is($again->repeats, $g->repeats, 'the same count of repeats');
        is_deeply([ $again->moves ], [ $g->moves ], 'the same moves');
        my $theirs = bot_moves($again, 3);
        is(save($g), $text, 'playing on the rebuilt game leaves the original alone');
        is_deeply(bot_moves($g, 3), $theirs, 'the next three bot moves are the same');
    };
}

round_trip($G->new, 'at the start');

my $three = $G->new;
bot_moves($three, 3);
round_trip($three, 'after three moves');

my $capture = $G->new;
bot_moves($capture, 1);
cmp_ok($capture->stones('black'), '<', 22, 'the first move captures');
round_trip($capture, 'after a capture');

my $chain = $G->new;
my $first;
for (1 .. 60) {
    last if $chain->over;
    my ($long) = grep { tr/-// >= 2 } $chain->legal_strings;
    if ($long) {
        ($first) = $long =~ /\A([a-z][0-9]+-[a-z][0-9]+[AW]?)/;
        last;
    }
    bot_moves($chain, 1);
}
ok($first, "a move of more than one step, begun with $first");
$chain->step($first) or die $chain->error->message;
ok($chain->in_chain, 'leaves a move half made');
like(save($chain), qr/^chain \Q$first\E$/m, 'which is written');
round_trip($chain, 'with a move half made');

my $offer = $G->new;
bot_moves($offer, 3);
$offer->offer_draw('white');
like(save($offer), qr/^offer white$/m, 'a standing offer is written');
round_trip($offer, 'with a draw offer standing');
{
    $offer = $G->new;
    bot_moves($offer, 3);
    $offer->offer_draw('white');
    my $again = load(save($offer));
    ok($again->accept_draw('black'), 'the offer on the rebuilt game can be accepted');
    is($again->result->how, 'agreement', 'and ends it');
}

my $end = $G->new;
bot_moves($end, 500);
ok($end->over, 'a game played out by the bot ends, ' . $end->result->how);
round_trip($end, 'at the end of a game played out');

my $resigned = $G->new;
bot_moves($resigned, 3);
$resigned->offer_draw('black');
$resigned->resign('black');
round_trip($resigned, 'after a resignation');
{
    my $again = load(save($resigned));
    ok($again->over, 'a game saved after a resignation loads over');
    is($again->result->how, 'resign', 'by resignation');
    is($again->winner, 'white', 'with the same winner');
    is($again->ply, $resigned->ply, 'and the moves still played');
}

my $mid = $G->new;
bot_moves($mid, 4);
my ($long) = grep { tr/-// >= 2 } $mid->legal_strings;
SKIP: {
    skip 'no move of two steps here', 1 unless $long;
    my ($step) = $long =~ /\A([a-z][0-9]+-[a-z][0-9]+[AW]?)/;
    $mid->step($step) or die $mid->error->message;
    $mid->resign($mid->turn) if $mid->in_chain;
    round_trip($mid, 'after a resignation in the middle of a move');
}

my $agreed = $G->new;
bot_moves($agreed, 4);
$agreed->offer_draw('white');
$agreed->accept_draw('black');
round_trip($agreed, 'after an agreed draw');
is(load(save($agreed))->result->how, 'agreement', 'an agreed draw loads ended by agreement');

subtest 'a text written before the offer and chain lines still loads' => sub {
    my $again = load("fanorona 1\nresult resign black\nmoves\nd3-e3A\n");
    ok($again->over, 'over');
    is($again->result->how, 'resign', 'by resignation');
    is($again->winner, 'black', 'won by black');
};

subtest 'text that is not a game is refused' => sub {
    my @bad = (
        [ "fanorona 1\noffer red\nmoves\n",                         'bad_offer',  2 ],
        [ "fanorona 1\nresult agreement\noffer white\nmoves\n",     'bad_offer',  3 ],
        [ "fanorona 1\nchain d3-e3A\nmoves\n",                      'bad_chain',  2 ],
        [ "fanorona 1\nchain d3-e9A\nmoves\n",                      'off_board',  2 ],
        [ "fanorona 1\nresult resign\nmoves\n",                     'bad_result', 2 ],
        [ "fanorona 1\nresult stones white\nmoves\nd3-e3A\n",       'bad_result', 2 ],
        [ "fanorona 1\noffer white\nmoves\nd3-e3A\n",               undef,        undef ],
    );
    for my $case (@bad) {
        my ($text, $code, $at) = @$case;
        (my $shown = $text) =~ s/\n/\\n/g;
        my ($game, $why, $line) = $G->from_text($text);
        if (!defined $code) {
            ok($game, "'$shown': a game");
            next;
        }
        is($game, undef, "'$shown': no game");
        is($why, $code, "because $code");
        is($line, $at, "at line $at");
    }
};

done_testing();
