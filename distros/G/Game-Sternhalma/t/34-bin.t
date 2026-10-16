use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SthT qw(near_home);
use File::Temp ();
use IPC::Open3 ();
use Symbol ();

use Game::Sternhalma;
use Game::Sternhalma::Terminal;

# bin/sternhalma, RUN AS A PROGRAM. No shell: the perl running this test is
# started again with the same @INC and the script's path, as a list, so there
# is nothing to quote and nothing that needs /bin/sh. Its standard input is a
# file, never a terminal, so it plays by typed move whatever it is given.

my $script = 'bin/sternhalma';
ok(-f $script, "$script is there") or BAIL_OUT('run from the distribution directory');

my $dir = File::Temp->newdir;

sub run {
    my ($typed, @args) = @_;
    my $in_file = "$dir/in";
    open my $w, '>', $in_file or die "in: $!";
    print {$w} $typed;
    close $w;
    open my $in, '<', $in_file or die "in: $!";
    my $err = Symbol::gensym();
    my $pid = IPC::Open3::open3('<&' . fileno($in), my $out, $err, $^X, (map { "-I$_" } grep { !ref } @INC), $script, @args);
    my $said = do { local $/; <$out> } // '';
    my $wrong = do { local $/; <$err> } // '';
    waitpid $pid, 0;
    return ($? >> 8, $said, $wrong);
}

# a saved game that starts with each seat a step from home
my $near = "$dir/near.txt";
{
    my $game = Game::Sternhalma->new(position => (near_home(2, 0))[0]->to_string);
    open my $fh, '>', $near or die $!;
    print {$fh} $game->log;
    close $fh;
}

subtest 'what it says of itself' => sub {
    my ($status, $out, $err) = run('', '--version');
    is($status, 0, '--version exits 0');
    is($out, "sternhalma $Game::Sternhalma::VERSION\n", 'with the version of the distribution');
    is($err, '', 'and nothing on STDERR');

    ($status, $out, $err) = run('', '--help');
    is($status, 0, '--help exits 0');
    like($out, qr/^  --$_\b/m, "and names --$_") for qw(seats pieces people bots level seed load pipe no-colour no-pick no-unicode version help);
};

subtest 'options it does not take' => sub {
    my ($status, $out, $err) = run('', '--colourful');
    is($status, 2, 'an option it does not know: exit 2');
    like($err, qr/^  sternhalma \[options\]$/m, 'with the usage on STDERR');
    is($out, '', 'and nothing on STDOUT');

    ($status, $out, $err) = run('', 'extra');
    is($status, 2, 'a stray word: exit 2');
    like($err, qr/^sternhalma: I do not know 'extra'\.$/m, 'named');

    my @refused = (
        [ [qw(--seats 5)],             "sternhalma: five cannot play: one seat would have nobody opposite.\n" ],
        [ [qw(--seats 7)],             "sternhalma: sternhalma is for 2, 3, 4 or 6 seats, not 7.\n" ],
        [ [qw(--seats 4 --pieces 15)], "sternhalma: fifteen pieces cannot sit at 4 seats: neighbouring points would share a hole.\n" ],
        [ [qw(--level 5)],             "sternhalma: level is 1 to 4.\n" ],
        [ [qw(--bots 2)],              "sternhalma: there is no seat 2 in a game of 2.\n" ],
        [ [qw(--bots one)],            "sternhalma: bots is a list of seats such as 1,2, or none or all, not 'one'.\n" ],
        [ [qw(--people 3)],            "sternhalma: people is 0 to 2.\n" ],
        [ [qw(--people 1 --bots 1)],   "sternhalma: give --people or --bots, not both.\n" ],
    );
    for my $case (@refused) {
        my ($args, $said) = @$case;
        ($status, $out, $err) = run('', @$args);
        is($status, 2, "@$args: exit 2");
        is($err, $said, '  in a sentence, with no file and line');
    }
};

subtest 'typed moves through its standard input' => sub {
    my ($status, $out, $err) = run("m6-n1\nquit\n", '--bots', 'none', '--load', $near);
    is($status, 0, 'played to the end and left: exit 0');
    is($err, '', 'nothing on STDERR');
    like($out, qr/^Loaded \Q$near\E: 0 moves\.$/m, 'the game it was given');
    unlike($out, qr/\e/, 'with no paint and no cursor movement in it, since this is no terminal');
    like($out, qr/^Red played m6-n1\.$/m, 'the move');
    like($out, qr/^1st Red, 2nd Blue\.$/m, 'and the end');

    ($status, $out, $err) = run("c3-e7\n", '--level', '1');
    is($status, 0, 'against the program, and the input simply ending: exit 0');
    like($out, qr/^Blue played /m, 'the program answered');
    like($out, qr/^Bye\.$/m, 'and it says goodbye when the input ends');

    ($status, $out, $err) = run('', '--seats', '4', '--bots', 'all', '--level', '1', '--seed', '3');
    is($status, 0, 'the program playing all four seats');
    like($out, qr/^Every seat but one is home\.$|^The game has reached its cap|^Nobody can move\.$/m, 'reaches an end');
};

# THE PIPE: a line in, a line out. A whole game, three seats, the program in
# two of them; and the same game is played by the facade alone, to show the
# lines are the game's and not the terminal's own idea of it.
subtest 'the pipe' => sub {
    my ($status, $out, $err) = run("a1-i5\nc3-e7\nquit\n", '--seats', 3, '--bots', '1,2', '--level', 2, '--pipe');
    is($status, 0, 'exit 0');
    is($err, '', 'nothing on STDERR');
    my @lines = split /\n/, $out;
    my $game = Game::Sternhalma->new(seats => 3);
    is($lines[0], 'start ' . $game->position, 'it starts with the position');
    is($lines[1], 'not_reachable ' . $game->position, 'a move that cannot be made: its flag, and the position unchanged');
    $game->play('c3-e7');
    is($lines[2], 'ok ' . $game->position, 'a move made: ok, and the position after it');
    like($lines[3], qr/^bot (\S+) /, 'then each move the program makes');
    for my $line (@lines[ 3, 4 ]) {
        my ($move) = $line =~ /^bot (\S+) /;
        is($game->play($move), undef, "  $move is a move the game makes");
        is($line, "bot $move " . $game->position, '  and the position after it');
    }
    is(scalar(@lines), 5, 'and quit stops it');

    ($status, $out, $err) = run("m6-n1\n", '--bots', 'none', '--load', $near, '--pipe');
    @lines = split /\n/, $out;
    like($lines[1], qr/^ok /, 'the move that ends a game');
    is($lines[2], 'over home 1,2', 'and over: how, and every seat\'s place');
    unlike($out, qr/^Loaded/m, 'nothing else is written on STDOUT');
    like($err, qr/^Loaded \Q$near\E: 0 moves\.$/m, 'what loading said is on STDERR');
};

subtest 'a saved game carried on' => sub {
    my $file = "$dir/saved.txt";
    my ($status, $out, $err) = run("c3-e7\no1-m5\nsave $file\n", '--bots', 'none');
    is($status, 0, 'two moves and a save');
    ok(-s $file, 'the file is there');

    ($status, $out, $err) = run("quit\n", '--bots', 'none', '--load', $file);
    is($status, 0, '--load: exit 0');
    like($out, qr/^Loaded \Q$file\E: 2 moves\.$/m, 'two moves loaded');
    like($out, qr/^Move 3\. Red to play, R\.$/m, 'and it is the third move');

    ($status, $out, $err) = run('', '--load', "$dir/absent.txt");
    is($status, 2, 'a file that is not there: exit 2');
    like($out . $err, qr/Cannot read \Q$dir\E\/absent\.txt/, 'and it says which');
};

# THE LAUNCHER'S FIELDS: every one is an option `run` takes, with every value
# it offers.
subtest 'options, for a launcher' => sub {
    my $class = 'Game::Sternhalma::Terminal';
    my $fields = $class->options;
    is_deeply([ map { $_->{name} } @$fields ], [qw(seats pieces people level)], 'four fields, in this order');
    isnt($class->options, $fields, 'a new list each call');
    is_deeply($class->options, $fields, 'with the same fields in it');
    SKIP: {
        skip 'Game::Terminal::Kit::Options is not installed', 1 unless eval { require Game::Terminal::Kit::Options; 1 };
        is_deeply([ Game::Terminal::Kit::Options::validate($fields) ], [], 'the kit finds nothing wrong');
    }
    my $quietly = sub {
        my $said = '';
        open my $out, '>', \$said or die $!;
        local *STDOUT = $out;
        local *STDERR = $out;
        return scalar eval { $class->run(@_) };
    };
    for my $field (@$fields) {
        my @values = $field->{type} eq 'enum' ? @{ $field->{choices} } : ($field->{min}, $field->{max});
        is($quietly->("--$field->{name}", $_, '--help'), 0, "--$field->{name} $_") for @values;
    }
    is($quietly->('--no-such-option', '--help'), 2, 'and one it does not take is 2, even beside --help');
};

done_testing();
