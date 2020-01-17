use strict;
use warnings;

use IO::ScalarArray;
use Symbol qw(geniosym); # tied file handle NON-BAREWORD
use Test::More;

plan tests => 33;

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

my $io = IO::ScalarArray->new(\@orig);
ok($io, "open: open a scalar on a ref to an array");
is($io->fileno(), undef, 'fileno() returns undef');

# print
{
    ok($io->print($extra[0]), 'print: Able to print to handle');
    ok($io->print(@extra[1..2]), 'print, Able to print to handle');
}

# getc
{
    my $buffer = '';
    $io->seek(0, 0);
    for (0..2) { $buffer .= $io->getc };
    is($buffer, 'A d', 'SAH: seek(0, 0) and getc() to buffer');
}

# getline
{
    my $last;
    $io->seek(3, 0);
    is($io->getline, "iner while dining at Crewe\n", 'getline/seek: got part of 1st line');
    is($io->getline, "Found a rather large mouse in his stew\n", 'getline/next: next getline gets subsequent line');

    for (1..6) { $last = $io->getline }
    ok(!$last, 'getline/eof: repeated getline() finds end of stream');

    $io->seek(0, 0);
    my @got  = $io->getlines;
    is(join('', @got), $whole, "getline/getlines: seek(0,0) and getlines slurps in string");
}

# read
{
    my $buffer = '';
    $io->seek(0, 0);
    $io->read($buffer, 10);
    is($buffer, "A diner wh", "read/first10: reading first 10 bytes with seek(0,START) + read(10)");

    $io->read($buffer, 10);
    is($buffer, "ile dining", "read/next10: reading next 10 bytes with read(10)");

    is($io->tell, 20, 'read/tell20: tell() the current location as 20');

    $io->seek(0,0);
    $io->read($buffer,1000);
    is($buffer, $whole, 'read/slurp: seek(0,start)+read(1000) reads in whole handle');
}

# seek
{
    my $buffer = '';
    $io->seek(2, 0);
    $io->read($buffer, 5);
    is($buffer, 'diner', 'seek/set: seek(2, set) + read(5) returns "diner"');

    $io->seek(-6,2);
    $io->read($buffer,3);
    is($buffer, 'too', 'seek/end: seek(-6,end)+read(3) returns "too"');

    $io->seek(-7,1);
    $io->read($buffer,7);
    is($buffer, 'one too', "SEEK/CUR: seek(-7,CUR) + read(7) returns 'one too'");
}

# tie
{
    my $th = geniosym;
    tie(*{$th}, 'IO::ScalarArray');
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

# record separators
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
        my $iosa = IO::ScalarArray->new(\@lines);
        local $/ = undef;
        is($iosa->getline, $all, "RECORDSEP undef: getline slurps everything");
    }

    # Read a little, slurp the rest
    {
        my $iosa = IO::ScalarArray->new(\@lines);
        is($iosa->getline, $lines[0], "RECORDSEP undef: get first line");
        local $/ = undef;
        is($iosa->getline, join('', @lines[1..$#lines]), "RECORDSEP undef: slurp the rest");
    }

    # Read line by line
    {
        my $iosa = IO::ScalarArray->new(\@lines);
        local $/ = "\n";
        for my $i (0..10) {
            is($iosa->getline, $lines[$i], "RECORDSEP newline: rec $i");
        }
    }
}
