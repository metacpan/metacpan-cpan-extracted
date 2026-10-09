#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use File::Temp ();
use Test::More;

use Game::Merrills;
use Game::Merrills::Bot;
use Game::Merrills::Test::Position qw/position_of/;

my $script = 'bin/merrills';

plan skip_all => "$script is not here, so this is not the distribution root"
	unless -f $script;

# The script is run as a process, but never an interactive one: everything it
# is asked to do here either prints and stops or reads its moves from a file.
#
# No shell is involved. The arguments go straight to the child, so a position
# does not have to survive a round of quoting, and the input arrives on a
# handle and not through a pipeline. cmd.exe has neither the quoting nor a
# printf, and a version of this that needed them failed there.
#
# EVERY FLAG IN --help HAS A SUBTEST THAT SHOWS IT DOING SOMETHING: the same
# run with the flag and without it, differing in the way the flag says. A
# flag that is only accepted is not tested.
sub run {
	my (@argument) = @_;
	my $input = ref $argument[0] eq 'ARRAY' ? shift @argument : [];

	my $stdin = File::Temp->new;
	binmode $stdin;
	print {$stdin} map { "$_\n" } @{$input};
	close $stdin;

	my $stdout = File::Temp->new;
	close $stdout;

	open my $old_in, '<&', \*STDIN or die "cannot save STDIN: $!";
	open my $old_out, '>&', \*STDOUT or die "cannot save STDOUT: $!";
	open my $old_err, '>&', \*STDERR or die "cannot save STDERR: $!";

	open STDIN, '<', $stdin->filename or die "cannot read the input: $!";
	open STDOUT, '>', $stdout->filename or die "cannot write the output: $!";
	open STDERR, '>&', \*STDOUT or die "cannot merge STDERR: $!";

	my $failed = system $^X, '-Ilib', $script, @argument;
	my $status = $failed == -1 ? -1 : $? >> 8;

	open STDIN, '<&', $old_in or die "cannot restore STDIN: $!";
	open STDOUT, '>&', $old_out or die "cannot restore STDOUT: $!";
	open STDERR, '>&', $old_err or die "cannot restore STDERR: $!";

	my $output = do {
		open my $fh, '<', $stdout->filename or die "cannot read the output: $!";
		local $/;
		readline $fh;
	};

	return (defined $output ? $output : '', $status);
}

my @PLAIN = qw/--ascii --no-colour/;
my $THREE = position_of(white => [qw/a7 d5 g1/], black => [qw/b6 f4 d2 c3/]);
my $WINNING = position_of(white => [qw/a7 d7 g4 c3 e3/], black => [qw/b2 d2 e5/]);

subtest '--version and --help' => sub {
	my ($version, $status) = run('--version');
	is($version, "merrills $Game::Merrills::VERSION\n", '--version prints the name and the version');
	is($status, 0, 'and exits 0');
	is((run('-v'))[0], $version, '-v is the same');

	my ($help, $helped) = run('--help');
	is($helped, 0, '--help exits 0');
	like($help, qr/\Amerrills - play Nine Men's Morris\n\nUsage: merrills \[options\]\n/, 'and begins with what it is');
	is((run('-h'))[0], $help, '-h is the same');
	my $limit = Game::Merrills::NO_MILL_PLIES;
	like($help, qr/or $limit moves without a mill/, 'the draw limit in the help is read out of the engine');
	my @levels = Game::Merrills::Bot->levels;
	like($help, qr/the bot's strength, $levels[0] to $levels[-1] /, 'and so are the levels');
	unlike($help, qr/[ \t]\n/, 'no line of it ends in a space');
	unlike($help, qr/[^\x0a\x20-\x7e]/, 'and it is plain ASCII');
};

subtest 'every flag the help offers is one this file tests' => sub {
	my ($help) = run('--help');
	my @offered = sort { $a cmp $b } keys %{ { map { $_ => 1 } $help =~ m/^\s+(?:-\w, )?(--[a-z-]+)/mg } };
	is_deeply(\@offered, [ sort qw/--ascii --bot-vs-bot --colour --help --hotseat --level --load
		--no-flying --no-pick --position --replay --seed --side --version/ ],
		'fourteen flags, and each has a subtest below by name');
	open my $self, '<', $0 or die $!;
	my $source = do { local $/; <$self> };
	close $self;
	for my $flag (@offered) {
		like($source, qr/^subtest '[^'\n]*\Q$flag\E\b/m, "$flag has a subtest named for it");
	}
};

subtest '--level sets the strength of the bot' => sub {
	my ($default) = run(@PLAIN);
	like($default, qr/^White: you\. Black: the bot at level 3\.$/m, 'without it, level 3');
	my ($set) = run(@PLAIN, '--level', 1);
	like($set, qr/^White: you\. Black: the bot at level 1\.$/m, 'with it, the level asked for');
	my ($short) = run(@PLAIN, '-l', 2);
	like($short, qr/the bot at level 2\./, '-l is the same');

	my ($weak, $strong) = map { (run([ 'd2', 'hint' ], @PLAIN, '--seed', 1, '--level', $_))[0] } 1, 3;
	isnt($weak, $strong, 'and a level 1 bot and a level 3 bot do not play the same game');
};

subtest '--side chooses which side is yours' => sub {
	my ($white) = run(@PLAIN, '--level', 1);
	like($white, qr/^White \(you\) to place, 9 in hand\.$/m, 'without it you are white and move first');
	unlike($white, qr/^Black placed/m, 'so nothing has been played before your prompt');

	my ($black) = run(@PLAIN, '--level', 1, '--side', 'black');
	like($black, qr/^Black: you\. White: the bot at level 1\.$/m, 'with black you are black');
	like($black, qr/^White placed a man on \w\w\.$/m, 'and the bot has opened before you are asked');
	like($black, qr/^black> $/m, 'at a prompt for black');

	my %side;
	for my $seed (1 .. 6) {
		my ($random) = run(@PLAIN, '--level', 1, '--side', 'random', '--seed', $seed);
		my ($you) = $random =~ m/^(White|Black): you\./m;
		$side{ $you || 'nobody' }++;
		is((run(@PLAIN, '--level', 1, '--side', 'random', '--seed', $seed))[0], $random,
			"seed $seed: random with a seed is the same side every time") if $seed < 3;
	}
	is_deeply([ sort keys %side ], [qw/Black White/], 'random gives white for some seeds and black for others');
};

subtest '--hotseat is two people and no bot' => sub {
	my ($bot) = run([ 'd2' ], @PLAIN, '--level', 1);
	like($bot, qr/^Black placed a man/m, 'without it the bot answers your move');
	my ($hotseat, $status) = run([ 'd2', 'f4' ], @PLAIN, '--hotseat');
	like($hotseat, qr/^White and Black: two people at one keyboard\.$/m, 'with it there are two of you');
	like($hotseat, qr/^black> f4$/m, 'and black is asked for a move');
	like($hotseat, qr/^Black placed a man on f4\.$/m, 'and makes the one typed');
	is($status, 0, 'exit 0');
};

subtest '--bot-vs-bot plays itself out' => sub {
	my ($game, $status) = run(@PLAIN, '--bot-vs-bot', '--level', 1, '--seed', 7);
	like($game, qr/^White: the bot at level 1\. Black: the bot at level 1\.$/m, 'two bots');
	like($game, qr/^(?:White|Black) wins: |^Draw: /m, 'and a result, with nobody typing');
	unlike($game, qr/> |Bye/, 'no prompt and no goodbye');
	is($status, 0, 'exit 0 whoever won');

	my ($uneven) = run(@PLAIN, '--bot-vs-bot', '--level', 2, '--level', 1, '--seed', 7);
	like($uneven, qr/^White: the bot at level 2\. Black: the bot at level 1\.$/m,
		'--level twice is white then black');
};

subtest '--seed makes a game repeatable' => sub {
	my @run = (@PLAIN, '--bot-vs-bot', '--level', 1);
	my ($one) = run(@run, '--seed', 11);
	my ($again) = run(@run, '--seed', 11);
	my ($other) = run(@run, '--seed', 12);
	is($again, $one, 'the same seed is the same game, to the byte');
	isnt($other, $one, 'and another seed is another game');
};

subtest '--position begins from a position' => sub {
	my ($empty) = run([ 'position' ], @PLAIN, '--hotseat');
	like($empty, qr/^\.{24} w 9 9 0 0$/m, 'without it the board is empty');
	my ($set) = run([ 'position' ], @PLAIN, '--hotseat', '--position', $THREE);
	like($set, qr/^\Q$THREE\E$/m, 'with it the game is where it was put');
	like($set, qr/^White to move, and flying\.$/m, 'and is played from there');
};

subtest '--no-flying keeps three men to the lines' => sub {
	my ($flying) = run([ 'moves' ], @PLAIN, '--hotseat', '--position', $THREE);
	like($flying, qr/^5[1-4]\. /m, 'without it three men have 54 moves');
	like($flying, qr/and flying\.$/m, 'and are said to be flying');
	my ($walking) = run([ 'moves' ], @PLAIN, '--hotseat', '--position', $THREE, '--no-flying');
	like($walking, qr/ 7\. \S+$/m, 'with it they have seven');
	unlike($walking, qr/\b8\. /, 'and no more');
	unlike($walking, qr/and flying\.$/m, 'and nobody is flying');
	like($walking, qr/No flying\.$/m, 'and the game says so at the start');
};

subtest '--load and --replay read a game that save wrote' => sub {
	my $dir = File::Temp->newdir;
	my $file = "$dir/game.txt";
	run([ 'd2', 'f4', 'd6', "save $file" ], @PLAIN, '--hotseat');
	ok(-s $file, 'a game was saved');

	my ($fresh) = run([ 'position' ], @PLAIN, '--hotseat');
	my ($loaded, $status) = run([ 'position', 'b4' ], @PLAIN, '--hotseat', '--load', $file);
	isnt($loaded, $fresh, '--load does not begin from the empty board');
	like($loaded, qr/^\S{24} b 7 8 0 3$/m, 'it begins three moves in, with black to move');
	like($loaded, qr/^Black placed a man on b4\.$/m, 'and carries on');
	is($status, 0, 'exit 0');

	my ($replay, $replayed) = run(@PLAIN, '--replay', $file);
	is(scalar(() = $replay =~ m/^7 [ (]/mg), 4, '--replay draws the board at the start and after each of three moves');
	like($replay, qr/^White placed a man on d2\.$/m, 'saying each in words');
	unlike($replay, qr/> |Bye|you\./, 'and asks for nothing: it is not a game being played');
	is($replayed, 0, 'exit 0');
};

subtest '--ascii keeps to plain ASCII' => sub {
	my ($drawn) = run('--no-colour', '--hotseat');
	like($drawn, qr/[^\x00-\x7f]/, 'without it the board is drawn with characters beyond ASCII');
	my ($ascii) = run('--no-colour', '--hotseat', '--ascii');
	unlike($ascii, qr/[^\x0a\x20-\x7e]/, 'with it every byte is printable ASCII');
	like($ascii, qr/^7  \.-{11}\.-{11}\.$/m, 'dots and dashes');
	is((run('--no-colour', '--hotseat', '-a'))[0], $ascii, '-a is the same');
};

subtest '--colour paints, and --no-colour never does' => sub {
	my ($default) = run('--ascii', '--hotseat');
	unlike($default, qr/\e/, 'off a terminal, without it, nothing is painted');
	my ($painted) = run('--ascii', '--hotseat', '--colour');
	like($painted, qr/\e\[[0-9;]+m/, 'with it the output is painted even off a terminal');
	(my $bare = $painted) =~ s/\e\[[0-9;]*m//g;
	like($bare, qr/^7  \.-{11}\.-{11}\./m, 'and under the paint it is the same board');
	my ($american) = run('--ascii', '--hotseat', '--color');
	is($american, $painted, '--color is the same');
	my ($off) = run('--ascii', '--hotseat', '--no-colour');
	unlike($off, qr/\e/, '--no-colour has none');
};

subtest '--no-pick types the moves, and off a terminal that is all there is' => sub {
	my ($typed) = run([ 'd2' ], @PLAIN, '--hotseat', '--no-pick');
	like($typed, qr/^white> d2$/m, 'with --no-pick the move is typed at a prompt');
	my ($asked) = run([ 'd2' ], @PLAIN, '--hotseat', '--pick');
	is($asked, $typed, 'and off a terminal --pick changes nothing: there are no keys to read');
	unlike($asked, qr/arrows move/, 'so no choosing screen is drawn');
};

subtest 'the picker, on a real terminal' => sub {
	plan skip_all => 'needs a pseudo-terminal: set AUTHOR_TESTING on macOS or a BSD with Term::ReadKey'
		unless $ENV{AUTHOR_TESTING} && $^O =~ m/^(?:darwin|freebsd|openbsd|netbsd)$/
			&& eval { require Term::ReadKey; 1 } && -x '/usr/bin/script';

	my $pty = sub {
		my (@argument) = @_;
		my $out = File::Temp->new;
		my $pid = open my $keys, '|-';
		die "cannot fork: $!" unless defined $pid;
		unless ($pid) {
			open STDOUT, '>', $out->filename or die $!;
			open STDERR, '>&', \*STDOUT or die $!;
			exec '/usr/bin/script', '-q', '/dev/null', $^X, '-Ilib', $script, @argument;
			die "cannot exec script: $!";
		}
		select((select($keys), $| = 1)[0]);
		for my $key ("\r", "\r", 'q', "y\r") {
			select undef, undef, undef, 0.8;
			print {$keys} $key;
		}
		select undef, undef, undef, 0.8;
		close $keys;
		open my $fh, '<', $out->filename or die $!;
		local $/;
		return scalar readline $fh;
	};

	my $picked = $pty->('--hotseat', '--ascii');
	like($picked, qr/arrows.*move.*tab.*next/, 'without --no-pick a terminal gets the choosing screen');
	like($picked, qr/Choose a point to place a man on\./, 'asking for a point');
	like($picked, qr/Black placed a man on/, 'and two enters place two men');

	my $typed = $pty->('--hotseat', '--ascii', '--no-pick');
	unlike($typed, qr/Choose a point to place a man on\./, 'with --no-pick the same terminal gets a prompt');
	like($typed, qr/white>/, 'to type at');
};

subtest 'a bad option says why, shows the usage, and exits 2' => sub {
	my @bad = (
		[ [ '--level', 9 ], qr/^merrills: --level takes a number from 1 to 5, not '9'$/m ],
		[ [ '--level', 'x' ], qr/^merrills: --level takes a number from 1 to 5, not 'x'$/m ],
		[ [ '--level', 1, '--level', 2 ], qr/^merrills: --level twice is for --bot-vs-bot/m ],
		[ [ '--bot-vs-bot', ('--level', 1) x 3 ], qr/^merrills: --level can be given twice at most/m ],
		[ [ '--hotseat', '--level', 2 ], qr/^merrills: --hotseat has no bot for --level to set$/m ],
		[ [ '--hotseat', '--bot-vs-bot' ], qr/^merrills: --hotseat is two people and --bot-vs-bot is none/m ],
		[ [ '--side', 'red' ], qr/^merrills: --side is white, black or random, not 'red'$/m ],
		[ [ '--seed', 'x' ], qr/^merrills: --seed takes a whole number, not 'x'$/m ],
		[ [ '--position', 'nonsense' ], qr/^merrills: --position: position: six fields are needed, got 1$/m ],
		[ [ '--load', 't/no-such-file.txt' ], qr/^merrills: cannot read t\/no-such-file\.txt: /m ],
		[ [ '--replay', 't/no-such-file.txt' ], qr/^merrills: cannot read t\/no-such-file\.txt: /m ],
		[ [ '--load', $0 ], qr/^merrills: \Q$0\E is not a game that plays: record: move 1, /m ],
		[ [ '--position', $THREE, '--load', 't/fixtures/level-1.txt' ],
			qr/^merrills: --position and --load each say where the game begins: give one$/m ],
		[ [ 'd2' ], qr/^merrills: there is nothing to do with 'd2': options begin with --$/m ],
		[ [ '--variant', 'twelve' ], qr/^Unknown option: variant$/m ],
	);
	for my $case (@bad) {
		my ($arguments, $why) = @{$case};
		my ($output, $status) = run(@{$arguments});
		my $name = join ' ', map { length > 30 ? '...' : $_ } @{$arguments};
		is($status, 2, "$name: exit 2");
		like($output, $why, 'saying why');
		like($output, qr/^Usage: merrills \[options\]$/m, 'and how it should be used');
		unlike($output, qr/ at \S+ line \d+/, 'with no Perl file and line in it');
	}
};

subtest 'the exit status: 0 for a win or a draw, 1 for a loss' => sub {
	my ($won, $win) = run([ 'g4-g7xb2' ], @PLAIN, '--level', 1, '--position', $WINNING);
	like($won, qr/^White wins: Black has fewer than three men$/m, 'you take the third man');
	is($win, 0, 'a win is 0');

	my ($lost, $loss) = run([ 'resign' ], @PLAIN, '--level', 1);
	like($lost, qr/^Black wins: White resigned$/m, 'you resign');
	is($loss, 1, 'a loss is 1');

	my ($as_black, $black_win) = run([ 'resign' ], @PLAIN, '--hotseat', '--position', $WINNING);
	is($black_win, 0, 'two people: 0 whoever resigns');

	my ($unfinished, $left) = run([ 'd2' ], @PLAIN, '--level', 1);
	like($unfinished, qr/Bye\.\n\z/, 'the end of the input ends the game politely');
	is($left, 0, 'and an unfinished game is 0');
};

done_testing;
