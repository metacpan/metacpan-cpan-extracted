use strict;
use warnings;

use IO::Scalar;
use Symbol qw(geniosym); # tied file handle NON-BAREWORD
use Test::More;

plan tests => 39;

# Some data
my @orig = (
    "A diner while dining at Crewe\n",
    "Found a rather large mouse in his stew\n",
    "   Said the waiter, \"Don't shout,\n",
    "   And wave it about..."
);
my @extra = (
    "\nor the rest",
    " will be wanting one ",
    "too.\"\n",
);
my $s = join('', @orig);
my $whole = $s . join('', @extra);

# start testing
my $io = IO::Scalar->new(\$s);
ok($io, "open: open a scalar on a ref to a string");
is($io->fileno(), undef, "fileno() returns undef");

# test print
{
    ok($io->print($extra[0]), "print: able to print");
    ok($io->print(@extra[1,2]), "print: able to print again");
    # is("$io", $whole, "Whole string matches");
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
    is($buff, $whole, 'read(1000): got full slurped value');
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
    tie(*{$th}, 'IO::Scalar');
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
    my $all = join('', @lines);

    # Slurp everything
    {
        my $ios = IO::Scalar->new(\$all);
        local $/ = undef;
        is($ios->getline, $all, "recordsep: undef - getline");
    }

    # Read a little, slurp the rest
    {
        my $ios = IO::Scalar->new(\$all);
        is($ios->getline, $lines[0], "recordsep: undef - get first line");
        local $/ = undef;
        is($ios->getline, join('', @lines[1..$#lines]), "recordsep: undef - slurp the rest");
    }

    # Read paragraph by paragraph
    {
        my $ios = IO::Scalar->new(\$all);
        local $/ = "";
        is($ios->getline, join('', @lines[0..2]), "recordsep: empty - first par");
        is($ios->getline, join('', @lines[6..7]), "recordsep: empty - second par");
        is($ios->getline, join('', @lines[8..10]), "recordsep empty - third par");
    }

    # Read record by record
    {
        my $ios = IO::Scalar->new(\$all);
        local $/ = "1,";
        is($ios->getline, "par 1,", "recordsep: custom - first rec");
        is($ios->getline, " line 1\npar 1,", "recordsep: custom - second rec");
    }

    # Read line by line
    {
        my $ios = IO::Scalar->new(\$all);
        local $/ = "\n";
        for my $i (0..10) {
            is($ios->getline, $lines[$i], "recordsep: newline - rec $i");
        }
    }
}
