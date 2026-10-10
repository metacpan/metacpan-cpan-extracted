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

# A move as a person would say it: where from, where to, and what it does.
sub said {
    my ($move) = @_;
    return $move->from . '-' . $move->to . ($move->captures ? 'x' : '') . ($move->rosette ? '*' : '');
}

sub moves_said { join ' ', map { said($_) } $_[0]->moves($_[1], $_[2]) }

my %OPEN      = (safe_rosettes => 0);
my %LONG_SAFE = (route => 'long', safe_rosettes => 1);

subtest 'the hand' => sub {
    my $start = board('4xx2/8/4xx2 l 7 0 7 0');
    is(moves_said($start, 2), 'hand-c1', 'seven in hand and a roll of 2: ONE move, not seven');
    is(moves_said($start, 4), 'hand-a1*', 'a roll of 4 enters on the rosette');

    my $none = board('4xx2/8/1l2xx2 l 0 6 7 0');
    is(moves_said($none, 1), 'b1-a1*', 'an empty hand is not a candidate');
    is(moves_said($none, 2), 'b1-a2', 'at any roll');

    my $blocked = board('4xx2/8/2l1xx2 l 6 0 7 0');
    is(moves_said($blocked, 2), 'c1-a1*', 'the hand may not enter onto its own piece');
};

subtest 'landing on your own piece is not a move' => sub {
    my $bd = board('4xx2/l1l5/4xx2 l 5 0 7 0');
    is(moves_said($bd, 2), 'hand-c1 c2-e2', 'a2 may not land on c2');
    is(moves_said($bd, 1), 'hand-d1 a2-b2 c2-d2*', 'though each has other moves');
};

subtest 'landing on an enemy piece captures it' => sub {
    my $bd = board('4xx2/l2d1d2/4xx2 l 6 0 5 0');
    my ($enter, $move) = $bd->moves(4);
    is(said($move), 'a2-e2', 'a2 goes to e2 past the dark piece on d2');
    ok(!$move->captures, 'and captures nothing by passing it');
    is(moves_said($bd, 3, \%OPEN), 'hand-b1 a2-d2x*', 'with safety off, a roll of 3 captures on d2');

    my $plain = board('4xx2/l1d5/4xx2 l 6 0 6 0');
    my (undef, $take) = $plain->moves(2);
    is(said($take), 'a2-c2x', 'an enemy on an ordinary shared square is captured');
    is($take->captures, 1, 'and the move says so');
    is($take->rosette, 0, 'and that it is not a rosette');
    is($take->to_cell, $E->cell_of(2, 1), 'the cell it lands on is c2');
    is($plain->at($E->cell_of(2, 1)), DARK, 'and the dark piece is STILL THERE: a move is described, not made');
};

# The rosette refuses a landing. It does not close the route.
subtest 'a safe rosette' => sub {
    my $bd = board('4xx2/l2d4/4xx2 l 6 0 6 0');
    is(moves_said($bd, 3), 'hand-b1', 'under finkel a2 may not land on the dark piece on d2');
    is(moves_said($bd, 3, \%OPEN), 'hand-b1 a2-d2x*', 'with safety off it captures there');
    is(moves_said($bd, 4), 'hand-a1* a2-e2', 'and safe or not, it may pass over');
    is(moves_said($bd, 3, 'masters'), 'hand-b1 a2-d2x*', 'masters has no safe rosette');

    my $own = board('4xx2/l2l4/4xx2 l 5 0 7 0');
    is(moves_said($own, 3), 'hand-b1 d2-g2', 'a rosette does not let you land on your own piece either');

    my $empty = board('4xx2/l7/4xx2 l 6 0 7 0');
    my (undef, $onto) = $empty->moves(3);
    is(said($onto), 'a2-d2*', 'an empty rosette is landed on, and the move says rosette');
};

# Under the long route a rosette in the FAR row can hold an enemy, and "only
# d2 is safe" and "rosettes are safe" stop being the same rule.
subtest 'the far rosette under the long route' => sub {
    my $bd = board('4xxd1/6l1/4xx2 l 6 0 6 0');
    is(moves_said($bd, 1, 'masters'), 'hand-d1 g2-g3x*', 'masters: light captures on g3, in the dark row');
    is(moves_said($bd, 1, \%LONG_SAFE), 'hand-d1', 'long and safe: g3 is a rosette and the dark piece is safe on it');
    is(moves_said($bd, 2, \%LONG_SAFE), 'hand-c1 g2-h3', 'and may be passed');
};

# EXACT MEANS EXACT. A piece that would overshoot does not move: it does not
# leave, and it does not bounce.
subtest 'leaving the board' => sub {
    my $short = board('4xx2/8/4xx1l l 0 6 7 0');
    is(moves_said($short, 1), 'h1-g1*', 'short route, step 13: a roll of 1 is not home yet');
    is(moves_said($short, 2), 'h1-home', 'a roll of 2 is exactly home');
    is(moves_said($short, 3), '', 'a roll of 3 overshoots: no move');
    is(moves_said($short, 4), '', 'and so does 4');

    my $last = board('4xx2/8/4xxl1 l 0 6 7 0');
    is(moves_said($last, 1), 'g1-home', 'from the last step a roll of 1 leaves');
    is(moves_said($last, $_), '', "and a roll of $_ does not") for 2 .. 4;

    my ($home) = $last->moves(1);
    is($home->home, 1, 'the move says home');
    is($home->rosette, 0, 'and NOT rosette: home is not a square');
    is($home->to, 'home', 'it goes to home');
    is($home->to_cell, -1, 'which is no cell');
    is($home->to_step, 15, 'and is step 15 of the short route');
    is($home->captures, 0, 'and nothing is captured there');

    my $long = board('4xx2/8/4xx1l l 0 6 7 0');
    is(moves_said($long, 1, 'masters'), 'h1-g1*', 'long route, h1 is step 15: a roll of 1 reaches g1');
    is(moves_said($long, 2, 'masters'), 'h1-home', 'and 2 is home');
    my ($far) = $long->moves(2, 'masters');
    is($far->to_step, 17, 'step 17 of the long route');

    my $mid = board('4xx2/7l/4xx2 l 0 6 7 0');
    is(moves_said($mid, 3), 'h2-home', 'short route, h2 is step 12 and 3 is home');
    is(moves_said($mid, 3, 'masters'), 'h2-home', 'long route, h2 is step 14 and 3 is home too');
    is(moves_said($mid, 4), '', 'short: 4 from h2 overshoots');
    is(moves_said($mid, 4, 'masters'), '', 'and long');
    is(moves_said($mid, 2), 'h2-g1*', 'short: 2 from h2 is g1');
    is(moves_said($mid, 2, 'masters'), 'h2-g1*', 'long: 2 from h2 is g1 as well, by the other way round');
    is(moves_said($mid, 1), 'h2-h1', 'both go to h1 on a 1');
};

# The order is part of the contract: the hand, then ASCENDING STEP. For dark on
# the long route the steps do not run the way the squares are numbered.
subtest 'the order of the list' => sub {
    my $bd = board('d3xx1d/8/4xxd1 d 4 0 7 0');
    my @moves = $bd->moves(1, 'masters');
    is(join(' ', map { $_->from } @moves), 'hand a3 g1 h3', 'the hand, then a3 (4), g1 (12), h3 (15)');
    is(join(' ', map { $_->from_step } @moves), '0 4 12 15', 'which is ascending step');
    is(join(' ', map { $_->to } @moves), 'd3 a2 h1 g3', 'and where each goes');

    my $light = board('4xx2/l6l/l3xx1l l 3 0 7 0');
    is(join(' ', map { $_->from } $light->moves(2)), 'hand a1 a2 h2 h1', 'light on the short route, a roll of 2: 4, 5, 12, 13');
};

subtest 'at most seven' => sub {
    is(MOVES_MAX, 7, 'MOVES_MAX is seven');
    my $bd = board('4xx2/1l1l1l1l/l1l1xx2 l 1 0 7 0');
    is(scalar($bd->moves(1)), 7, 'six pieces and the hand all move on a 1, short route');
    is(scalar($bd->moves(1, 'masters')), 7, 'and on the long route');
    is(scalar(my @list = $bd->moves(1)), 7, 'the same in list context');
};

subtest 'a roll of nothing, and a roll that is not one' => sub {
    my $bd = board('4xx2/l2d2l1/1l2xx1l l 2 1 6 0');
    is(scalar($bd->moves(0)), 0, 'a roll of 0 allows nothing');
    is_deeply([ $bd->moves(0, 'masters') ], [], 'under either set');
    for my $bad (5, -1, 1.5, 'two', '', undef) {
        my $shown = defined $bad ? "'$bad'" : 'undef';
        ok(!eval { $bd->moves($bad); 1 }, "a roll of $shown croaks: it is not an empty list");
    }
    like($@, qr/whole number from 0 to 4/, 'with a sentence');
};

subtest 'the side to move, and nothing else, decides whose moves' => sub {
    my $bd = board('2d1xx2/3l4/4xx2 l 6 0 6 0');
    is(moves_said($bd, 1), 'hand-d1 d2-e2', 'light to move');
    $bd->set_side(SIDE_DARK);
    is(moves_said($bd, 1), 'hand-d3 c3-b3', 'dark to move, same board');
    my ($move) = $bd->moves(1);
    is($move->side, 'dark', 'and the move knows whose it is');
    is($move->roll, 1, 'and what roll made it');
};

subtest 'asking changes nothing' => sub {
    my $bd = board('4xxdd/l2d2ll/4xx1l l 3 0 4 0');
    my ($string, $key) = ($bd->to_string, $bd->key_hex);
    $bd->moves($_, 'masters') for 0 .. 4;
    $bd->moves($_) for 0 .. 4;
    is($bd->to_string, $string, 'the position is as it was');
    is($bd->key_hex, $key, 'and so is its key');
};

subtest 'a move carries both the square and the step' => sub {
    my $bd = board('4xx2/6l1/4xx2 l 6 0 7 0');
    my (undef, $move) = $bd->moves(1, 'masters');
    is($move->from, 'g2', 'from g2');
    is($move->to, 'g3', 'to g3');
    is($move->from_step, 11, 'which is step 11');
    is($move->to_step, 12, 'to step 12');
    is($move->from_cell, $E->cell_of(6, 1), 'the cell of g2');
    is($move->to_cell, $E->cell_of(6, 2), 'the cell of g3');
    is($move->trace, '11>12*', 'and its trace');
    my ($enter) = $bd->moves(1);
    is($enter->from, 'hand', 'a piece entering comes from the hand');
    is($enter->from_step, 0, 'step 0');
    is($enter->from_cell, -1, 'and no cell');
    is($enter->trace, '0>1', 'traced');
};

subtest 'a rule set is a name or a hash, and a mistake is refused' => sub {
    is_deeply($E->rules('finkel'),
        { route => 'short', dice => 4, zero_rolls => 0, safe_rosettes => 1, pieces => 7 }, 'finkel, spelled out');
    is_deeply($E->rules('masters'),
        { route => 'long', dice => 3, zero_rolls => 4, safe_rosettes => 0, pieces => 7 }, 'masters, spelled out');
    is_deeply($E->rules(undef), $E->rules('finkel'), 'undef is finkel');
    is_deeply($E->rules({}), $E->rules('finkel'), 'and so is an empty hash');
    is($E->rules({ route => 'long' })->{dice}, 4, 'a hash names what differs from finkel');
    is($E->rules({ pieces => 3 })->{pieces}, 3, 'three pieces');

    my $bd = board('4xx2/8/4xx2 l 7 0 7 0');
    my @refused = (
        [ 'bell',                    'a name that is no set' ],
        [ { safe_rosette => 0 },     'a misspelt rule' ],
        [ { route => 'medium' },     'a route that is neither' ],
        [ { dice => 5 },             'five dice' ],
        [ { dice => 2 },             'two dice' ],
        [ { zero_rolls => 2 },       'nothing marked worth two' ],
        [ { pieces => 0 },           'no pieces' ],
        [ { pieces => 8 },           'eight pieces' ],
        [ [ 'finkel' ],              'an array' ],
    );
    for my $case (@refused) {
        ok(!eval { $bd->moves(1, $case->[0]); 1 }, "$case->[1] croaks");
    }
};

# WHAT THE TWIN SAID. t/twin-moves.txt is the output of a second generator,
# written in another language from the rules and not from this engine, over
# positions nobody chose. It is text, so this needs no Python. The file is
# found from this file's own directory.
subtest 'the engine against the twin' => sub {
    my $path = File::Spec->catfile(dirname(__FILE__), 'twin-moves.txt');
    open my $in, '<', $path or die "no fixture at $path: $!";
    my %set = (
        'finkel'     => 'finkel',
        'masters'    => 'masters',
        'short-open' => { route => 'short', safe_rosettes => 0 },
        'long-safe'  => { route => 'long',  safe_rosettes => 1 },
    );
    my (%lines, %wrong, %board, @bad);
    while (my $line = <$in>) {
        chomp $line;
        my ($name, $position, $roll, $want) = split /\|/, $line, -1;
        die "a line of the fixture is not four fields: $line" unless defined $want && exists $set{$name};
        my $bd = $board{$position} ||= board($position);
        my $got = join ' ', map { $_->trace } $bd->moves($roll, $set{$name});
        $lines{$name}++;
        next if $got eq $want;
        $wrong{$name}++;
        push @bad, "$line\n    the engine says: $got" if @bad < 5;
    }
    close $in;
    for my $name (sort keys %set) {
        cmp_ok($lines{$name} || 0, '>=', 500, "$name: at least five hundred lines were read ($lines{$name})");
        is($wrong{$name} || 0, 0, "$name: and the engine agrees with every one");
    }
    diag($_) for @bad;
};

done_testing();
