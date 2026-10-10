use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

# EVERY FLAG OF THE royalur PROGRAM, RUN. Sibling distributions have shipped
# flags that parsed and did nothing, because their tests checked that an option
# was accepted and not what it changed. Each flag here is run and judged on
# what came out, against the same run without it.
#
# The program is started with the perl running this test and a list of
# arguments, so no shell is involved and none is needed.

my $script = "$FindBin::Bin/../bin/royalur";
ok(-f $script, 'bin/royalur is there');

my @libs = map { "-I$_" } grep { !ref } @INC;
my @FIXED = ('--seed', '6661636164652034' . '36', '--first', 'light');

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

subtest '--version and --help' => sub {
    my ($said, $complained, $status) = run(['--version']);
    like($said, qr/\Aroyalur \d+\.\d+\n\z/, '--version: the name and the version, and nothing else');
    is($status, 0, 'exit 0');

    ($said, $complained, $status) = run(['--help']);
    is($status, 0, '--help: exit 0');
    like($said, qr/--$_\b/, "names --$_")
        for qw(mode rules level side first seed pace route record replay ascii unicode no-colour no-pick version help);
    unlike($said, qr/rolled/, 'and no game was started');
};

subtest 'what it does not understand' => sub {
    my ($said, $complained, $status) = run(['--nonsense']);
    is($status, 2, 'an unknown flag: exit 2');
    like($complained, qr/--mode HOW/, 'with the usage on STDERR');
    is($said, '', 'and nothing on STDOUT');

    ($said, $complained, $status) = run(['extra']);
    is($status, 2, 'a stray word: exit 2');
    like($complained, qr/I do not know 'extra'/, 'and it is named');

    for my $case ([ '--mode', 'solo' ], [ '--side', 'white' ], [ '--first', 'me' ], [ '--level', '9' ],
                  [ '--rules', 'bell' ], [ '--pace', 'fast' ], [ '--seed', 'xyz' ], [ '--seed', 'abc' ],
                  [ '--replay', '/no/such/file' ]) {
        my (undef, $why, $code) = run($case);
        is($code, 2, "@$case: exit 2");
        like($why, qr/\Aroyalur: .+\.\n\z/, "@$case: and one sentence saying why");
    }
};

subtest '--seed' => sub {
    my ($one) = run([@FIXED]);
    my ($two) = run([@FIXED]);
    is($two, $one, 'the same seed is the same screen');
    like($one, qr/You rolled 2   \. \^ \^ \./, 'and it is the seed asked for: "facade 46" opens with a 2');
    my ($other) = run([ '--seed', 'ff', '--first', 'light' ]);
    isnt($other, $one, 'another seed is another');
};

subtest '--first' => sub {
    my ($light) = run([ '--seed', '6661636164652031', '--first', 'light' ]);
    unlike($light, qr/To see who starts/, 'light: nothing is thrown for it');
    like($light, qr/^light \(\d\)> /m, 'and light is asked to move');
    my ($dark) = run([ '--seed', '6661636164652031', '--first', 'dark', '--mode', 'hotseat' ]);
    like($dark, qr/^dark \(\d\)> /m, 'dark: dark is');
    my ($roll) = run([ '--seed', '6661636164652031', '--first', 'roll', '--mode', 'hotseat' ]);
    like($roll, qr/To see who starts, light threw .* a tie, again\./, 'roll: the dice are thrown for it, tie and all');
    like($roll, qr/Dark moves first\./, 'and settle it');
    my ($default) = run([ '--seed', '6661636164652031', '--mode', 'hotseat' ]);
    is($default, $roll, 'and roll is what happens when nothing is said');
};

subtest '--mode' => sub {
    my ($bot) = run([@FIXED]);
    like($bot, qr/you are light, against level 4/, 'bot, the default: you against the program');
    my ($hotseat) = run([ @FIXED, '--mode', 'hotseat' ], "hand-c1\nquit\n");
    like($hotseat, qr/finkel, two players/, 'hotseat: two players');
    like($hotseat, qr/^dark \(1\)> /m, 'and dark is asked for its own move');
    my ($watch, undef, $status) = run([ @FIXED, '--mode', 'watch', '--level', '1' ], '');
    like($watch, qr/level 1 against itself/, 'watch: the program against itself');
    like($watch, qr/(?:Light|Dark) won, all 7 home/, 'to the end, with nobody typing');
    is($status, 0, 'and then it stops');
};

subtest '--side' => sub {
    my ($light) = run([ @FIXED, '--level', '1' ]);
    unlike($light, qr/ played /, 'light, the default: nobody has moved before you are asked');
    my ($dark) = run([ @FIXED, '--level', '1', '--side', 'dark' ]);
    like($dark, qr/Light played 2: hand-c1\./, 'dark: the program has light and has moved');
    like($dark, qr/you are dark/, 'and the title says so');
};

subtest '--level' => sub {
    my ($top) = run([@FIXED]);
    my ($one) = run([ @FIXED, '--level', '1' ]);
    like($top, qr/against level 4/, 'the default is the top of the ladder');
    like($one, qr/against level 1/, 'and --level 1 is level 1');

    my ($deep) = run([ @FIXED, '--mode', 'watch', '--level', '2' ], '');
    my ($shallow) = run([ @FIXED, '--mode', 'watch', '--level', '1' ], '');
    isnt($deep, $shallow, 'the same dice played at two levels are two different games');
};

subtest '--rules' => sub {
    my ($finkel) = run([@FIXED]);
    my ($masters) = run([ @FIXED, '--rules', 'masters' ]);
    like($finkel, qr/Royal Game of Ur   finkel,/, 'finkel is the default');
    like($masters, qr/Royal Game of Ur   masters,/, 'masters when asked');
    like($finkel, qr/rolled \d   [.^] [.^] [.^] [.^]$/m, 'finkel throws four dice');
    like($masters, qr/rolled \d   [.^] [.^] [.^](?:   \(nothing marked is worth four\))?$/m, 'and masters three');
};

subtest '--route' => sub {
    my ($without) = run([@FIXED]);
    my ($with) = run([ @FIXED, '--route' ]);
    unlike($without, qr/route, as/, 'not shown unless asked');
    like($with, qr/The short route, as light travels it:/, 'shown when asked');
    like($with, qr/^    1     4     3     2     1                14    13  $/m, 'with the steps of the short route in it');
    my ($long) = run([ @FIXED, '--route', '--rules', 'masters' ]);
    like($long, qr/^    1     4     3     2     1                16    15  $/m, 'and of the long one under masters');
};

subtest '--ascii and --unicode' => sub {
    my ($plain) = run([ @FIXED, '--ascii' ]);
    unlike($plain, qr/[^\x00-\x7F]/, '--ascii: not one byte outside ASCII');
    my ($wide) = run([ @FIXED, '--unicode' ]);
    like($wide, qr/\xE2\x97\x8F/, '--unicode: a light piece is a filled disc, in UTF-8');
    like($wide, qr/\xE2\x95\xAD/, 'and the board has a rounded corner');
    my ($neither) = run([@FIXED]);
    is($neither, $plain, 'into a pipe, plain is what you get when neither is said');
    my ($off) = run([ @FIXED, '--no-unicode' ]);
    is($off, $plain, 'and --no-unicode is --ascii');
};

subtest '--colour and --no-colour' => sub {
    my ($painted) = run([ @FIXED, '--colour' ]);
    like($painted, qr/\e\[1;38;5;220mThe Royal Game of Ur\e\[0m/, '--colour: the title is painted');
    my ($bare) = run([ @FIXED, '--no-colour' ]);
    unlike($bare, qr/\e\[/, '--no-colour: not one escape');
    my ($american) = run([ @FIXED, '--color' ]);
    is($american, $painted, 'and --color is --colour');
    (my $stripped = $painted) =~ s/\e\[[0-9;]*m//g;
    is($stripped, $bare, 'with the colour taken out, the painted screen IS the bare one');
};

# Into a pipe there is no keyboard to take over, so --no-pick cannot change
# what a pipe sees; what picking does is t/25's, at the terminal. What this
# can show is that the flag is taken and that the pipe is read as lines.
subtest '--no-pick' => sub {
    my ($said, $complained, $status) = run([ @FIXED, '--no-pick', '--mode', 'hotseat' ], "1\nquit\n");
    is($status, 0, 'it is taken');
    like($said, qr/Light played 2: hand-c1\./, 'and a typed number is a move');
};

# The pace holds a screen in a terminal. Into a pipe nothing is held, so what
# this can show is that a number is taken and a word is not; that the pace is
# kept is t/25's, which counts the waits.
subtest '--pace' => sub {
    my (undef, undef, $status) = run([ @FIXED, '--pace', '0.25' ]);
    is($status, 0, 'a number of seconds is taken');
    (undef, undef, $status) = run([ @FIXED, '--pace', '-1' ]);
    is($status, 2, 'a negative one is not');
};

subtest '--record and --replay' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $file = "$dir/game.txt";
    my ($said, undef, $status) = run([ @FIXED, '--mode', 'hotseat', '--record', $file ], "hand-c1\n1\nquit\n");
    is($status, 0, 'a game is played and left');
    ok(-s $file, '--record: the file is written on leaving');
    open my $fh, '<', $file or die "cannot read $file: $!";
    my $record = do { local $/; <$fh> };
    close $fh;
    like($record, qr/\A\[rules finkel\]\n\[first light\]\n\[seed 666163616465203436\]\n1\. l 2 0110: hand-c1\n2\. d 0 0000: -\n3\. l 0 0000: -\n4\. d 1 0001: hand-d3\n\z/,
        'and it is the game: the rules, the seed, every turn with its dice');

    my ($without) = run([ @FIXED, '--mode', 'hotseat' ], "moves\nquit\n");
    unlike($without, qr/^    1: hand-d3$/m, 'a new game has no fourth turn');
    my ($carried) = run([ '--mode', 'hotseat', '--replay', $file ], "moves\nquit\n");
    like($carried, qr/^    2: hand-c1\n    0: -\n    0: -\n    1: hand-d3$/m, '--replay: the four turns are there to list');
    like($carried, qr/^  3 \|\*    \|     \|     \| _\@_ \|/m, 'and the board is as it was left');

    open my $bad, '>', "$dir/bad.txt" or die;
    print {$bad} "[rules finkel]\n[first light]\n1. l 4: hand-b1\n";
    close $bad;
    my (undef, $why, $code) = run([ '--replay', "$dir/bad.txt" ]);
    is($code, 2, 'a record that is not a game: exit 2');
    like($why, qr/is not a game I can replay: .*\(turn 1\)\./, 'saying which turn');
};

done_testing();
