use strict;
use warnings;

use Test::More tests => 6;

use File::Spec ();
use Path::Tiny qw/ path /;
use Socket qw/ :crlf /;

sub _normalize_lf
{
    my ($s) = @_;
    $s =~ s#$CRLF#$LF#g;
    return $s;
}

sub _filename
{
    return File::Spec->catfile( File::Spec->curdir(), "t", "data", shift() );
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
    ok(
        !system( $^X,
            "-Mblib",
            "-MGames::Solitaire::BlackHole::Solver::App",
            "-e",
            "Games::Solitaire::BlackHole::Solver::App->new()->run()",
            "--",
            "-o",
            $sol_fn,
            _filename("26464608654870335080.bh.board.txt")
        )
    );

    # TEST
    is(
        _normalize_lf( path($sol_fn)->slurp_utf8 ),
        _normalize_lf($solution1),
        "Testing for correct solution.",
    );

    unlink($sol_fn);
}

{
    my $sol_fn = _filename("26464608654870335080.bh.sol.txt");

    # TEST
    ok(
        !system( $^X, "-Mblib",
            File::Spec->catfile(
                File::Spec->curdir(), "bin", "black-hole-solve"
            ),
            "-o", $sol_fn,
            _filename("26464608654870335080.bh.board.txt")
        )
    );

    # TEST
    is(
        _normalize_lf( path($sol_fn)->slurp_utf8 ),
        _normalize_lf($solution1),
        "Testing for correct solution.",
    );

    unlink($sol_fn);
}

my $GOLF_35_SOLUTION = <<'EOF';
Solved!
8D
9H
TC
Deal talon 3S
2H
Deal talon 7C
6D
5D
4D
3C
Deal talon KH
QH
JC
TD
9S
TS
Deal talon QS
KS
QC
JD
Deal talon AH
Deal talon 8C
7D
6S
7H
Deal talon KD
Deal talon AS
2S
AC
2C
AD
Deal talon 6C
5S
6H
5H
4H
5C
Deal talon 4S
3D
2D
3H
Deal talon 9D
TH
JH
QD
KC
EOF

{
    my $sol_fn = _filename("35.golf.sol.txt");

    # TEST
    ok(
        !system( $^X, "-Mblib",
            File::Spec->catfile(
                File::Spec->curdir(), "bin", "golf-solitaire-solve-perl"
            ),
            "--queens-on-kings",
            "-o", $sol_fn,
            _filename("35.golf.board.txt")
        )
    );

    # TEST
    is(
        _normalize_lf( path($sol_fn)->slurp_utf8 ),
        _normalize_lf($GOLF_35_SOLUTION),
        "Testing for correct Golf solution.",
    );

    unlink($sol_fn);
}
