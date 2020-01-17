use strict;
use warnings;

use IO::Lines;
use Symbol qw(geniosym); # tied file handle NON-BAREWORD
use Test::More;

plan tests => 33;

my @orig = (
    "A diner while dining at Crewe\n",
    "Found a rather large mouse in his stew\n",
    "   Said the waiter, \"Don't shout,\n",
    "   And wave it about..."
);
my $io = IO::Lines->new(\@orig);
ok($io, "open: open a scalar on a ref to an array");

# append with print
{
    my $error;
    { # catch block
        local $@;
        $error = $@ || 'Error' unless eval { # try block
            $io->print("\nor the rest");
            $io->print(" will be wanting one ", "too.\"\n");
            1
        };
    }
    is($error, undef, 'print: able to print to the handle');
}

# getc
{
    my @c_str;
    $io->seek(0,0);
    for my $i (0..2) {
        $c_str[$i] = $io->getc;
    }
    is($c_str[0], 'A', 'seek/getc: got A');
    is($c_str[1], ' ', 'seek/getc: got space');
    is($c_str[2], 'd', 'seek/getc: got d');
}

# getline
{
    my $str;

    $io->seek(3,0);
    $str = $io->getline;
    is($str, "iner while dining at Crewe\n", 'getline: got the line');

    $str = undef;
    $str = $io->getline;
    is($str, "Found a rather large mouse in his stew\n", 'getline: get subsequent line');

    $str = undef;
    # we know we're trying to grab too many lines
    for (0..5) {
        $str = $io->getline;
    }
    is($str, undef, 'getline: repeat past end of stream');
}

# getlines
{
    my @data;
    $io->seek(0,0);
    @data = $io->getlines;
    is(join('', @data), join('', @orig), 'getlines: got our original input!');
}

# read
{
    my $buff;

    $io->seek(0, 0);
    $io->read($buff, 10);
    is($buff, 'A diner wh', 'read: read(10) got correct value');

    $buff = undef;
    $io->read($buff, 10);
    is($buff, 'ile dining', 'read: read(10) again got correct value');
    is($io->tell, 20, 'tell: got correct current position');

    $buff = undef;
    $io->seek(0, 0);
    $io->read($buff, 1000);
    is($buff, join('', @orig), 'read(1000): got full slurped value');
}

# seek
{
    my $buff;

    $io->seek(2, 0);
    $io->read($buff, 5);
    is($buff, 'diner', 'seek(2,0) - read: got correct value');

    $buff = undef;
    $io->seek(-6, 2);
    $io->read($buff, 3);
    is($buff, 'too', 'seek(-6,2) - read(): got correct value');

    $buff = undef;
    $io->seek(-7, 1);
    $io->read($buff, 7);
    is($buff, 'one too', 'seek(-7,1) - read(): got correct value');
}

# tie
{
    my $th = geniosym;
    tie(*{$th}, 'IO::Lines', []);
    ok($th, 'tie: got tied handle');

    print {$th} @orig;

    tied(*{$th})->seek(0, 0);

    my @lines;
    while (my $line = <$th>) {
        push @lines, $line;
    }
    is(join('', @lines), join('', @orig), 'tied seek readline: got correct value');

    @lines = ();
    tied(*{$th})->seek(0, 0);
    @lines = <$th>;
    is(join('', @lines), join('', @orig), 'tied seek readlines: got correct value');
}

# record seps
{
    my @lines = (
        "par 1, line 1\n",
        "par 1, line 2\n",
        "\n",
        "\n",
        "\n",
        "\n",
        "par 2, line 1\n",
        "\n",
        "par 3, line 1\n",
        "par 3, line 2\n",
        "par 3, line 3",
    );
    my $all = [@lines];

    # Slurp everything
    {
        my $ios = IO::Lines->new($all);
        local $/ = undef;
        is($ios->getline, join('', @lines), "recordsep: undef - getline");
    }

    # Read a little, slurp the rest
    {
        my $ios = IO::Lines->new($all);
        is($ios->getline, $lines[0], "recordsep: undef - get first line");
        local $/ = undef;
        is($ios->getline, join('', @lines[1..$#lines]), "recordsep: undef - slurp the rest");
    }

    # Read line by line
    {
        my $ios = IO::Lines->new($all);
        local $/ = "\n";
        for my $i (0..10) {
            is($ios->getline, $lines[$i], "recordsep: newline - rec $i");
        }
    }
}
