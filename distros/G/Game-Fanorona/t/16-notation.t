use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use Game::Fanorona::Rules ();
use Game::Fanorona::Notation ':all';
use FnT qw(sq name mtext board);
my $E = 'Game::Fanorona::Engine';

subtest 'a point' => sub {
    is_deeply([ parse_point('a1') ], [ 0, 0 ], 'a1 is file 0, rank 0');
    is_deeply([ parse_point('e3') ], [ 4, 2 ], 'e3 is file 4, rank 2');
    is_deeply([ parse_point('i5') ], [ 8, 4 ], 'i5 is file 8, rank 4');
    is(format_point(4, 2), 'e3', 'and back');
    for my $bad ('', 'e', '3', 'e0', 'e6', 'j3', 'E3', 'e33', ' e3', "e3\n", 'e-3', undef) {
        is(scalar(my @none = parse_point($bad)), 0, 'not a point: ' . (defined $bad ? "'$bad'" =~ s/\n/\\n/r : 'undef'));
    }
    is(format_point(9, 0), undef, 'file 9 has no name');
    is(format_point(0, 5), undef, 'nor rank 5');
    is(format_point(-1, 0), undef, 'nor a negative file');
    is(format_point(undef, 0), undef, 'nor nothing');

    # on a smaller board a point has to be on it
    is_deeply([ parse_point('c3', cols => 3, rows => 3) ], [ 2, 2 ], 'c3 is a point of the three by three');
    is(scalar(my @off = parse_point('d1', cols => 3, rows => 3)), 0, 'd1 is not');
    is(scalar(my @high = parse_point('a4', cols => 3, rows => 3)), 0, 'nor a4');
    is(scalar(my @odd = parse_point('a1', cols => 4, rows => 4)), 0, 'and no point is on a board that is not one');

    # THE NUMBERS ARE THE ENGINE'S. This module works them out for itself,
    # with no engine loaded, so here is the only place the two are compared.
    my $bd = $E->new;
    my @wrong = grep { square_of(name($_)) != $_ || (name_of($_) // '') ne name($_) } $bd->all_squares;
    is(scalar(@wrong), 0, 'square_of and name_of agree with the engine on all forty-five points');
    is(square_of('e3'), $E->square_of(4, 2), 'e3 is the engine\'s e3');
    is(square_of('j1'), -1, 'square_of something that is not a point is -1');
    is(name_of(0), undef, 'and a number in the ring has no name');
    is(name_of(77), undef, 'nor one past the grid');
    is(name_of('x'), undef, 'nor something that is not a number');
};

# The solving paper writes the five openings this way.
subtest 'the five openings, as the paper writes them' => sub {
    is(join(' ', sort map { format_move($_) } $E->new->moves), 'd2-e3A d3-e3A d3-e3W e2-e3A f2-e3A',
        'd3-e3A, d3-e3W, e2-e3A, f2-e3A and d2-e3A');
    my $move = parse_move('e2-e3A');
    is($move->{from}, sq('e2'), 'e2-e3A starts on e2');
    is($move->{to}, sq('e3'), 'ends on e3');
    is_deeply($move->{points}, [ 'e2', 'e3' ], 'touches e2 and e3');
    is_deeply($move->{steps}, [ { from => sq('e2'), to => sq('e3'), dir => N, kind => APPROACH } ],
        'and is one step north, an approach');
    is_deeply([ move_points('b2-c2A-c3A') ], [ qw(b2 c2 c3) ], 'move_points of a chain');
    is(scalar(my @none = move_points('b2-c4')), 0, 'and of something that is not a move, nothing');
};

# EVERY MOVE THE ENGINE CAN MAKE IN 285 POSITIONS: written, read back, and
# played from what was read. A parsed step is what the game takes, so a move
# read from text must reach the position the move itself reaches.
subtest 'every move of 285 positions is written and read back' => sub {
    open my $fh, '<', "$FindBin::Bin/moves.txt" or die "t/moves.txt: $!";
    my ($moves, $chains, $sizes, @bad) = (0, 0, {});
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /\A#/ || $line !~ /\S/;
        my ($position) = split /\t/, $line;
        my $bd = board($position);
        my %size = (cols => $bd->cols, rows => $bd->rows);
        $sizes->{"$size{cols}x$size{rows}"}++;
        for my $move ($bd->moves) {
            $moves++;
            $chains++ if $move->length > 1;
            my $string = format_move($move);
            (my $want = mtext($move)) =~ s/x[a-i1-5,]+//g;
            push @bad, "$position: wrote $string, wanted $want" unless $string eq $want;
            my ($parsed, $why) = parse_move($string, %size);
            if (!$parsed) { push @bad, "$position: $string was refused, $why"; next }
            push @bad, "$position: $string came back as " . format_move($parsed) unless format_move($parsed) eq $string;
            my @theirs = map { join ',', @{$_}{qw(from to dir kind)} } @{ $move->steps };
            my @mine   = map { join ',', @{$_}{qw(from to dir kind)} } @{ $parsed->{steps} };
            push @bad, "$position: $string parsed to other steps" unless "@mine" eq "@theirs";

            my $game = Game::Fanorona::Rules->new(position => $position, variant => { quiet_limit => 0, repeat => 0 });
            my $made = 0;
            for my $s (@{ $parsed->{steps} }) { last unless $game->step($s); $made++ }
            $game->stop if $game->in_chain;
            my $tokens = $bd->play_move($move);
            push @bad, "$position: $string, played from its text, reached " . $game->position
                unless $made == @{ $parsed->{steps} } && $game->position eq $bd->to_string;
            $bd->unplay_move($tokens);
        }
    }
    cmp_ok($moves, '>', 3000, "$moves moves");
    cmp_ok($chains, '>', 2000, "$chains of them chains");
    cmp_ok(scalar(keys %$sizes), '>=', 4, 'on ' . join(', ', sort keys %$sizes));
    is(scalar(@bad), 0, 'each written canonically, read back to the same steps, and played to the same position')
        or diag join "\n", @bad[0 .. ($#bad < 3 ? $#bad : 3)];
};

subtest 'a string that is not a move, and why' => sub {
    my @refused = (
        [ undef,            'empty',          'no string' ],
        [ '',               'empty',          'an empty one' ],
        [ 'b2c2',           'bad_shape',      'no dash' ],
        [ 'b2',             'bad_shape',      'one point and nothing else' ],
        [ 'b2-',            'bad_shape',      'a trailing dash' ],
        [ '-b2-c2',         'bad_shape',      'a leading dash' ],
        [ 'b2--c2',         'bad_shape',      'two dashes together' ],
        [ 'b2 - c2',        'bad_shape',      'spaces' ],
        [ "b2-c2\n",        'bad_shape',      'a newline on the end' ],
        [ 'b2-c2!',         'bad_shape',      'punctuation' ],
        [ 'b2A-c2',         'kind_on_start',  'a letter on the point it starts from' ],
        [ 'B2-c2',          'bad_point',      'a capital file to start with' ],
        [ 'b2-C2',          'bad_point',      'a capital file INSIDE a move' ],
        [ 'bb-c2',          'bad_point',      'two letters' ],
        [ 'b2-22',          'bad_point',      'two digits' ],
        [ 'b2-c',           'bad_point',      'a point with no rank' ],
        [ 'b2-c2a',         'bad_kind',       'a lower-case kind' ],
        [ 'b2-c2X',         'bad_kind',       'a kind that is not A or W' ],
        [ 'b2-c2AW',        'bad_kind',       'both kinds at once' ],
        [ 'b2-c22',         'bad_kind',       'a third character that is a digit' ],
        [ 'a5-a6',          'off_board',      'rank 6, as the point arrived on' ],
        [ 'a6-a5',          'off_board',      'rank 6, as the point left' ],
        [ 'a1-a0',          'off_board',      'rank 0' ],
        [ 'i2-j2',          'off_board',      'file j' ],
        [ 'b2-c2A-c6A',     'off_board',      'rank 6 in the third point of a chain' ],
        [ 'b2-b2',          'same_point',     'a step to the same point' ],
        [ 'b2-c4',          'not_adjacent',   'a knight\'s move' ],
        [ 'b2-b4',          'not_adjacent',   'two points up' ],
        [ 'b2-c2A-e2A',     'not_adjacent',   'a gap in the middle of a chain' ],
        [ 'e2-f3',          'no_line',        'a diagonal from a weak point' ],
        [ 'b2-c2A-d3A',     'no_line',        'a diagonal from a weak point in the middle of a chain' ],
        [ 'b2-c2-c3A',      'paika_in_chain', 'a step with no letter and another after it' ],
        [ 'b2-c2A-c3',      'paika_in_chain', 'a step with no letter at the end of a chain' ],
    );
    for my $case (@refused) {
        my ($string, $want, $what) = @$case;
        my ($move, $why) = parse_move($string);
        ok(!defined $move, "$what: no move");
        is($why, $want, "$what: $want");
    }
    cmp_ok(scalar(@refused), '>=', 20, scalar(@refused) . ' strings refused');
    is(scalar(parse_move('b2-c4')), undef, 'in scalar context a refusal is undef');

    my %seen = map { $_->[1] => 1 } @refused;
    is_deeply([ sort keys %seen ],
        [ sort qw(empty bad_shape kind_on_start bad_point bad_kind off_board same_point not_adjacent no_line paika_in_chain) ],
        'ten different reasons among them');

    # the two that need an argument to provoke
    is((parse_move('a1-a2', cols => 4, rows => 5))[1], 'bad_size', 'a board that is not one: bad_size');
    my $long = 'a1' . ('-a2A-a1A' x 23);
    is((parse_move($long))[1], 'too_long', 'forty-six steps: too_long');
    ok(parse_move('a1' . ('-a2A-a1A' x 22)), 'forty-four steps is a shape this module will read, though no game has such a move');
    is((parse_move('a1' . ('-a2A-a1A' x 22) . '-a2A'))[1], 'too_long', 'forty-five steps is one too many');

    # a point that is on the big board and off the small one
    ok(parse_move('c3-d3'), 'c3-d3 is a step on the nine by five');
    is((parse_move('c3-d3', cols => 3, rows => 3))[1], 'off_board', 'and off the three by three');
    ok(parse_move('b2-c3', cols => 3, rows => 3), 'b2-c3 is a diagonal on the three by three');
};

subtest 'what is a shape and what is a rule' => sub {
    # all of these parse. None could be played from the set-up, and that is
    # for the game to say.
    for my $string ('a1-a2', 'e3-e4', 'b2-c2A-c3A-c2W', 'b2-c2A-d2A', 'e3-f4W') {
        ok(parse_move($string), "$string is a well-formed move");
    }
    my $game = Game::Fanorona::Rules->new;
    my $move = parse_move('a1-a2');
    ok(!$game->step($move->{steps}[0]), 'a1-a2 parses, and the game refuses it');
    is($game->why, WHY_OCCUPIED, 'because a2 is occupied');
    my $wrong = parse_move('d3-e3A');
    ok($game->step($wrong->{steps}[0]), 'd3-e3A parses, and the game plays it');
};

subtest 'format_move' => sub {
    is(format_move(parse_move('b2-b1')), 'b2-b1', 'a paika has no letter');
    is(format_move(parse_move('f4-e4W')), 'f4-e4W', 'a withdrawal has a W');
    is(format_move(undef), undef, 'nothing has no string');
    is(format_move('b2-b1'), undef, 'a string is not a move');
    is(format_move({ from => sq('b2'), steps => [] }), undef, 'nor is a move with no steps');
    is(format_move({ from => 0, steps => [ { to => sq('b1'), kind => 0 } ] }), undef, 'nor one that starts in the ring');
    is(format_move({ from => sq('b2'), steps => [ { to => sq('b1'), kind => 7 } ] }), undef, 'nor one with a kind that is not one');
};

subtest 'a move reflected' => sub {
    is(mirror_move('d3-e3A', 'files'), 'f3-e3A', 'left to right: d3-e3 becomes f3-e3');
    is(mirror_move('d3-e3A', 'ranks'), 'd3-e3A', 'top to bottom: a move along the middle rank is itself');
    is(mirror_move('d2-e3A', 'turn'), 'f4-e3A', 'half a turn: d2-e3 becomes f4-e3');
    is(mirror_move('a1-b2', 'files', cols => 3, rows => 3), 'c1-b2', 'on the three by three, a1 goes to c1');
    is(mirror_move('b2-c4', 'files'), undef, 'something that is not a move has no reflection');
    is(mirror_move('d3-e3A', 'sideways'), undef, 'nor is there a reflection called sideways');
    for my $how (qw(files ranks turn)) {
        is(mirror_move(mirror_move('f4-e4W-e3A-d3A', $how), $how), 'f4-e4W-e3A-d3A', "reflected by $how twice, a move is itself");
    }

    # A REFLECTED MOVE IS A MOVE OF THE REFLECTED POSITION. Lines map to lines
    # and strong points to strong points, so the whole list goes across.
    my @bad;
    for my $position ('9/5wb2/2b6/3bb4/9 w', '9/1b7/3b5/w1b6/1b7 w', SETUP, 'bbbbb/bbbbb/bw1bw/wwwww/wwwww w') {
        my $bd = board($position);
        my %size = (cols => $bd->cols, rows => $bd->rows);
        my $list = join ' ', sort map { format_move($_) } $bd->moves;
        for my $how (qw(files ranks turn)) {
            my $there = join ' ', sort map { format_move($_) } board(mirror_position($position, $how))->moves;
            my $across = join ' ', sort map { mirror_move($_, $how, %size) } split ' ', $list;
            push @bad, "$position by $how" unless $there eq $across;
        }
    }
    is("@bad", '', 'the moves of four positions, reflected three ways, are the moves of the reflected positions');
};

done_testing();
