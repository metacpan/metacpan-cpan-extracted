use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;

use Game::RoyalUr::Engine ':all';
my $E = 'Game::RoyalUr::Engine';

sub board {
    my ($position) = @_;
    my ($bd, $err) = $E->of_string($position);
    die "'$position' was refused, code $err" unless $bd;
    return $bd;
}

# The move a roll allows whose piece starts on a named place.
sub move_from {
    my ($bd, $roll, $from, $rules) = @_;
    my ($move) = grep { $_->from eq $from } $bd->moves($roll, $rules);
    die "no move from $from on a roll of $roll" unless $move;
    return $move;
}

# Everything a position is, the parts the key leaves out included.
sub everything {
    my ($bd) = @_;
    return join ' | ', $bd->to_string, $bd->key_hex, $bd->ply;
}

# THE SIX ROWS OF "WHOSE TURN IS IT AFTERWARDS". Each from a position written
# for it, with the whole position expected afterwards typed out.
subtest 'a move to an ordinary square passes the turn' => sub {
    my $bd = board('4xx2/8/4xx2 l 7 0 7 0');
    ok(defined $bd->apply(move_from($bd, 2, 'hand')), 'the move is made');
    is($bd->to_string, '4xx2/8/2l1xx2 d 6 0 7 0', 'a piece on c1, one fewer in hand, DARK to move');
    is($bd->ply, 1, 'and one ply made');
};

subtest 'a move to a rosette keeps the turn' => sub {
    my $bd = board('4xx2/8/4xx2 l 7 0 7 0');
    $bd->apply(move_from($bd, 4, 'hand'));
    is($bd->to_string, '4xx2/8/l3xx2 l 6 0 7 0', 'a piece on a1, and LIGHT to move again');
    is($bd->ply, 1, 'which is still a ply');
};

subtest 'a capture on an ordinary square passes the turn, and the piece goes to its owner hand' => sub {
    my $bd = board('4xx2/l1d5/4xx2 l 6 0 5 1');
    $bd->apply(move_from($bd, 2, 'a2'));
    is($bd->to_string, '4xx2/2l5/4xx2 d 6 0 6 1',
        'light on c2; dark hand 5 to 6; dark home STILL 1; light hand STILL 6; dark to move');
    is($bd->count(SIDE_DARK), 0, 'and no dark piece is on the board');
    ok($bd->consistent(7), 'seven a side, all accounted for');
};

subtest 'a capture on a rosette keeps the turn' => sub {
    my $far = board('4xxd1/6l1/4xx2 l 6 0 6 0');
    $far->apply(move_from($far, 1, 'g2', 'masters'), 'masters');
    is($far->to_string, '4xxl1/8/4xx2 l 6 0 7 0', 'masters: light takes g3 and moves AGAIN');

    my $mid = board('4xx2/l2d4/4xx2 l 6 0 6 0');
    $mid->apply(move_from($mid, 3, 'a2', { safe_rosettes => 0 }), { safe_rosettes => 0 });
    is($mid->to_string, '4xx2/3l4/4xx2 l 6 0 7 0', 'short route with safety off: the same on d2');
};

subtest 'a move home passes the turn, though the piece left from a rosette' => sub {
    my $bd = board('4xx2/8/4xxl1 l 3 3 7 0');
    $bd->apply(move_from($bd, 1, 'g1'));
    is($bd->to_string, '4xx2/8/4xx2 d 3 4 7 0', 'home 3 to 4, the board empty, DARK to move');
};

subtest 'a forfeit passes the turn, always' => sub {
    my $bd = board('4xx2/8/l3xx2 l 6 0 7 0');
    my $undo = $bd->forfeit;
    is($bd->to_string, '4xx2/8/l3xx2 d 6 0 7 0', 'nothing moves and dark is to move');
    is($bd->ply, 1, 'and it is a ply');
    $bd->forfeit;
    is($bd->side, SIDE_LIGHT, 'and back again');
    is($bd->ply, 2, 'two plies');
};

subtest 'unapply puts back exactly what apply took' => sub {
    my @cases = (
        [ '4xx2/8/4xx2 l 7 0 7 0',      4, 'hand', undef,     'entering on a rosette' ],
        [ '4xx2/l1d5/4xx2 l 6 0 5 1',   2, 'a2',   undef,     'a capture' ],
        [ '4xxd1/6l1/4xx2 l 6 0 6 0',   1, 'g2',   'masters', 'a capture on a rosette' ],
        [ '4xx2/8/4xxl1 l 3 3 7 0',     1, 'g1',   undef,     'going home' ],
        [ '1d2xx2/3l4/4xx2 d 6 0 6 0',  2, 'b3',   undef,     'a dark move' ],
    );
    for my $case (@cases) {
        my ($position, $roll, $from, $rules, $what) = @$case;
        my $bd = board($position);
        $bd->set_ply(17);
        my $before = everything($bd);
        my $undo = $bd->apply(move_from($bd, $roll, $from, $rules), $rules);
        isnt(everything($bd), $before, "$what: the move changed something");
        is($bd->unapply($undo), $bd, 'unapply returns the board');
        is(everything($bd), $before, 'and it is all back: cells, hands, homes, side, ply');
    }
    my $bd = board('4xx2/8/l3xx2 l 6 0 7 0');
    my $before = everything($bd);
    $bd->unapply($bd->forfeit);
    is(everything($bd), $before, 'a forfeit taken back');
};

# The hands are not in the key, so a key alone would not notice a hand that
# was not put back. The string is compared as well, every time.
subtest 'five thousand random moves a rule set, each made, taken back and made again' => sub {
    for my $rules ('finkel', 'masters') {
        srand(20261009);
        my $spelled = $E->rules($rules);
        my @rolls = map { $_->[0] } $E->chances($spelled->{dice}, $spelled->{zero_rolls});
        my ($made, $captures, $rosettes, $homes, $forfeits, @bad) = (0) x 5;
        while ($made < 5_000) {
            my $bd = $E->new;
            while ($bd->status($rules) == ONGOING && $made < 5_000) {
                my $roll = $rolls[ rand @rolls ];
                my @moves = $bd->moves($roll, $rules);
                my $before = everything($bd);
                if (!@moves) {
                    my $undo = $bd->forfeit;
                    $bd->unapply($undo);
                    push @bad, "a forfeit did not come back from $before" unless everything($bd) eq $before;
                    $bd->forfeit;
                    $forfeits++;
                    next;
                }
                my $move = $moves[ rand @moves ];
                my $undo = $bd->apply($move, $rules);
                push @bad, "$before: " . $move->trace . ' was not made' unless defined $undo;
                my $after = everything($bd);
                $bd->unapply($undo);
                push @bad, "$before: " . $move->trace . ' did not come back' unless everything($bd) eq $before;
                $bd->apply($move, $rules);
                push @bad, "$before: " . $move->trace . ' was different the second time' unless everything($bd) eq $after;
                push @bad, "$after is not consistent" unless $bd->consistent(7);
                $made++;
                $captures++ if $move->captures;
                $rosettes++ if $move->rosette;
                $homes++    if $move->home;
            }
        }
        is(scalar @bad, 0, "$rules: every one") or diag(join "\n", @bad[0 .. ($#bad > 4 ? 4 : $#bad)]);
        cmp_ok($captures, '>', 100, "$rules: $captures of them captures");
        cmp_ok($rosettes, '>', 300, "$rules: $rosettes onto a rosette");
        cmp_ok($homes,    '>', 100, "$rules: $homes home");
        cmp_ok($forfeits, '>', ($rules eq 'finkel' ? 100 : 5), "$rules: and $forfeits forfeits between them");
    }
};

subtest 'apply asks that the piece is there, and nothing else' => sub {
    my $bd = board('4xx2/8/4xx2 l 7 0 7 0');
    my $enter = move_from($bd, 2, 'hand');
    $bd->set_hand(SIDE_LIGHT, 0);
    my $before = everything($bd);
    ok(!defined $bd->apply($enter), 'a piece from an empty hand is not moved');
    is(everything($bd), $before, 'and nothing changed');

    my $other = board('4xx2/l7/4xx2 l 6 0 7 0');
    my $move = move_from($other, 1, 'a2');
    $other->lift($E->cell_of(0, 1));
    $before = everything($other);
    ok(!defined $other->apply($move), 'nor is a piece that is no longer on its square');
    is(everything($other), $before, 'and nothing changed');

    ok(!eval { $bd->apply('hand-c1'); 1 }, 'apply takes a move, not a string');
    ok(!eval { $bd->unapply('junk'); 1 }, 'unapply takes what apply returned');
    ok(!eval { $bd->unapply(undef); 1 }, 'and not undef');
};

subtest 'the ply is carried by the board and is not the position' => sub {
    my $bd = $E->new;
    is($bd->ply, 0, 'a new board is at ply 0');
    my $key = $bd->key_hex;
    is($bd->set_ply(40), $bd, 'set_ply returns the board');
    is($bd->ply, 40, 'forty');
    is($bd->key_hex, $key, 'and the key has not moved');
    $bd->set_ply(-1);
    is($bd->ply, 40, 'a negative ply is ignored');
    is($bd->clone->ply, 40, 'a clone carries it');
    my ($again) = $E->of_string($bd->to_string);
    is($again->ply, 0, 'a position string does not: a board read from one starts at 0');
};

# PINNED, and counted by hand as far as depth 2: from the start under finkel a
# roll of 0 forfeits and the other four each enter one piece, which is 5. At
# depth 2 four of those five leave dark five choices each, and the fifth (the
# piece that entered on the rosette) leaves light 1 + 2 + 2 + 2 + 1, which is
# 8. Twenty-eight.
subtest 'the walk from the start' => sub {
    my $bd = $E->new;
    my $before = everything($bd);
    is(join(' ', map { $bd->walk($_, 'finkel') }  1 .. 5), '5 28 192 1492 12469', 'finkel, depths 1 to 5');
    is(join(' ', map { $bd->walk($_, 'masters') } 1 .. 5), '4 19 116 846 6556',   'masters, depths 1 to 5');
    is($bd->walk(0, 'finkel'), '1', 'a walk of no plies is the position itself');
    is(everything($bd), $before, 'and the board is as it was');

    my $won = board('4xx2/8/4xx2 d 0 7 7 0');
    is($won->walk(3, 'finkel'), '1', 'a finished game is where a walk ends');
};

# WHAT THE TWIN SAID, the second half: the twin makes the moves as well, and
# these are the numbers it walked to.
subtest 'the engine against the twin, walking' => sub {
    my $path = File::Spec->catfile(dirname(__FILE__), 'twin-walks.txt');
    open my $in, '<', $path or die "no fixture at $path: $!";
    my %set = (
        'finkel'     => 'finkel',
        'masters'    => 'masters',
        'short-open' => { route => 'short', safe_rosettes => 0 },
        'long-safe'  => { route => 'long',  safe_rosettes => 1 },
    );
    my (%lines, %wrong, @bad);
    while (my $line = <$in>) {
        chomp $line;
        my ($name, $position, $depth, $want) = split /\|/, $line, -1;
        die "a line of the fixture is not four fields: $line" unless defined $want && exists $set{$name};
        my $got = board($position)->walk($depth, $set{$name});
        $lines{$name}++;
        next if $got eq $want;
        $wrong{$name}++;
        push @bad, "$line\n    the engine says: $got" if @bad < 5;
    }
    close $in;
    for my $name (sort keys %set) {
        cmp_ok($lines{$name} || 0, '>=', 100, "$name: at least a hundred walks were read ($lines{$name})");
        is($wrong{$name} || 0, 0, "$name: and the engine agrees with every one");
    }
    diag($_) for @bad;
};

done_testing();
