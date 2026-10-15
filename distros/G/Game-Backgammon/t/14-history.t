#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Backgammon;
use Game::Backgammon::Terminal;

sub seed_of { Digest::SHA::sha256($_[0]) }

sub picker {
    my (%o) = @_;
    my @keys;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    my $ui = Game::Backgammon::Terminal->new(
        game => Game::Backgammon->new(seed => seed_of($o{seed} || 'again')),
        out => $fh,
        mode => $o{mode} || 'bot',
        seat => 'white',
        level => 1,
        ascii => 1,
        colour => 0,
        interactive => 0,
        picking => 1,
        keysource => $o{keysource} || sub { shift @keys },
    );
    $ui->_enter_raw;
    $ui->history->start($ui->game);
    return ($ui, \@keys, \$out);
}

sub press {
    my ($ui, $keys, $press) = @_;
    @$keys = split //, $press;
    my $on = $ui->step;
    @$keys = ();
    return $on;
}

sub to_white {
    my ($ui) = @_;
    $ui->step while $ui->game->status eq 'active' && $ui->game->turn ne 'white';
    return $ui->game->to_text;
}

sub typed {
    my ($input) = @_;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    open my $in, '<', \$input or die $!;
    my $ui = Game::Backgammon::Terminal->new(
        game => Game::Backgammon->new(seed => seed_of('again')),
        out => $fh, in => $in, mode => 'bot', seat => 'white', level => 1,
        picking => 0,
    );
    $ui->start;
    close $fh;
    return ($ui, $out);
}

subtest 'u takes back a turn and the reply, r plays them again' => sub {
    plan tests => 9;
    my ($ui, $keys, $out) = picker();
    my $first = to_white($ui);
    my $dice = $ui->game->dice;
    press($ui, $keys, "\r" x 4);
    my $second = to_white($ui);
    isnt($second, $first, 'a turn and the reply were played');

    ok(press($ui, $keys, 'u'), 'the game goes on after u');
    is($ui->game->to_text, $first, 'u goes back to the earlier turn');
    is(scalar @{ $ui->game->history }, scalar @{ Game::Backgammon->from_text($first)->history },
        'and the reply is gone with it');
    is_deeply($ui->game->dice, $dice, 'with the dice thrown then');
    is_deeply([$ui->log->lines], ['Taken back.'], 'and a note saying so');

    ok(press($ui, $keys, 'r'), 'the game goes on after r');
    is($ui->game->to_text, $second, 'r plays them again');
    is_deeply([$ui->log->lines], ['Played again.'], 'and a note saying so');
};

subtest 'a new turn after u empties redo' => sub {
    plan tests => 4;
    my ($ui, $keys, $out) = picker();
    to_white($ui);
    press($ui, $keys, "\r" x 4);
    to_white($ui);
    press($ui, $keys, 'u');
    ok($ui->history->can_redo, 'there is a turn to play again');
    press($ui, $keys, "j\r\r\r\r");
    my $now = to_white($ui);
    press($ui, $keys, 'r');
    ok(!$ui->history->can_redo, 'and none once another turn is played');
    is($ui->game->to_text, $now, 'r then changes nothing');
    like($$out, qr/There is nothing to play again\./, 'and says so');
};

subtest 'u at the start notes and changes nothing' => sub {
    plan tests => 3;
    my ($ui, $keys, $out) = picker();
    my $first = to_white($ui);
    ok(!press($ui, $keys, 'uq'), 'q still stops');
    is($ui->game->to_text, $first, 'the game is as it was');
    like($$out, qr/There is nothing to take back\./, 'and a note said why');
};

subtest 'u in a turn being built drops it' => sub {
    plan tests => 3;
    my ($ui, $keys, $out) = picker();
    my $first = to_white($ui);
    press($ui, $keys, "\r" x 4);
    to_white($ui);
    ok(press($ui, $keys, "\ru"), 'one move chosen, then u');
    is($ui->game->to_text, $first, 'the whole earlier turn is taken back');
    is_deeply([$ui->log->lines], ['Taken back.', 'The moves chosen this turn were dropped.'],
        'and the note says the moves chosen were dropped');
};

subtest 'in hotseat every turn is a step' => sub {
    plan tests => 4;
    my ($ui, $keys) = picker(mode => 'hotseat');
    my @text = ($ui->game->to_text);
    for (1 .. 2) {
        press($ui, $keys, "\r" x 4);
        push @text, $ui->game->to_text;
    }
    isnt($text[1], $text[0], 'two turns were played');
    press($ui, $keys, 'u');
    is($ui->game->to_text, $text[1], 'u takes back one of them');
    press($ui, $keys, 'u');
    is($ui->game->to_text, $text[0], 'and u again the other');
    press($ui, $keys, 'r');
    is($ui->game->to_text, $text[1], 'r plays one again');
};

subtest 'undo and redo typed' => sub {
    plan tests => 5;
    my ($played) = typed("1\nq\n");
    my ($start) = typed("q\n");
    my ($ui, $out) = typed("1\nundo\nq\n");
    is($ui->game->to_text, $start->game->to_text, 'undo takes back the turn and the reply');
    like($out, qr/Taken back\./, 'and says so');
    ($ui, $out) = typed("1\nundo\nredo\nq\n");
    is($ui->game->to_text, $played->game->to_text, 'redo plays them again');
    like($out, qr/Played again\./, 'and says so');
    ($ui, $out) = typed("undo\nq\n");
    like($out, qr/There is nothing to take back\./, 'undo with nothing to take back says so');
};

subtest 'a finished game takes its last turn back' => sub {
    plan tests => 3;
    my ($ui) = picker(keysource => sub { "\r" });
    $ui->start;
    is($ui->game->status, 'finished', 'the game was played to the end');
    my $turns = @{ $ui->game->history };
    ok($ui->take_back, 'u at the end takes something back');
    cmp_ok(scalar @{ $ui->game->history }, '<', $turns, 'and the game is before its end');
};

subtest 'with nobody at the keys there is nothing to take back' => sub {
    plan tests => 2;
    my ($ui) = picker(mode => 'watch');
    $ui->start;
    my $text = $ui->game->to_text;
    ok(!$ui->take_back, 'nothing is taken back');
    is($ui->game->to_text, $text, 'and the game is as it was');
};

done_testing;
