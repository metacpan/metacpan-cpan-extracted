use strict;
use warnings;
use Test::More;

use Game::RoyalUr;
use Game::RoyalUr::Bot;

my $G = 'Game::RoyalUr';

sub moves_of { join ' ', map { $_->from . '-' . $_->to } $_[0]->legal }

sub dice_of {
    my ($game) = @_;
    return join ',', $game->rolls, ($game->roll // '-'), ($game->throw ? join('', @{ $game->throw }) : '-');
}

sub bot_line {
    my ($game, $level) = @_;
    my $bot = Game::RoyalUr::Bot->new(level => $level);
    my @line;
    for (1 .. 3) {
        last if $game->is_over;
        my $move = $bot->choose($game);
        push @line, $game->side . ' ' . $game->roll . ' ' . $move->from . '-' . $move->to;
        $game->play_or_die($move);
    }
    return join ' | ', @line, $game->to_text;
}

sub round_trip {
    my ($game, $name) = @_;
    subtest $name => sub {
        my $text = $game->to_text;
        ok(defined $text && !ref $text, 'the text is a string');
        my $again = $G->from_text($text);
        isnt($again, $game, 'a new game');
        is($again->to_text, $text, 'which writes the same text');
        is($again->position, $game->position, 'the same position');
        is($again->side, $game->side, 'the same side to move');
        is(dice_of($again), dice_of($game), 'the same roll waiting, from the same throw');
        is(moves_of($again), moves_of($game), 'the same moves');
        is($again->is_over ? 1 : 0, $game->is_over ? 1 : 0, 'over or not alike');
        if ($game->is_over) {
            is($again->result->winner // 'draw', $game->result->winner // 'draw', 'the same winner');
            is($again->result->how, $game->result->how, 'the same way');
        }
        else {
            my ($one, $two) = ($G->from_text($text), $G->from_text($text));
            is(bot_line($two, 2), bot_line($one, 2), 'the next three bot moves, and the dice they fall to, are the same');
            my $mine = $G->from_text($text);
            my $before = $game->to_text;
            $mine->play_or_die(($mine->legal)[0]);
            is($game->to_text, $before, 'playing on the copy leaves the original alone');
            my $copy = $G->from_text($text);
            my $orig = $G->from_text($text);
            my (@a, @b);
            for (1 .. 6) {
                last if $copy->is_over;
                $copy->play_or_die(($copy->legal)[0]);
                $orig->play_or_die(($orig->legal)[0]);
                push @a, dice_of($copy);
                push @b, dice_of($orig);
            }
            is("@a", "@b", 'the dice to come are the same');
        }
    };
}

sub find {
    my ($seed, $rules, $want) = @_;
    my $game = $G->new(seed => $seed, rules => $rules);
    my $n = 0;
    until ($game->is_over) {
        my @moves = $game->legal;
        my $move = $moves[ $n++ % @moves ];
        $game->play_or_die($move);
        return $game if $want->($move, $game);
    }
    return $game;
}

for my $rules ('finkel', 'masters') {
    my $start = $G->new(seed => "round trip $rules", rules => $rules);
    round_trip($start, "$rules: at the start, a roll thrown and not yet played");

    my $three = $G->new(seed => "round trip $rules", rules => $rules);
    $three->play_or_die(($three->legal)[0]) for 1 .. 3;
    round_trip($three, "$rules: after three moves");

    my $capture = find("capture $rules", $rules, sub { $_[0]->captures });
    ok(!$capture->is_over && $capture->log->[-1]{captures}, "$rules: a capture was found");
    round_trip($capture, "$rules: after a capture");

    my $rosette = find("rosette $rules", $rules, sub { $_[0]->rosette });
    ok(!$rosette->is_over && $rosette->log->[-1]{rosette}, "$rules: a rosette was found");
    round_trip($rosette, "$rules: after a rosette, the same side to throw again");

    my $forfeit = find("forfeit $rules", $rules, sub { $_[1]->forfeits_since($_[1]->ply - 1) });
    round_trip($forfeit, "$rules: after a turn lost to the roll");

    my $late = $G->new(seed => "late $rules", rules => $rules);
    my $bot = Game::RoyalUr::Bot->new(level => 1);
    my @texts;
    until ($late->is_over) {
        push @texts, $late->to_text;
        $late->play_or_die($bot->choose($late));
    }
    round_trip($G->from_text($texts[-3]), "$rules: late in a game the bot played out");
    round_trip($late, "$rules: at the end of that game");

    my $resigned = $G->new(seed => "resign $rules", rules => $rules);
    $resigned->play_or_die(($resigned->legal)[0]) for 1 .. 5;
    $resigned->resign('dark');
    round_trip($resigned, "$rules: after a resignation");
}

my $told = $G->new(seed => 'told', first => 'dark');
$told->play_or_die(($told->legal)[0]) for 1 .. 2;
round_trip($told, 'a game told who moves first');

my $from = $G->new(seed => 'from a position', position => '4xx2/8/4xx2 l 7 0 7 0', first => 'dark');
$from->play_or_die(($from->legal)[0]);
like($from->to_text, qr/^\[position 4xx2\/8\/4xx2 l 7 0 7 0\]$/m, 'a game from a position writes it');
round_trip($from, 'a game from a position');

my $later = $G->new(seed => 'from later', position => '1dddxx2/8/lll1xx2 d 4 0 4 0');
$later->play_or_die(($later->legal)[0]) for 1 .. 2;
round_trip($later, 'a game from a position with pieces on the board');

subtest 'a malformed text is refused with a sentence' => sub {
    my $text = $told->to_text;
    for my $case (
        [ undef,                                         qr/wants the text to_text wrote, and was given nothing/ ],
        [ [],                                            qr/given a reference/ ],
        [ '',                                            qr/refused: the record does not agree.*\(empty\)/ ],
        [ "nonsense\n",                                  qr/refused at line 1: .*\(rules\)/ ],
        [ $text =~ s/\n\z//r,                            qr/\(no_newline\)/ ],
        [ $text =~ s/^1\. d/1. l/mr,                     qr/refused at line \d+: .*\(side\)/ ],
        [ $text =~ s/\[seed [0-9a-f]+\]/[seed 00]/r,     qr/refused at line \d+/ ],
        [ $text =~ s/^\[first (\w+)\]\n/[first $1]\n[position 9]\n/mr, qr/\(position\)/ ],
    ) {
        my ($bad, $like) = @$case;
        my $game = eval { $G->from_text($bad) };
        ok(!$game, 'refused');
        like($@, qr/\AGame::RoyalUr: /, 'by the game');
        like($@, $like, 'saying why');
    }
};

done_testing;
