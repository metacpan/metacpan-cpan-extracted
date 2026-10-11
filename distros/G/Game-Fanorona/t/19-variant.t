use strict;
use warnings;
use Test::More;

use Game::Fanorona::Variant;
use Game::Fanorona::Engine ();
use Game::Fanorona::Rules ();
my $V = 'Game::Fanorona::Variant';

subtest 'the three named boards' => sub {
    my %want = (
        sivy => [ 9, 5, 'bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w' ],
        dimy => [ 5, 5, 'bbbbb/bbbbb/bw1bw/wwwww/wwwww w' ],
        telo => [ 3, 3, 'bbb/w1b/www w' ],
    );
    is_deeply([ $V->names ], [ qw(sivy dimy telo) ], 'sivy, dimy, telo');
    for my $name ($V->names) {
        my $v = $V->named($name);
        isa_ok($v, $V);
        is($v->name, $name, "$name is called $name");
        is_deeply([ $v->cols, $v->rows ], [ @{ $want{$name} }[0, 1] ], "$name is $want{$name}[0] by $want{$name}[1]");
        is($v->start, $want{$name}[2], "$name starts from its set-up");
        ok($v->is_setup, 'which it knows is the set-up');
        is($v->as_string, $name, "and as a string it is just '$name'");
    }
    is($V->named->name, 'sivy', 'with no name, named gives the nine by five');
};

subtest 'the limits are the game\'s' => sub {
    my $v = $V->named;
    my $game = Game::Fanorona::Rules->new;
    is($v->quiet_limit, $game->quiet_limit, 'the quiet limit is the one a game has by default');
    is($v->repeat, $game->repeat, 'and the repeat');
    is($v->ply_cap, $game->ply_cap, 'and the cap');
    is_deeply($v->limits, { quiet_limit => 60, repeat => 3, ply_cap => 3000 }, 'limits is the three as a hash: 60, 3, 3,000');
    my $made = Game::Fanorona::Rules->new(position => $v->start, variant => $V->custom(board => 'sivy', quiet_limit => 7, repeat => 0, ply_cap => 90)->limits);
    is_deeply([ $made->quiet_limit, $made->repeat, $made->ply_cap ], [ 7, 0, 90 ], 'and a game made from a variant\'s limits has them');
};

subtest 'custom' => sub {
    my $v = $V->custom(board => 'sivy', quiet_limit => 40);
    is($v->name, 'sivy', 'a nine by five with another limit is still called sivy');
    is($v->quiet_limit, 40, 'with its limit');
    is($v->repeat, 3, 'and the other two at their defaults');
    is($v->as_string, 'sivy,quiet_limit=40', 'as a string: the name and what differs');

    my $odd = $V->custom(cols => 7, rows => 5);
    is($odd->name, '7x5', 'a board with no name is called by its size');
    is($odd->start, 'bbbbbbb/bbbbbbb/wbw1bwb/wwwwwww/wwwwwww w', 'and starts from the pattern carried to that size');
    is($V->custom(cols => 5, rows => 5)->name, 'dimy', 'a five by five given by its size is dimy');

    # THE OTHER FIVE BY FIVE. The pattern gives b w . b w; a rank that reads
    # the same from both ends is a real alternative, and can be asked for.
    my $other = $V->custom(board => 'dimy', start => 'bbbbb/bbbbb/bw1wb/wwwww/wwwww w');
    is($other->start, 'bbbbb/bbbbb/bw1wb/wwwww/wwwww w', 'a start that is not the set-up');
    ok(!$other->is_setup, 'which it knows is not');
    is($other->as_string, 'dimy,start=bbbbb/bbbbb/bw1wb/wwwww/wwwww w', 'and writes');
    is($V->custom(board => 'telo', start => '3/1w1/3 b')->start, '3/1w1/3 b', 'any position of the board will do as a start');
    is($V->custom(board => 'sivy', start => '9/9/414/9/9 w')->start, '9/9/9/9/9 w', 'and is kept the one way the engine writes it');
};

subtest 'what custom refuses' => sub {
    my @refused = (
        [ [ colour => 'red', cols => 9, rows => 5 ],          qr/no field is called 'colour'/,  'a field that is not one' ],
        [ [ cols => 9, rows => 5, quiet_limit => undef ],     qr/quiet_limit has no value/,     'a field with no value' ],
        [ [ cols => 9 ],                                      qr/a board is cols and rows/,     'cols without rows' ],
        [ [ ],                                                qr/a board is cols and rows/,     'no board at all' ],
        [ [ cols => 8, rows => 5 ],                           qr/no board is 8 by 5/,           'an even width' ],
        [ [ cols => 9, rows => 7 ],                           qr/no board is 9 by 7/,           'seven ranks' ],
        [ [ cols => 'nine', rows => 5 ],                      qr/no board is nine by 5/,        'a size that is not a number' ],
        [ [ board => 'grande' ],                              qr/no board is called 'grande'/,  'a name that is not a board' ],
        [ [ board => 'telo', cols => 3, rows => 3 ],          qr/not both/,                     'a name and a size together' ],
        [ [ board => 'sivy', quiet_limit => 'lots' ],         qr/quiet_limit is a whole number/, 'a limit that is not a number' ],
        [ [ board => 'sivy', quiet_limit => -1 ],             qr/quiet_limit is a whole number/, 'a limit below nothing' ],
        [ [ board => 'sivy', repeat => 1 ],                   qr/repeat is 0, for never, or 2/, 'a repeat of 1' ],
        [ [ board => 'sivy', ply_cap => 0 ],                  qr/ply_cap is 1 or more/,         'a cap of nothing' ],
        [ [ board => 'sivy', start => '9/9/9/9 w' ],          qr/is not a position/,            'a start that is not a position' ],
        [ [ board => 'telo', start => '9/9/9/9/9 w' ],        qr/not a position of a board 3 by 3/, 'a start of another size' ],
        [ [ 'board' ],                                        qr/field => value pairs/,         'an odd number of arguments' ],
    );
    for my $case (@refused) {
        my ($args, $why, $what) = @$case;
        ok(!eval { $V->custom(@$args); 1 }, "$what: croaks");
        like($@, $why, "$what: saying why");
    }
    ok(!eval { $V->named('grande'); 1 }, 'named croaks on a name that is not a board');
    ok(!eval { $V->new(name => 'sivy', cols => 9, rows => 5); 1 }, 'and new croaks whatever it is given');
    like($@, qr/made by named, custom or from_string/, 'saying how a variant is made');
    is($V->custom(board => 'sivy', repeat => 0, quiet_limit => 0)->repeat, 0, 'a repeat and a quiet limit of 0 are allowed: they mean never');
};

subtest 'as a string, and back' => sub {
    for my $string ('sivy', 'dimy', 'telo', '7x5', '9x3', 'sivy,quiet_limit=40', 'telo,repeat=0,ply_cap=50',
                    'dimy,start=bbbbb/bbbbb/bw1wb/wwwww/wwwww w', '7x5,quiet_limit=0,repeat=2,ply_cap=10,start=7/7/3w3/7/6b b') {
        my $v = $V->from_string($string);
        ok($v, "'$string' is a variant") or next;
        is($v->as_string, $string, 'and writes itself back');
    }
    is($V->from_string('5x5')->as_string, 'dimy', 'a named board given by its size writes its name');
    is($V->from_string('sivy,repeat=3')->as_string, 'sivy', 'a limit given at its default is not written');
    for my $bad (undef, '', 'grande', '8x5', 'sivy,', 'sivy,colour=red', 'sivy,quiet_limit', 'sivy,quiet_limit=x',
                 'sivy,repeat=1', 'sivy,quiet_limit=1,quiet_limit=2', 'sivy,start=9/9 w', [ 'sivy' ]) {
        is($V->from_string($bad), undef, 'not a variant: ' . (defined $bad ? "'$bad'" : 'undef'));
    }
};

done_testing();
