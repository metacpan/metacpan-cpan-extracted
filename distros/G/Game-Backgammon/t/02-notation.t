#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Backgammon::Notation qw(parse_turn print_turn);

# Notation in and out. The round trip is the assertion: a line a player
# writes must come back as the same line, or the log will not read as the
# game that was played.

subtest 'the lines a player writes' => sub {
    my @exact = ('8/5 6/5', '24/23 13/11', 'bar/20', '6/off', '13/11*',
                 '8/5(2)', 'bar/20(2)', '6/off(3)', '13/11* 8/5');
    plan tests => scalar @exact;
    for my $line (@exact) {
        my $t = parse_turn($line, player => 'white');
        is(print_turn($t), $line, "'$line' round-trips exactly");
    }
};

subtest 'one checker moved twice' => sub {
    plan tests => 2;
    my $t = parse_turn('13/7/5', player => 'white');
    is(scalar @{ $t->moves }, 2, '13/7/5 is two moves');
    is(print_turn($t), '13/7 7/5', 'and prints as the two it is');
};

subtest 'no play' => sub {
    plan tests => 3;
    for my $line ('', '(no play)') {
        my $t = parse_turn($line, player => 'white');
        ok($t && $t->is_forfeit, "'$line' is a forfeit turn, not an error");
    }
    is(print_turn(parse_turn('', player => 'white')), '(no play)',
       'and prints as one');
};

subtest 'what is refused, and why' => sub {
    my %bad = (
        '5/8'      => qr/backwards/,
        'off/5'    => qr/off the board/,
        '5/bar'    => qr/onto the bar/,
        'nonsense' => qr/not a move/,
        '25/20'    => qr/not a point/,
        '8/5(9)'   => qr/not 1 to 4/,
        '8/5(0)'   => qr/not 1 to 4/,
    );
    plan tests => 2 * scalar keys %bad;
    for my $line (sort keys %bad) {
        my $t = parse_turn($line, player => 'white');
        is($t, undef, "'$line' is refused");
        like($@, $bad{$line}, 'with a reason that says which rule');
    }
};

subtest 'the die a move spent' => sub {
    plan tests => 3;
    my $plain = parse_turn('8/5', player => 'white');
    is($plain->moves->[0]->die, 3, 'a point-to-point move knows its die');

    # entering and bearing off depend on the position, so the parser leaves
    # them undef rather than guessing: the rules fill them in
    my $enter = parse_turn('bar/20', player => 'white');
    is($enter->moves->[0]->die, undef, 'entering does not, because the position decides');
    my $off = parse_turn('6/off', player => 'white');
    is($off->moves->[0]->die, undef, 'and neither does bearing off');
};

subtest 'two orders of the same moves are one turn' => sub {
    plan tests => 2;
    my $a = parse_turn('8/5 6/5', player => 'white');
    my $b = parse_turn('6/5 8/5', player => 'white');
    is($a->key, $b->key, 'the key ignores order, so they compare equal');
    isnt(print_turn($a), print_turn($b), 'though they still print as written');
};

done_testing();
