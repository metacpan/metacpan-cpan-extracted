use v5.16;
use warnings;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

# How the converter runs as a process: what it writes to the standard
# error, how it ends, and what the program around it sees.

my $dir = tempdir(CLEANUP => 1);
my $lib = File::Spec->rel2abs('lib');

sub put {
    my($name, $text) = @_;
    open my $fh, '>', "$dir/$name" or die "$name: $!";
    print $fh $text;
    close $fh;
    "$dir/$name";
}

put 'a.up', "hello\n";

# run a script in the directory of the files, and stop it when it hangs
sub run {
    my($body, $input) = @_;
    put 'script.pl', "use IO::Factotum;\nalarm 20;\n\$| = 1;\n$body\n";
    my $stdin = defined $input ? "printf '$input' |" : '';
    scalar qx{cd "$dir" && $stdin $^X -I"$lib" script.pl 2>&1};
}

is run(q{
    IO::Factotum::register(
	match   => qr/\.up$/,
	command => ['perl', '-e', 'print STDERR "x" x 300000; print "OUT\n"']);
    print IO::Factotum::open_input('a.up')->getlines;
}), "OUT\n", 'much output to the standard error does not block, and is not shown';

is run(q{
    IO::Factotum::register(
	match   => qr/\.up$/,
	command => [ sub { print STDERR "x" x 300000; print "OUT\n" } ]);
    print IO::Factotum::open_input('a.up')->getlines;
}), "OUT\n", 'the same with a code reference';

is run(q{
    IO::Factotum::register(
	match   => qr/\.up$/,
	command => [ sub { print "CONVERTED\n" } ]);
    print IO::Factotum::open_input('a.up')->getlines;
    END { print "END in $0\n" }
}), "CONVERTED\nEND in script.pl\n", 'END blocks do not run in the process of the converter';

is run(q{
    IO::Factotum::register(
	match   => qr/\.up$/,
	command => [ sub { print "partial\n"; die "failed\n" } ]);
    print IO::Factotum::open_input('a.up')->getlines;
}), "hello\n", 'a code reference which dies leaves the file as it is';

is run(q{
    IO::Factotum::register(match => qr/\.up$/, command => ['no-such-command-xyz']);
    my $fh = eval { IO::Factotum::open_input('a.up') };
    print "content: ", $fh->getlines;
    print "end\n";
}), "content: hello\nend\n", 'a command which can not be run, inside eval';

is run(q{
    IO::Factotum::register(match => qr/\.up$/, command => ['false']);
    system 'true';
    IO::Factotum::open_input('a.up');
    print "status $?\n";
}), "status 0\n", '$? is kept';

is run(q{
    IO::Factotum::tie_argv();
    my $first = <STDIN>;
    print "first=$first";
    print "rest=", <>;
}, '1\n2\n3\n'), "first=1\nrest=2\n3\n", 'the standard input read before <>';

is run(q{
    local $SIG{CHLD} = 'IGNORE';
    IO::Factotum::register(match => qr/\.up$/, command => ['perl', '-pe', '$_ = uc']);
    print IO::Factotum::open_input('a.up')->getlines;
}), "HELLO\n", 'with SIGCHLD ignored';

subtest 'bytes are kept' => sub {
    put 'latin1.up', "caf\xe9 = 1;\n";
    put 'bin.up', join('', map chr, 0..255);
    my $out = run(q{
	binmode STDOUT;
	IO::Factotum::register(match => qr/\.up$/, command => ['cat']);
	print IO::Factotum::open_input($_)->getlines for qw(latin1.up bin.up);
    });
    is $out, "caf\xe9 = 1;\n" . join('', map chr, 0..255), 'no decoding, no warning';
};

done_testing;
