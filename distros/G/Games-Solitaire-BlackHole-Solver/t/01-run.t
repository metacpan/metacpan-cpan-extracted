use strict;
use warnings;

use Test::More tests => 4;

use File::Spec;

sub _filename
{
    return File::Spec->catfile(File::Spec->curdir(), "t", "data", shift());
}

my $solution1 = <<'EOF';
Solved!
2D
3H
2S
3C
4H
5S
6D
7C
8C
9H
TH
9S
8S
9D
TC
JS
QC
KS
QH
JC
TS
JH
QS
KH
AC
2C
3D
4S
5D
6S
7D
6H
5C
4C
3S
2H
AD
KC
AH
KD
QD
JD
TD
9C
8D
7S
8H
7H
6C
5H
4D
EOF

{
    my $sol_fn = _filename("26464608654870335080.bh.sol.txt");
    # TEST
    ok (!system($^X, "-Mblib", "-MGames::Solitaire::BlackHole::Solver::App",
            "-e", "Games::Solitaire::BlackHole::Solver::App->new()->run()",
            "--",
            "-o", $sol_fn,
            _filename("26464608654870335080.bh.board.txt")
        )
    );

    my $contents;
    {
        local $/;
        open my $in, "<", $sol_fn,
            or die "Could not open '$sol_fn' for reading.";
        $contents = <$in>;
        close($in);
    }

    # TEST
    is (
        $contents,
        $solution1,
        "Testing for correct solution.",
    );

    unlink($sol_fn);
}

{
    my $sol_fn = _filename("26464608654870335080.bh.sol.txt");
    # TEST
    ok (!system($^X, "-Mblib", File::Spec->catfile(File::Spec->curdir(), "bin", "black-hole-solve"),
            "-o", $sol_fn,
            _filename("26464608654870335080.bh.board.txt")
        )
    );

    my $contents;
    {
        local $/;
        open my $in, "<", $sol_fn,
            or die "Could not open '$sol_fn' for reading.";
        $contents = <$in>;
        close($in);
    }

    # TEST
    is (
        $contents,
        $solution1,
        "Testing for correct solution.",
    );

    unlink($sol_fn);
}

