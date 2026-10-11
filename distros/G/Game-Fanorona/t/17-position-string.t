use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Game::Fanorona::Engine ':all';
use Game::Fanorona::Rules ();
use Game::Fanorona::Notation ':all';
use FnT qw(sq name mtext board roller);
my $E = 'Game::Fanorona::Engine';
my $R = 'Game::Fanorona::Rules';

subtest 'the set-up' => sub {
    is(SETUP, $E->new->to_string, 'SETUP is the engine\'s set-up');
    my $p = parse_position(SETUP);
    is($p->{cols}, 9, 'nine files');
    is($p->{rows}, 5, 'five ranks');
    is($p->{side}, 'w', 'White to move');
    is(scalar(keys %{ $p->{stones} }), 44, 'forty-four stones');
    is($p->{stones}{d3}, 'w', 'd3 is white');
    is($p->{stones}{f3}, 'b', 'f3 is black');
    ok(!exists $p->{stones}{e3}, 'e3 is empty');
    is($p->{board}, SETUP, 'board is the two-field string');
    is($p->{counted}, 0, 'it has no counts');
    is_deeply([ $p->{quiet}, $p->{move} ], [ 0, 1 ], 'so they are 0 and 1');

    my $counted = parse_position(SETUP . ' 7 23');
    is($counted->{counted}, 1, 'the four-field form has counts');
    is_deeply([ $counted->{quiet}, $counted->{move} ], [ 7, 23 ], 'and they are read');
    is($counted->{board}, SETUP, 'and board is still the two-field string, which the engine reads');
    is(format_position(SETUP, 7, 23), SETUP . ' 7 23', 'format_position writes them');
    is(format_position(SETUP), SETUP . ' 0 1', 'and 0 and 1 when they are left out');
};

# WHAT THE ENGINE HOLDS, THE STRING SAYS. Positions reached by play, each
# written by the engine, read here, and compared stone for stone.
subtest 'positions reached in play' => sub {
    my $roll = roller(5102026);
    my ($seen, %distinct, @bad) = (0);
    for my $g (1 .. 120) {
        my $game = $R->new;
        while (!$game->over && $game->ply < 80) {
            my @moves = $game->moves;
            $game->play_move($moves[ $roll->(scalar @moves) ]);
            my $string = $game->position;
            $seen++;
            $distinct{$string}++;
            my ($p, $why) = parse_position($string);
            if (!$p) { push @bad, "$string refused: $why"; next }
            my ($bd) = $E->of_string($string);
            my @wrong = grep {
                my $have = $bd->at($_);
                my $says = $p->{stones}{ name($_) } // '';
                ($have == WHITE ? 'w' : $have == BLACK ? 'b' : '') ne $says
            } $bd->all_squares;
            push @bad, "$string: the stones differ on " . join(' ', map { name($_) } @wrong) if @wrong;
            push @bad, "$string: the side differs" unless $p->{side} eq ($bd->side == WHITE ? 'w' : 'b');
            my $full = format_position($string, $game->quiet, $game->ply + 1);
            my $back = parse_position($full);
            push @bad, "$full did not read back"
                unless $back && $back->{board} eq $string && $back->{quiet} == $game->quiet && $back->{move} == $game->ply + 1;
        }
    }
    cmp_ok($seen, '>', 3000, "$seen positions");
    cmp_ok(scalar(keys %distinct), '>', 2500, scalar(keys %distinct) . ' of them distinct');
    is(scalar(@bad), 0, 'each read stone for stone as the engine has it, and written and read again with its counts')
        or diag join "\n", @bad[0 .. ($#bad < 3 ? $#bad : 3)];
};

# THIS MODULE AND THE ENGINE READ THE SAME STRINGS. Each reads the two-field
# form for itself, one in Perl and one in C. Good strings are damaged one
# character at a time and both are asked.
subtest 'the engine and this module refuse the same strings' => sub {
    my $roll = roller(77);
    my @good = (SETUP, 'bbb/w1b/www w', 'bbbbb/bbbbb/bw1bw/wwwww/wwwww b', '9/9/4w4/9/9 w',
                '1w1b1w1b1/9/4w4/bb5ww/w7b w', 'bbbbbbb/wbw1bwb/wwwwwww b', '9/9/9 w');
    my @chars = (qw(w b 1 2 5 9 0 / x W), ' ', '');
    my ($asked, $accepted, @bad) = (0, 0);
    for my $i (1 .. 4000) {
        my $string = $good[ $roll->(scalar @good) ];
        for (1 .. 1 + $roll->(2)) {
            my $at = $roll->(length($string) + 1);
            my $with = $chars[ $roll->(scalar @chars) ];
            substr($string, $at, $roll->(2), $with);
        }
        $asked++;
        my $mine = parse_position($string) ? 1 : 0;
        my ($bd) = $E->of_string($string);
        my $theirs = $bd ? 1 : 0;
        $accepted += $mine;
        push @bad, "'$string': this module " . ($mine ? 'reads' : 'refuses') . ' it and the engine ' . ($theirs ? 'reads' : 'refuses') . ' it'
            unless $mine == $theirs;
        push @bad, "'$string': read, and not the engine's string"
            if $mine && $theirs && parse_position($string)->{board} ne $bd->to_string;
    }
    is($asked, 4000, 'four thousand damaged strings');
    cmp_ok($accepted, '>', 200, "$accepted of them still positions");
    cmp_ok($asked - $accepted, '>', 2000, ($asked - $accepted) . ' of them not');
    is(scalar(@bad), 0, 'and the two agree on every one')
        or diag join "\n", @bad[0 .. ($#bad < 5 ? $#bad : 5)];
};

subtest 'a string that is not a position, and why' => sub {
    my @refused = (
        [ undef,                       'empty',      'no string' ],
        [ '',                          'empty',      'an empty one' ],
        [ SETUP . (' ' x 40),          'too_long',   'eighty characters or more' ],
        [ '9/9/9/9/9',                 'bad_shape',  'one field' ],
        [ '9/9/9/9/9 w 0',             'bad_shape',  'three fields' ],
        [ '9/9/9/9/9 w 0 1 2',         'bad_shape',  'five fields' ],
        [ '9/9/9/9/9  w',              'bad_shape',  'two spaces' ],
        [ '9/9/9/9/9 w ',              'bad_shape',  'a trailing space' ],
        [ '9/9/4x4/9/9 w',             'bad_letter', 'a letter that is not w or b' ],
        [ '9/9/4W4/9/9 w',             'bad_letter', 'a capital' ],
        [ '9/9/9/9/90 w',              'bad_letter', 'a zero' ],
        [ '9/9/9/9 w',                 'rows',       'four ranks' ],
        [ '9 w',                       'rows',       'one rank' ],
        [ '9/9/8/9/9 w',               'width',      'a short rank' ],
        [ '8/8/8/8/8 w',               'width',      'an even width' ],
        [ '9/9//9/9 w',                'width',      'an empty rank' ],
        [ '9/9/9/9/9 x',               'side',       'a side that is not w or b' ],
        [ '9/9/9/9/9 W',               'side',       'a capital side' ],
        [ '9/9/9/9/9 w x 1',           'bad_count',  'a quiet count that is not a number' ],
        [ '9/9/9/9/9 w 01 1',          'bad_count',  'a quiet count with a leading zero' ],
        [ '9/9/9/9/9 w 0 0',           'bad_count',  'move 0: moves are numbered from 1' ],
        [ '9/9/9/9/9 w -1 1',          'bad_count',  'a quiet count below nothing' ],
        [ '9/9/9/9/9 w 0 1.5',         'bad_count',  'a move number that is not whole' ],
    );
    for my $case (@refused) {
        my ($string, $want, $what) = @$case;
        my ($p, $why) = parse_position($string);
        ok(!defined $p, "$what: no position");
        is($why, $want, "$what: $want");
    }
    # A STRING CAN SPELL A RUN TWO WAYS, and both load. What comes back is the
    # one way the engine writes it.
    is(parse_position('9/9/414/9/9 w')->{board}, '9/9/9/9/9 w', '414 is nine empty points, and comes back as 9');
    is(parse_position('1w1b1w1b1/9/4w4/bb5ww/w71 w')->{board}, '1w1b1w1b1/9/4w4/bb5ww/w8 w', 'w71 comes back as w8');
    is(format_position('9/9/414/9/9 w', 3, 4), '9/9/9/9/9 w 3 4', 'and format_position writes the canonical board');

    is(format_position('9/9/9/9 w'), undef, 'format_position of something that is not a position is undef');
    is(format_position(SETUP . ' 0 1'), undef, 'and of a string that already has counts');
    is(format_position(SETUP, 'x', 1), undef, 'and with a count that is not a number');
    is(format_position(SETUP, 0, 0), undef, 'and with move 0');
};

subtest 'a position reflected' => sub {
    is(mirror_position(SETUP, 'files'), 'bbbbbbbbb/bbbbbbbbb/wbwb1wbwb/wwwwwwwww/wwwwwwwww w',
        'left to right, the middle rank reads the other way');
    is(mirror_position(SETUP, 'ranks'), 'wwwwwwwww/wwwwwwwww/bwbw1bwbw/bbbbbbbbb/bbbbbbbbb w',
        'top to bottom, White is at the top');
    is(mirror_position(SETUP, 'turn'), 'wwwwwwwww/wwwwwwwww/wbwb1wbwb/bbbbbbbbb/bbbbbbbbb w', 'half a turn is both');
    is(mirror_position(SETUP . ' 3 9', 'files'), 'bbbbbbbbb/bbbbbbbbb/wbwb1wbwb/wwwwwwwww/wwwwwwwww w 3 9', 'the counts are kept');
    is(mirror_position('bbb/w1b/www b', 'files'), 'bbb/b1w/www b', 'on the three by three, with the side kept');
    is(mirror_position('9/9/9/9 w', 'files'), undef, 'something that is not a position has no reflection');
    is(mirror_position(SETUP, 'sideways'), undef, 'nor is there a reflection called sideways');

    my $odd = '1w1b1w1b1/9/4w4/bb5ww/w7b w';
    my %four = map { $_ => 1 } $odd, map { mirror_position($odd, $_) } qw(files ranks turn);
    is(scalar(keys %four), 4, 'a position with no symmetry has four different reflections');
    for my $how (qw(files ranks turn)) {
        is(mirror_position(mirror_position($odd, $how), $how), $odd, "reflected by $how twice, it is itself");
        my $there = parse_position(mirror_position($odd, $how));
        is(scalar(grep { $_ eq 'w' } values %{ $there->{stones} }) . ',' . scalar(grep { $_ eq 'b' } values %{ $there->{stones} }),
            '6,5', "and reflected by $how it has the same six white stones and five black");
    }
    is(mirror_position(mirror_position($odd, 'files'), 'ranks'), mirror_position($odd, 'turn'), 'files then ranks is half a turn');
};

subtest 'a game as text' => sub {
    my $game = $R->new;
    my $roll = roller(42);
    my @moves;
    until ($game->over) {
        my @list = $game->moves;
        my $move = $list[ $roll->(scalar @list) ];
        push @moves, format_move($move);
        $game->play_move($move);
    }
    my $text = format_game({ white => 'Rakoto', black => 'Rasoa', quiet_limit => 60, moves => \@moves, result => $game->how });
    like($text, qr/\Afanorona 1\nvariant sivy\nquiet_limit 60\nwhite Rakoto\nblack Rasoa\nresult \w+\nmoves\n/, 'the header, in a fixed order');
    is(scalar(() = $text =~ /\n/g), 7 + @moves, 'and one line a move after it');

    my ($read, $why, $line) = parse_game($text);
    ok($read, 'it reads back') or diag "$why at line $line";
    is_deeply($read->{moves}, \@moves, 'with every move');
    is($read->{white}, 'Rakoto', 'the names');
    is($read->{variant}, 'sivy', 'the variant');
    is_deeply([ $read->{cols}, $read->{rows} ], [ 9, 5 ], 'and its size');

    # THE TEXT IS ENOUGH TO PLAY THE GAME AGAIN
    my $again = $R->new(variant => { quiet_limit => $read->{quiet_limit} });
    for my $string (@{ $read->{moves} }) {
        my $parsed = parse_move($string, cols => $read->{cols}, rows => $read->{rows});
        $again->step($_) or die "$string was refused" for @{ $parsed->{steps} };
        $again->stop if $again->in_chain;
    }
    is($again->position, $game->position, 'played again from the text, the game ends on the same position');
    is($again->how, $game->how, 'in the same way');
    is($again->ply, scalar(@moves), 'after the same number of moves');

    is(format_game({ moves => [] }), "fanorona 1\nvariant sivy\nmoves\n", 'a game with no moves yet');
    my $small = format_game({ variant => 'telo', start => 'bbb/w1b/www w', moves => [ 'a2-b2A' ] });
    is((parse_game($small))->{cols}, 3, 'a game on the three by three, with its start');
    is((parse_game("fanorona 1\nvariant 7x5\nmoves\ng1-g2\n"))->{cols}, 7, 'and a size that has no name');
};

subtest 'text that is not a game, and why' => sub {
    my @refused = (
        [ undef,                                              'empty',           0, 'nothing' ],
        [ "variant sivy\nmoves\n",                             'not_a_game',      1, 'no first line' ],
        [ "fanorona 2\nmoves\n",                               'not_a_game',      1, 'another version' ],
        [ "fanorona 1\nvariant sivy\n",                        'no_moves_line',   2, 'no moves line' ],
        [ "fanorona 1\nvariant\nmoves\n",                      'bad_header',      2, 'a header with no value' ],
        [ "fanorona 1\nVariant sivy\nmoves\n",                 'bad_header',      2, 'a capital in a header' ],
        [ "fanorona 1\ncolour red\nmoves\n",                   'unknown_header',  2, 'a header this module does not know' ],
        [ "fanorona 1\nwhite a\nwhite b\nmoves\n",             'repeated_header', 3, 'a header twice' ],
        [ "fanorona 1\nquiet_limit lots\nmoves\n",             'bad_number',      2, 'a limit that is not a number' ],
        [ "fanorona 1\nvariant grande\nmoves\n",               'bad_variant',     2, 'a variant that is not one' ],
        [ "fanorona 1\nvariant 4x4\nmoves\n",                  'bad_variant',     2, 'a size that is not one' ],
        [ "fanorona 1\nstart 9/9/9/9 w\nmoves\n",              'bad_start',       2, 'a start that is not a position' ],
        [ "fanorona 1\nvariant telo\nstart 9/9/9/9/9 w\nmoves\n", 'bad_start',    2, 'a start of another size' ],
        [ "fanorona 1\nmoves\nd3-e3A\nb2-c4\n",                'not_adjacent',    4, 'a move that is not one, with the line it is on' ],
        [ "fanorona 1\nvariant telo\nmoves\nd3-e3A\n",         'off_board',       4, 'a move off the board the game is on' ],
        [ "fanorona 1\nmoves\nd3-e3A\n\nc3-d3W\n",             'empty',           4, 'a blank line among the moves' ],
    );
    for my $case (@refused) {
        my ($text, $want, $at, $what) = @$case;
        my ($game, $why, $line) = parse_game($text);
        ok(!defined $game, "$what: no game");
        is($why, $want, "$what: $want");
        is($line, $at, "$what: line $at");
    }
    is(format_game({ colour => 'red', moves => [] }), undef, 'format_game will not write a header it does not know');
    is(format_game({ white => "Ra\x{e9}", moves => [] }), undef, 'nor a value outside plain ASCII');
    is(format_game({ white => '', moves => [] }), undef, 'nor an empty value');
    is(format_game({ white => "a\nresult stones", moves => [] }), undef, 'nor a value with a line break in it, which would be read as a second header');
    is(format_game({ moves => [ 'b2-c4' ] }), undef, 'nor a move that is not one');
    is(format_game({ moves => 'd3-e3A' }), undef, 'nor moves that are not a list');
    is(format_game('text'), undef, 'nor anything that is not a hash');
};

done_testing();
