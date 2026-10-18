use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

my ($exits, $catching);
BEGIN { *CORE::GLOBAL::exit = sub { $exits++; die "exit was called\n" if $catching; CORE::exit(@_) } }

use Game::Senet::Terminal;

# EVERY FLAG OF THE senet PROGRAM, RUN, plan_game_senet/08. Sibling dists have
# shipped flags that parsed and did nothing, because their tests checked that
# an option was accepted and not what it changed. Each flag here is run and
# judged on what came out, against the same run without it.
#
# The program is started with the perl running this test and a list of
# arguments: no shell, and no -e carrying a double quote, which never reaches
# the child on Windows.

my $script = "$FindBin::Bin/../bin/senet";
ok(-f $script, 'bin/senet is there');

my @libs = map { "-I$_" } grep { !ref } @INC;
my @FIXED = ('--seed', unpack('H*', 'senet bin'));

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
    my ($said, undef, $status) = run(['--version']);
    like($said, qr/\Asenet \d+\.\d+\n\z/, '--version: the name and the version, and nothing else');
    is($status, 0, 'exit 0');
    ($said, undef, $status) = run(['--help']);
    is($status, 0, '--help: exit 0');
    like($said, qr/--$_\b/, "names --$_")
        for qw(mode rules pieces level side first seed pace record replay ascii unicode no-colour no-pick version help);
    like($said, qr/\Asenet - /, 'the usage names senet, never $0');
    unlike($said, qr/threw/, 'and no game was started');
};

subtest 'what it does not understand' => sub {
    my ($said, $complained, $status) = run(['--nonsense']);
    is($status, 2, 'an unknown flag: exit 2');
    like($complained, qr/--mode HOW/, 'with the usage on STDERR');
    is($said, '', 'and nothing on STDOUT');
    ($said, $complained, $status) = run(['extra']);
    is($status, 2, 'a stray word: exit 2');
    like($complained, qr/I do not know 'extra'/, 'and it is named');
    for my $case ([ '--mode', 'solo' ], [ '--side', 'white' ], [ '--first', 'me' ], [ '--pieces', '6' ],
                  [ '--rules', 'bell' ], [ '--pace', 'fast' ], [ '--seed', 'xyz' ], [ '--seed', 'abc' ],
                  [ '--level', '0' ], [ '--replay', '/no/such/file' ]) {
        my (undef, $why, $code) = run($case);
        is($code, 2, "@$case: exit 2");
        like($why, qr/\Asenet: .+\.\n\z/, "@$case: and one sentence saying why");
    }
};

subtest '--seed' => sub {
    my ($one) = run([@FIXED]);
    my ($two) = run([@FIXED]);
    is($two, $one, 'the same seed is the same screen');
    my ($other) = run([ '--seed', 'ff' ]);
    isnt($other, $one, 'another seed is another');
};

subtest '--first' => sub {
    my ($light) = run([ @FIXED, '--mode', 'hotseat' ]);
    like($light, qr/^light \(\d\)> /m, 'light, the default, is asked first');
    my ($dark) = run([ @FIXED, '--mode', 'hotseat', '--first', 'dark' ]);
    like($dark, qr/^dark \(\d\)> /m, 'dark when asked');
};

subtest '--mode' => sub {
    my ($bot) = run([@FIXED]);
    like($bot, qr/you are light, against level 4/, 'bot, the default: you against the top of the ladder');
    my ($hotseat) = run([ @FIXED, '--mode', 'hotseat' ], "1\nquit\n");
    like($hotseat, qr/kendall, two players/, 'hotseat: two players');
    my ($watch, undef, $status) = run([ @FIXED, '--mode', 'watch', '--level', '1' ], '');
    like($watch, qr/level 1 against itself/, 'watch: the program against itself');
    like($watch, qr/(?:Light|Dark) won, all 5 home/, 'to the end, with nobody typing');
    is($status, 0, 'and then it stops');
};

subtest '--side' => sub {
    my ($light) = run([ @FIXED, '--level', '1' ]);
    unlike($light, qr/ played /, 'light, the default: nobody has moved before you are asked');
    my ($dark) = run([ @FIXED, '--level', '1', '--side', 'dark' ]);
    like($dark, qr/Light played \d: /, 'dark: the program has light and has moved');
    like($dark, qr/you are dark/, 'and the title says so');
};

subtest '--level' => sub {
    my ($one) = run([ @FIXED, '--level', '1' ]);
    like($one, qr/against level 1/, '--level 1 is level 1');
    my ($high) = run([ @FIXED, '--level', '9' ]);
    like($high, qr/against level 4/, 'above the top of kendall\'s ladder plays the top');
    my ($sky) = run([ @FIXED, '--level', '9', '--rules', 'skyruk' ]);
    like($sky, qr/against level 3/, 'and skyruk\'s top is 3');
    my ($deep) = run([ @FIXED, '--mode', 'watch', '--level', '3' ], '');
    my ($shallow) = run([ @FIXED, '--mode', 'watch', '--level', '1' ], '');
    isnt($deep, $shallow, 'the same sticks played at two levels are two different games');
};

subtest '--rules' => sub {
    my ($kendall) = run([@FIXED]);
    my ($skyruk) = run([ @FIXED, '--rules', 'skyruk' ]);
    like($kendall, qr/Senet   kendall,/, 'kendall is the default');
    like($skyruk, qr/Senet   skyruk,/, 'skyruk when asked');
    my ($kw) = run([ @FIXED, '--mode', 'watch', '--level', '1' ], '');
    my ($sw) = run([ @FIXED, '--mode', 'watch', '--level', '1', '--rules', 'skyruk' ], '');
    isnt($sw, $kw, 'and the two play two different games on the same sticks');
};

subtest '--pieces' => sub {
    my ($five) = run([@FIXED]);
    my ($seven) = run([ @FIXED, '--pieces', '7' ]);
    like($seven, qr/kendall pieces=7/, 'seven when asked, and the title says so');
    my @five = $five =~ /\|  [O@]   /g;
    my @seven = $seven =~ /\|  [O@]   /g;
    is(scalar @five, 10, 'five a side: ten pieces on the board');
    is(scalar @seven, 14, 'seven a side: fourteen');
};

subtest '--ascii and --unicode' => sub {
    my ($plain) = run([ @FIXED, '--ascii' ]);
    unlike($plain, qr/[^\x00-\x7F]/, '--ascii: not one byte outside ASCII');
    my ($wide) = run([ @FIXED, '--unicode' ]);
    like($wide, qr/\xE2\x97\x8F/, '--unicode: a light piece is a filled disc, in UTF-8');
    like($wide, qr/\xE2\x98\xA5/, 'and 15 has its ankh');
    my ($neither) = run([@FIXED]);
    is($neither, $plain, 'into a pipe, plain is what you get when neither is said');
};

subtest '--colour and --no-colour' => sub {
    my ($painted) = run([ @FIXED, '--colour' ]);
    like($painted, qr/\e\[1;38;5;220mSenet\e\[0m/, '--colour: the title is painted');
    my ($bare) = run([ @FIXED, '--no-colour' ]);
    unlike($bare, qr/\e\[/, '--no-colour: not one escape');
    my ($american) = run([ @FIXED, '--color' ]);
    is($american, $painted, 'and --color is --colour');
    (my $stripped = $painted) =~ s/\e\[[0-9;]*m//g;
    is($stripped, $bare, 'with the colour taken out, the painted screen IS the bare one');
};

# Into a pipe there is no keyboard to take over, so --no-pick and --pace cannot
# change what a pipe sees; what they do at a terminal is t/29's, which drives
# the keys and counts the waits through the sleeper. This shows the flags are
# taken and the pipe read as lines.
subtest '--no-pick and --pace' => sub {
    my ($said, undef, $status) = run([ @FIXED, '--no-pick', '--mode', 'hotseat' ], "1\nquit\n");
    is($status, 0, '--no-pick is taken');
    like($said, qr/Light played \d: /, 'and a typed number is a move');
    (undef, undef, $status) = run([ @FIXED, '--pace', '0.25' ]);
    is($status, 0, '--pace 0.25 is taken');
    (undef, undef, $status) = run([ @FIXED, '--pace', '-1' ]);
    is($status, 2, 'and a negative one is not');
};

subtest '--record and --replay' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $file = "$dir/game.txt";
    my (undef, undef, $status) = run([ @FIXED, '--mode', 'hotseat', '--record', $file ], "1\n1\nquit\n");
    is($status, 0, 'a game is played and left');
    ok(-s $file, '--record: the file is written on leaving');
    open my $fh, '<', $file or die "cannot read $file: $!";
    my $record = do { local $/; <$fh> };
    close $fh;
    like($record, qr/\A\[variant kendall pieces=5 blockade=3 protect=run backward=1 reach26=exact throw_on_26=0\]\n\[first light\]\n\[seed [0-9a-f]+\]\n1\. l \d [01]{4}: \d+-\d+\n2\. [ld] \d [01]{4}: /,
        'and it is the game: the variant, the seed, every ply with its sticks');
    my ($carried) = run([ '--mode', 'hotseat', '--replay', $file ], "moves\nquit\n");
    my @moves = $carried =~ /^     \d: \S+/mg;
    cmp_ok(scalar @moves, '>=', 2, '--replay: the plies are there to list');

    open my $bad, '>', "$dir/bad.txt" or die;
    print {$bad} "[variant kendall pieces=5 blockade=3 protect=run backward=1 reach26=exact throw_on_26=0]\n[first light]\n1. l 4: 1-5\n";
    close $bad;
    my (undef, $why, $code) = run([ '--replay', "$dir/bad.txt" ]);
    is($code, 2, 'a record that is not a game: exit 2');
    like($why, qr/is not a game I can replay: .*\(ply 1\)\./, 'saying which ply');
};

subtest 'run returns, and never calls exit' => sub {
    $exits = 0;
    open my $null, '>', File::Spec->devnull or die;
    my $old = select $null;
    local *STDOUT = $null;
    local *STDERR = $null;
    $catching = 1;
    my @status = map { my $arg = $_; my $s = eval { Game::Senet::Terminal->run($arg) }; defined $s ? $s : 'died' }
        '--help', '--version', '--nonsense';
    $catching = 0;
    select $old;
    is_deeply(\@status, [ 0, 0, 2 ], 'run answers 0, 0 and 2');
    is($exits, 0, 'and exit was never called, here, by run');
};

done_testing();
