use strict;
use warnings;
use Test::More;
use File::Temp ();
use IPC::Open3 ();
use Symbol ();

use Game::Fanorona;

# bin/fanorona, RUN AS A PROGRAM. No shell: the perl running this test is
# started again with the same @INC and the script's path, as a list, so there
# is nothing to quote and nothing that needs /bin/sh. Its standard input is a
# file, never a terminal, so it plays by typed move whatever it is given.

my $script = 'bin/fanorona';
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

subtest 'what it says of itself' => sub {
    my ($status, $out, $err) = run('', '--version');
    is($status, 0, '--version exits 0');
    is($out, "fanorona $Game::Fanorona::VERSION\n", 'with the version of the distribution');
    is($err, '', 'and nothing on STDERR');

    ($status, $out, $err) = run('', '--help');
    is($status, 0, '--help exits 0');
    like($out, qr/^  --$_\b/m, "and names --$_") for qw(side level variant load no-colour no-pick no-unicode version help);
    unlike($out, qr/--seed/, 'there is no --seed: nothing in the game is thrown');
};

subtest 'options it does not take' => sub {
    my ($status, $out, $err) = run('', '--seed', 'abc');
    is($status, 2, 'an option it does not know: exit 2');
    like($err, qr/^  fanorona \[options\]$/m, 'with the usage on STDERR');
    is($out, '', 'and nothing on STDOUT');

    ($status, $out, $err) = run('', 'extra');
    is($status, 2, 'a stray word: exit 2');
    like($err, qr/^fanorona: I do not know 'extra'\.$/m, 'named');

    ($status, $out, $err) = run('', '--side', 'red');
    is($status, 2, 'a side that is not one: exit 2');
    is($err, "fanorona: side is white, black, both or neither, not 'red'.\n", 'in a sentence, with no file and line');

    ($status, $out, $err) = run('', '--level', '6');
    is($status, 2, 'a level that is not one');
    is($err, "fanorona: level is 1 to 5.\n", 'said so');

    ($status, $out, $err) = run('', '--variant', 'chess');
    is($status, 2, 'a board that is not one');
    is($err, "fanorona: 'chess' is not a variant.\n", 'said so');
};

subtest 'a whole game through its standard input' => sub {
    my ($status, $out, $err) = run("a3-b3A\nquit\n", '--side', 'both', '--variant', '9x5,start=9/9/w1b6/9/9 w');
    is($status, 0, 'played to the end and left: exit 0');
    is($err, '', 'nothing on STDERR');
    like($out, qr/^3  O---\+---X---\+/m, 'the board it was given, in letters since this is no terminal');
    unlike($out, qr/\e/, 'with no paint and no cursor movement in it');
    like($out, qr/^White played a3-b3A, taking 1 stone\.$/m, 'the move');
    like($out, qr/^Black has no stone left\. White wins\.$/m, 'and the end');

    ($status, $out, $err) = run("d2-e3A\n", '--side', 'white', '--level', '1');
    is($status, 0, 'against the program, and the input simply ending: exit 0');
    like($out, qr/^Black played /m, 'the program answered');
    like($out, qr/^Bye\.$/m, 'and it says goodbye when the input ends');

    ($status, $out, $err) = run("", '--variant', 'telo', '--side', 'neither');
    is($status, 0, 'the program against itself on three by three');
    like($out, qr/wins\.$|is drawn\.$/m, 'reaches an end');
};

subtest 'a saved game carried on' => sub {
    my $file = "$dir/saved.txt";
    my ($status, $out, $err) = run("d2-e3A\ne5-f4A\nsave $file\n", '--side', 'both');
    is($status, 0, 'two moves and a save');
    ok(-s $file, 'the file is there');

    ($status, $out, $err) = run("quit\n", '--side', 'both', '--load', $file);
    is($status, 0, '--load: exit 0');
    like($out, qr/^Loaded \Q$file\E: 2 moves\.$/m, 'two moves loaded');
    like($out, qr/^Move 3\. White to play, O\.$/m, 'and it is the third move');

    ($status, $out, $err) = run('', '--load', "$dir/absent.txt");
    is($status, 2, 'a file that is not there: exit 2');
    like($out . $err, qr/Cannot read \Q$dir\E\/absent\.txt/, 'and it says which');
};

done_testing();
