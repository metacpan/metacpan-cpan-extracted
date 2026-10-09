use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

# EVERY FLAG OF THE brandubh PROGRAM, RUN. Two sibling distributions each
# shipped four flags that parsed and did nothing, because their tests checked
# that an option was accepted and not what it changed. Each flag here is run
# and judged on what came out.
#
# The program is started with the perl running this test and a list of
# arguments, so no shell is involved and none is needed.

my $script = "$FindBin::Bin/../bin/brandubh";
ok(-f $script, 'bin/brandubh is there');

my @libs = map { "-I$_" } grep { !ref } @INC;

sub run {
    my ($args, $typed) = @_;
    my ($in, $out);
    my $err = gensym;
    local $ENV{NO_COLOR};
    delete $ENV{NO_COLOR};
    my $pid = open3($in, $out, $err, $^X, @libs, $script, @$args);
    binmode $_ for $in, $out, $err;
    print {$in} defined $typed ? $typed : "quit\n";
    close $in;
    my $said = do { local $/; <$out> };
    my $complained = do { local $/; <$err> };
    waitpid $pid, 0;
    return ($said // '', $complained // '', $? >> 8);
}

subtest '--version' => sub {
    my ($said, $complained, $status) = run(['--version']);
    like($said, qr/\Abrandubh \d+\.\d+\n\z/, 'the name and the version, and nothing else');
    is($status, 0, 'exit 0');
    unlike($said, qr/attackers>/, 'and no game was started');
};

subtest '--help' => sub {
    my ($said, $complained, $status) = run(['--help']);
    is($status, 0, 'exit 0');
    like($said, qr/--$_\b/, "names --$_")
        for qw(side level variant seed load no-colour no-pick no-unicode version help);
    unlike($said, qr/attackers>/, 'and no game was started');
};

subtest '--side' => sub {
    my ($said) = run([ '--side', 'defenders', '--level', '1' ]);
    like($said, qr/The attackers played /, 'defenders: the program has the attackers, and moves first');
    like($said, qr/The defenders to move: you\./, 'and then it is your move');

    ($said) = run([ '--side', 'attackers', '--level', '1' ]);
    like($said, qr/The attackers to move: you\./, 'attackers: your move first');
    unlike($said, qr/ played /, 'and the program has not moved');

    ($said) = run([ '--side', 'both' ], "d1c1\nquit\n");
    like($said, qr/The defenders to move: either of you\./, 'both: after one move it is still a person\'s turn');
    unlike($said, qr/ played /, 'and the program never moves');

    ($said) = run([ '--side', 'none', '--level', '1', '--variant', 'custom ply_cap=40' ], '');
    my @told = $said =~ /^The (?:attackers|defenders) played /mg;
    cmp_ok(scalar(@told), '>', 3, 'none: the program plays both sides, ' . scalar(@told) . ' moves of them');

    my (undef, $complained, $status) = run([ '--side', 'kings' ]);
    is($status, 2, 'a side that is not one: exit 2');
    like($complained, qr/brandubh: side is attackers, defenders, both or none, not 'kings'\./, 'and a sentence saying what a side is');
};

subtest '--level' => sub {
    for my $level (1, 3) {
        my ($said) = run([ '--side', 'attackers', '--level', $level ], "d1c1\nquit\n");
        like($said, qr/You have the attackers; the program has the defenders, at level $level\./,
            "level $level is the level the program is said to play at");
    }
    my ($one) = run([ '--side', 'attackers', '--level', '1', '--seed', 'ab' x 32 ], "moves\nquit\n");
    my (undef, $complained, $status) = run([ '--level', '9' ]);
    is($status, 2, 'a level that is not one: exit 2');
    like($complained, qr/brandubh: level is 1, 2 or 3\./, 'and a sentence');
    (undef, $complained, $status) = run([ '--level', 'hard' ]);
    is($status, 2, 'a level in words: exit 2');
};

subtest '--seed' => sub {
    my @args = ('--side', 'none', '--level', '1', '--variant', 'custom ply_cap=50');
    my ($first)  = run([ @args, '--seed', '11' x 32 ], '');
    my ($again)  = run([ @args, '--seed', '11' x 32 ], '');
    my ($other)  = run([ @args, '--seed', '22' x 32 ], '');
    cmp_ok(length $first, '>', 500, 'a whole game was played');
    is($again, $first, 'the same seed plays the same game, to the character');
    isnt($other, $first, 'and another seed plays another');

    my (undef, $complained, $status) = run([ '--seed', 'abc' ]);
    is($status, 2, 'a seed too short: exit 2');
    like($complained, qr/a seed is sixty-four hexadecimal characters/, 'and a sentence');
    (undef, $complained, $status) = run([ '--seed', 'zz' x 32 ]);
    is($status, 2, 'a seed that is not hexadecimal: exit 2');
};

subtest '--variant' => sub {
    my ($said) = run([ '--side', 'both', '--variant', 'custom repeat=2' ], "rules\nquit\n");
    like($said, qr/comes round for the second time/, 'the rule set given is the one the rules page describes');
    ($said) = run([ '--side', 'both' ], "rules\nquit\n");
    like($said, qr/comes round for the third time/, 'and without it, the default');

    ($said) = run([ '--side', 'both', '--variant', 'custom repeat=2' ], "a4a3\nc4c3\na3a4\nc3c4\nquit\n");
    like($said, qr/The same position has come round once too often/, 'and it is the rule set the game is played under');

    my (undef, $complained, $status) = run([ '--variant', 'tablut' ]);
    is($status, 2, 'a rule set nobody has heard of: exit 2');
    like($complained, qr/brandubh: 'tablut' is not a rule set\./, 'and a sentence');
};

subtest '--load' => sub {
    my $dir = tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/saved.txt" or die;
    print {$fh} "variant brandubh\nmoves d1c1 d3c3\n";
    close $fh;

    my ($said, $complained, $status) = run([ '--side', 'both', '--load', "$dir/saved.txt" ], "c1d1\nquit\n");
    is($status, 0, 'exit 0');
    like($said, qr/Loaded .*saved\.txt: 2 moves\./, 'the game is loaded');
    like($said, qr/1\. d1-c1  2\. d3-c3  3\. c1-d1/, 'and carried on from');

    ($said, $complained, $status) = run([ '--load', "$dir/missing.txt" ]);
    is($status, 2, 'a file that is not there: exit 2');
    like($said . $complained, qr/Cannot read .*missing\.txt/, 'and it says which');
};

subtest '--colour and --no-colour' => sub {
    my ($plain) = run([ '--side', 'both' ]);
    unlike($plain, qr/\e\[/, 'into a pipe there is no colour unless it is asked for');

    my ($painted) = run([ '--side', 'both', '--colour' ]);
    like($painted, qr/\e\[48;5;\d+/, '--colour paints the squares even into a pipe');

    my ($american) = run([ '--side', 'both', '--color' ]);
    like($american, qr/\e\[48;5;\d+/, '--color is the same flag');

    my ($off) = run([ '--side', 'both', '--colour', '--no-colour' ]);
    unlike($off, qr/\e\[/, '--no-colour turns it off again');
};

subtest '--unicode and --no-unicode' => sub {
    my ($drawn) = run([ '--side', 'both', '--colour' ]);
    like($drawn, qr/\xE2\x96\xB2/, 'with colour the attackers are triangles');
    my ($letters) = run([ '--side', 'both', '--colour', '--no-unicode' ]);
    unlike($letters, qr/[^\x00-\x7F]/, '--no-unicode keeps the colour and writes nothing outside ASCII');
    like($letters, qr/\e\[48;5;\d+;[0-9;]+m  A  \e\[0m/, 'the attacker is a painted A');
    my ($both) = run([ '--side', 'both', '--unicode' ]);
    like($both, qr/\xE2\x96\xB2|\xC2\xB7/, '--unicode draws the pieces without colour');
};

subtest '--pick and --no-pick' => sub {
    my ($typed) = run([ '--side', 'both', '--no-pick' ], "d1c1\nquit\n");
    like($typed, qr/1\. d1-c1/, '--no-pick: moves are typed');
    my ($asked) = run([ '--side', 'both', '--pick' ], "d1c1\nquit\n");
    like($asked, qr/1\. d1-c1/, '--pick into a pipe, where there are no keys to read: it falls back to typing and still plays');
    unlike($asked, qr/\e\[\?25l/, 'and does not hide a cursor it has no terminal to hide');
};

subtest 'with no side and no level, and nobody at a keyboard' => sub {
    my ($said, $complained, $status) = run([], "d1c1\nquit\n");
    is($status, 0, 'exit 0');
    unlike($said, qr/Which side will you take/, 'the opening question is for a terminal, and is not asked of a pipe');
    like($said, qr/The attackers to move: you\./, 'it goes straight to the game');
};

subtest 'what it will not take' => sub {
    my ($said, $complained, $status) = run(['--frobnicate']);
    is($status, 2, 'an option it does not have: exit 2');
    like($complained, qr/--side WHO/, 'and the usage, on the error stream');
    is($said, '', 'with nothing on the other one');

    ($said, $complained, $status) = run([ 'd1c1' ]);
    is($status, 2, 'a stray word: exit 2');
    like($complained, qr/brandubh: I do not know 'd1c1'\./, 'and it says which word');
};

done_testing();
