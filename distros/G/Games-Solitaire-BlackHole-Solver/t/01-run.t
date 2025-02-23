use strict;
use warnings;

use Test::More tests => 20;

use Path::Tiny           qw/ path cwd /;
use Dir::Manifest::Slurp qw/ as_lf /;
use Test::Differences    qw/ eq_or_diff /;

sub _filename
{
    return cwd()->child( "t", "data", shift() );
}

sub _filename_2to3
{
    my $n = shift;
    return cwd()
        ->child( "t", "data", "run-2-to-3-with-3-unsolved", "bh${n}.board" );
}

sub _filename_maxiters2000
{
    my $n = shift;
    return cwd()
        ->child( "t", "data", "run-with-max-iters-2000", "bh${n}.board" );
}

sub _exe
{
    return cwd()->child( "bin", shift );
}

my $BHS    = _exe("black-hole-solve");
my $GOLF_S = _exe("golf-solitaire-solve-perl");

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
Total number of states checked is 8636.
This scan generated 8672 states.
EOF

{
    my $sol_fn = _filename("26464608654870335080.bh.sol.txt");

    # TEST
    ok(
        !system(
            $^X,
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
        as_lf( path($sol_fn)->slurp_utf8 ),
        as_lf($solution1), "Testing for correct solution.",
    );

    unlink($sol_fn);
}

{
    my $sol_fn = _filename("26464608654870335080.bh.sol.txt");

    # TEST
    ok(
        !system(
            $^X, "-Mblib", $BHS, "-o", $sol_fn,
            _filename("26464608654870335080.bh.board.txt")
        )
    );

    # TEST
    is(
        as_lf( path($sol_fn)->slurp_utf8 ),
        as_lf($solution1), "Testing for correct solution.",
    );

    unlink($sol_fn);
}

my $solution2 = <<'EOF';
Solved!
Move 2D from stack 16 to foundations 0

Foundations: [ AS -> 2D ]
: KD JH JS
: 8H 4C 7D
: 7H TD 4H
: JD 9S 5S
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C 8C
: 4D KC TC
: 6D 3C 3H
: 2C KS TH
: AD 5D 7C
: 9H 2S [ 2D -> ]

Move 3H from stack 13 to foundations 0

Foundations: [ 2D -> 3H ]
: KD JH JS
: 8H 4C 7D
: 7H TD 4H
: JD 9S 5S
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C 8C
: 4D KC TC
: 6D 3C [ 3H -> ]
: 2C KS TH
: AD 5D 7C
: 9H 2S

Move 2S from stack 16 to foundations 0

Foundations: [ 3H -> 2S ]
: KD JH JS
: 8H 4C 7D
: 7H TD 4H
: JD 9S 5S
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C 8C
: 4D KC TC
: 6D 3C
: 2C KS TH
: AD 5D 7C
: 9H [ 2S -> ]

Move 3C from stack 13 to foundations 0

Foundations: [ 2S -> 3C ]
: KD JH JS
: 8H 4C 7D
: 7H TD 4H
: JD 9S 5S
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C 8C
: 4D KC TC
: 6D [ 3C -> ]
: 2C KS TH
: AD 5D 7C
: 9H

Move 4H from stack 2 to foundations 0

Foundations: [ 3C -> 4H ]
: KD JH JS
: 8H 4C 7D
: 7H TD [ 4H -> ]
: JD 9S 5S
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C 8C
: 4D KC TC
: 6D
: 2C KS TH
: AD 5D 7C
: 9H

Move 5S from stack 3 to foundations 0

Foundations: [ 4H -> 5S ]
: KD JH JS
: 8H 4C 7D
: 7H TD
: JD 9S [ 5S -> ]
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C 8C
: 4D KC TC
: 6D
: 2C KS TH
: AD 5D 7C
: 9H

Move 6D from stack 13 to foundations 0

Foundations: [ 5S -> 6D ]
: KD JH JS
: 8H 4C 7D
: 7H TD
: JD 9S
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C 8C
: 4D KC TC
: [ 6D -> ]
: 2C KS TH
: AD 5D 7C
: 9H

Move 7C from stack 15 to foundations 0

Foundations: [ 6D -> 7C ]
: KD JH JS
: 8H 4C 7D
: 7H TD
: JD 9S
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C 8C
: 4D KC TC
:
: 2C KS TH
: AD 5D [ 7C -> ]
: 9H

Move 8C from stack 11 to foundations 0

Foundations: [ 7C -> 8C ]
: KD JH JS
: 8H 4C 7D
: 7H TD
: JD 9S
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C [ 8C -> ]
: 4D KC TC
:
: 2C KS TH
: AD 5D
: 9H

Move 9H from stack 16 to foundations 0

Foundations: [ 8C -> 9H ]
: KD JH JS
: 8H 4C 7D
: 7H TD
: JD 9S
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C
: 4D KC TC
:
: 2C KS TH
: AD 5D
: [ 9H -> ]

Move TH from stack 14 to foundations 0

Foundations: [ 9H -> TH ]
: KD JH JS
: 8H 4C 7D
: 7H TD
: JD 9S
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C
: 4D KC TC
:
: 2C KS [ TH -> ]
: AD 5D
:

Move 9S from stack 3 to foundations 0

Foundations: [ TH -> 9S ]
: KD JH JS
: 8H 4C 7D
: 7H TD
: JD [ 9S -> ]
: AH 3S 6H
: 9C 9D 8S
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C
: 4D KC TC
:
: 2C KS
: AD 5D
:

Move 8S from stack 5 to foundations 0

Foundations: [ 9S -> 8S ]
: KD JH JS
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C 9D [ 8S -> ]
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C
: 4D KC TC
:
: 2C KS
: AD 5D
:

Move 9D from stack 5 to foundations 0

Foundations: [ 8S -> 9D ]
: KD JH JS
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C [ 9D -> ]
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C
: 4D KC TC
:
: 2C KS
: AD 5D
:

Move TC from stack 12 to foundations 0

Foundations: [ 9D -> TC ]
: KD JH JS
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C
: 4D KC [ TC -> ]
:
: 2C KS
: AD 5D
:

Move JS from stack 0 to foundations 0

Foundations: [ TC -> JS ]
: KD JH [ JS -> ]
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS QC
: 8D 3D KH
: 5H 5C
: 4D KC
:
: 2C KS
: AD 5D
:

Move QC from stack 9 to foundations 0

Foundations: [ JS -> QC ]
: KD JH
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS [ QC -> ]
: 8D 3D KH
: 5H 5C
: 4D KC
:
: 2C KS
: AD 5D
:

Move KS from stack 14 to foundations 0

Foundations: [ QC -> KS ]
: KD JH
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: AC JC QH
: QD 4S TS
: 6C QS
: 8D 3D KH
: 5H 5C
: 4D KC
:
: 2C [ KS -> ]
: AD 5D
:

Move QH from stack 7 to foundations 0

Foundations: [ KS -> QH ]
: KD JH
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: AC JC [ QH -> ]
: QD 4S TS
: 6C QS
: 8D 3D KH
: 5H 5C
: 4D KC
:
: 2C
: AD 5D
:

Move JC from stack 7 to foundations 0

Foundations: [ QH -> JC ]
: KD JH
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: AC [ JC -> ]
: QD 4S TS
: 6C QS
: 8D 3D KH
: 5H 5C
: 4D KC
:
: 2C
: AD 5D
:

Move TS from stack 8 to foundations 0

Foundations: [ JC -> TS ]
: KD JH
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: AC
: QD 4S [ TS -> ]
: 6C QS
: 8D 3D KH
: 5H 5C
: 4D KC
:
: 2C
: AD 5D
:

Move JH from stack 0 to foundations 0

Foundations: [ TS -> JH ]
: KD [ JH -> ]
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: AC
: QD 4S
: 6C QS
: 8D 3D KH
: 5H 5C
: 4D KC
:
: 2C
: AD 5D
:

Move QS from stack 9 to foundations 0

Foundations: [ JH -> QS ]
: KD
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: AC
: QD 4S
: 6C [ QS -> ]
: 8D 3D KH
: 5H 5C
: 4D KC
:
: 2C
: AD 5D
:

Move KH from stack 10 to foundations 0

Foundations: [ QS -> KH ]
: KD
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: AC
: QD 4S
: 6C
: 8D 3D [ KH -> ]
: 5H 5C
: 4D KC
:
: 2C
: AD 5D
:

Move AC from stack 7 to foundations 0

Foundations: [ KH -> AC ]
: KD
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
: [ AC -> ]
: QD 4S
: 6C
: 8D 3D
: 5H 5C
: 4D KC
:
: 2C
: AD 5D
:

Move 2C from stack 14 to foundations 0

Foundations: [ AC -> 2C ]
: KD
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
:
: QD 4S
: 6C
: 8D 3D
: 5H 5C
: 4D KC
:
: [ 2C -> ]
: AD 5D
:

Move 3D from stack 10 to foundations 0

Foundations: [ 2C -> 3D ]
: KD
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
:
: QD 4S
: 6C
: 8D [ 3D -> ]
: 5H 5C
: 4D KC
:
:
: AD 5D
:

Move 4S from stack 8 to foundations 0

Foundations: [ 3D -> 4S ]
: KD
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
:
: QD [ 4S -> ]
: 6C
: 8D
: 5H 5C
: 4D KC
:
:
: AD 5D
:

Move 5D from stack 15 to foundations 0

Foundations: [ 4S -> 5D ]
: KD
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H 6S
:
: QD
: 6C
: 8D
: 5H 5C
: 4D KC
:
:
: AD [ 5D -> ]
:

Move 6S from stack 6 to foundations 0

Foundations: [ 5D -> 6S ]
: KD
: 8H 4C 7D
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H [ 6S -> ]
:
: QD
: 6C
: 8D
: 5H 5C
: 4D KC
:
:
: AD
:

Move 7D from stack 1 to foundations 0

Foundations: [ 6S -> 7D ]
: KD
: 8H 4C [ 7D -> ]
: 7H TD
: JD
: AH 3S 6H
: 9C
: 7S 2H
:
: QD
: 6C
: 8D
: 5H 5C
: 4D KC
:
:
: AD
:

Move 6H from stack 4 to foundations 0

Foundations: [ 7D -> 6H ]
: KD
: 8H 4C
: 7H TD
: JD
: AH 3S [ 6H -> ]
: 9C
: 7S 2H
:
: QD
: 6C
: 8D
: 5H 5C
: 4D KC
:
:
: AD
:

Move 5C from stack 11 to foundations 0

Foundations: [ 6H -> 5C ]
: KD
: 8H 4C
: 7H TD
: JD
: AH 3S
: 9C
: 7S 2H
:
: QD
: 6C
: 8D
: 5H [ 5C -> ]
: 4D KC
:
:
: AD
:

Move 4C from stack 1 to foundations 0

Foundations: [ 5C -> 4C ]
: KD
: 8H [ 4C -> ]
: 7H TD
: JD
: AH 3S
: 9C
: 7S 2H
:
: QD
: 6C
: 8D
: 5H
: 4D KC
:
:
: AD
:

Move 3S from stack 4 to foundations 0

Foundations: [ 4C -> 3S ]
: KD
: 8H
: 7H TD
: JD
: AH [ 3S -> ]
: 9C
: 7S 2H
:
: QD
: 6C
: 8D
: 5H
: 4D KC
:
:
: AD
:

Move 2H from stack 6 to foundations 0

Foundations: [ 3S -> 2H ]
: KD
: 8H
: 7H TD
: JD
: AH
: 9C
: 7S [ 2H -> ]
:
: QD
: 6C
: 8D
: 5H
: 4D KC
:
:
: AD
:

Move AD from stack 15 to foundations 0

Foundations: [ 2H -> AD ]
: KD
: 8H
: 7H TD
: JD
: AH
: 9C
: 7S
:
: QD
: 6C
: 8D
: 5H
: 4D KC
:
:
: [ AD -> ]
:

Move KC from stack 12 to foundations 0

Foundations: [ AD -> KC ]
: KD
: 8H
: 7H TD
: JD
: AH
: 9C
: 7S
:
: QD
: 6C
: 8D
: 5H
: 4D [ KC -> ]
:
:
:
:

Move AH from stack 4 to foundations 0

Foundations: [ KC -> AH ]
: KD
: 8H
: 7H TD
: JD
: [ AH -> ]
: 9C
: 7S
:
: QD
: 6C
: 8D
: 5H
: 4D
:
:
:
:

Move KD from stack 0 to foundations 0

Foundations: [ AH -> KD ]
: [ KD -> ]
: 8H
: 7H TD
: JD
:
: 9C
: 7S
:
: QD
: 6C
: 8D
: 5H
: 4D
:
:
:
:

Move QD from stack 8 to foundations 0

Foundations: [ KD -> QD ]
:
: 8H
: 7H TD
: JD
:
: 9C
: 7S
:
: [ QD -> ]
: 6C
: 8D
: 5H
: 4D
:
:
:
:

Move JD from stack 3 to foundations 0

Foundations: [ QD -> JD ]
:
: 8H
: 7H TD
: [ JD -> ]
:
: 9C
: 7S
:
:
: 6C
: 8D
: 5H
: 4D
:
:
:
:

Move TD from stack 2 to foundations 0

Foundations: [ JD -> TD ]
:
: 8H
: 7H [ TD -> ]
:
:
: 9C
: 7S
:
:
: 6C
: 8D
: 5H
: 4D
:
:
:
:

Move 9C from stack 5 to foundations 0

Foundations: [ TD -> 9C ]
:
: 8H
: 7H
:
:
: [ 9C -> ]
: 7S
:
:
: 6C
: 8D
: 5H
: 4D
:
:
:
:

Move 8D from stack 10 to foundations 0

Foundations: [ 9C -> 8D ]
:
: 8H
: 7H
:
:
:
: 7S
:
:
: 6C
: [ 8D -> ]
: 5H
: 4D
:
:
:
:

Move 7S from stack 6 to foundations 0

Foundations: [ 8D -> 7S ]
:
: 8H
: 7H
:
:
:
: [ 7S -> ]
:
:
: 6C
:
: 5H
: 4D
:
:
:
:

Move 8H from stack 1 to foundations 0

Foundations: [ 7S -> 8H ]
:
: [ 8H -> ]
: 7H
:
:
:
:
:
:
: 6C
:
: 5H
: 4D
:
:
:
:

Move 7H from stack 2 to foundations 0

Foundations: [ 8H -> 7H ]
:
:
: [ 7H -> ]
:
:
:
:
:
:
: 6C
:
: 5H
: 4D
:
:
:
:

Move 6C from stack 9 to foundations 0

Foundations: [ 7H -> 6C ]
:
:
:
:
:
:
:
:
:
: [ 6C -> ]
:
: 5H
: 4D
:
:
:
:

Move 5H from stack 11 to foundations 0

Foundations: [ 6C -> 5H ]
:
:
:
:
:
:
:
:
:
:
:
: [ 5H -> ]
: 4D
:
:
:
:

Move 4D from stack 12 to foundations 0

Foundations: [ 5H -> 4D ]
:
:
:
:
:
:
:
:
:
:
:
:
: [ 4D -> ]
:
:
:
:

Total number of states checked is 8636.
This scan generated 8672 states.
EOF

{
    my $sol_fn = _filename("26464608654870335080.bh-disp.sol.txt");

    # TEST
    ok(
        !system(
            $^X, "-Mblib", $BHS, "--display-boards", "-o", $sol_fn,
            _filename("26464608654870335080.bh.board.txt")
        )
    );

    # TEST
    is(
        as_lf( path($sol_fn)->slurp_utf8 ),
        as_lf($solution2), "Testing for correct --display-boards solution.",
    );

    unlink($sol_fn);
}

{
    my $sol_fn = _filename("26464608654870335080.bh-disp.sol.txt");

    # TEST
    ok(
        !system(
            $^X, "-Mblib", $BHS, "--display-boards", "--max-iters=10000", "-o",
            $sol_fn, _filename("26464608654870335080.bh.board.txt")
        )
    );

    # TEST
    is(
        as_lf( path($sol_fn)->slurp_utf8 ),
        as_lf($solution2), "Testing for correct --max-iters solution.",
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
        !system(
            $^X, "-Mblib", $GOLF_S, "--queens-on-kings", "-o", $sol_fn,
            _filename("35.golf.board.txt")
        )
    );

    # TEST
    is(
        as_lf( path($sol_fn)->slurp_utf8 ),
        as_lf($GOLF_35_SOLUTION),
        "Testing for correct Golf solution.",
    );

    unlink($sol_fn);
}

my $MAX_NUM_PLAYED_CARDS_RE = qr/\AAt most ([0-9]+) cards could be played\.$/ms;

my @MAX_NUM_PLAYED_FLAG = ("--show-max-num-played-cards");

sub _test_multiple_max_num_played_cards
{
    my ($args) = @_;
    my ( $name, $want, $input_lines ) =
        @{$args}{qw/ name expected_num input_lines/};
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return subtest $name => sub {
        plan tests => 2;
        my @matches = (
            grep { /$MAX_NUM_PLAYED_CARDS_RE/ }
            map  { as_lf($_) } @$input_lines,
        );

        is( scalar(@matches), scalar(@$want), "lines count." );

        eq_or_diff(
            [
                map {
                    /$MAX_NUM_PLAYED_CARDS_RE/
                        ? ($1)
                        : ( die "not matched!" )
                } @matches
            ],
            [@$want],
            "num cards moved.",
        );
    };
}

sub _test_max_num_played_cards
{
    my ($args) = @_;
    my ( $name, $want, $input_lines ) =
        @{$args}{qw/ name expected_num input_lines/};
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return subtest $name => sub {
        plan tests => 2;
        my @matches = (
            grep { /$MAX_NUM_PLAYED_CARDS_RE/ }
            map  { as_lf($_) } @$input_lines,
        );

        is( scalar(@matches), 1, "One line." );

        eq_or_diff(
            [
                map {
                    /$MAX_NUM_PLAYED_CARDS_RE/
                        ? ($1)
                        : ( die "not matched!" )
                } @matches
            ],
            [$want],
            "num cards moved.",
        );
    };
}

{
    my $sol_fn = _filename("26464608654870335080-with-max-depth.bh.sol.txt");

    # TEST
    ok(
        !system(
            $^X, "-Mblib", $BHS, @MAX_NUM_PLAYED_FLAG, "-o", $sol_fn,
            _filename("26464608654870335080.bh.board.txt")
        )
    );

    # TEST
    _test_max_num_played_cards(
        {
            name         => "max-num-played on success",
            expected_num => 51,
            input_lines  => [ path($sol_fn)->lines_utf8() ]
        }
    );

    unlink($sol_fn);
}

{
    my $sol_fn = _filename("1-with-max-depth.bh.sol.txt");

    # TEST
    ok(
        system( $^X, "-Mblib", $BHS, @MAX_NUM_PLAYED_FLAG, "-o", $sol_fn,
            _filename("1.bh.board.txt") ) != 0
    );

    # TEST
    _test_max_num_played_cards(
        {
            name         => "max-num-played on fail",
            expected_num => 3,
            input_lines  => [ path($sol_fn)->lines_utf8() ]
        }
    );

    unlink($sol_fn);
}

{
    my $sol_fn = _filename("27.bh.sol.txt");

    # TEST
    ok(
        system( $^X, "-Mblib", $BHS, @MAX_NUM_PLAYED_FLAG, "-o", $sol_fn,
            _filename("27.bh.board.txt") ) != 0
    );

    # TEST
    _test_max_num_played_cards(
        {
            name         => "max-num-played on no moves",
            expected_num => 0,
            input_lines  => [ path($sol_fn)->lines_utf8() ]
        }
    );

    unlink($sol_fn);
}

{
    my $sol_fn = _filename("3and4.bh.sol.txt");

    # TEST
    ok(
        system( $^X, "-Mblib", $BHS, "--max-iters", 20000,
            @MAX_NUM_PLAYED_FLAG, "-o", $sol_fn,
            _filename_2to3(2),    _filename_2to3(3), ) != 0
    );

    # TEST
    _test_multiple_max_num_played_cards(
        {
            name         => "max-num-played on no moves",
            expected_num => [ 50, 48, ],
            input_lines  => [ path($sol_fn)->lines_utf8() ]
        }
    );

    unlink($sol_fn);
}

sub _test_multiple_verdict_lines
{
    my %is_verdict_line = map { $_ => 1, }
        ( "Solved!", "Unsolved!", "Exceeded max_iters_limit !" );
    my ($args) = @_;
    my ( $name, $expected_files_checks, $want, $input_lines ) =
        @{$args}{qw/ name expected_files_checks expected_results input_lines/};
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return subtest $name => sub {
        plan tests => 2;
        $input_lines =
            [ map { my $l = as_lf($_); chomp $l; $l } @$input_lines ];
        my @matches;
        my $deal_idx = 0;
        while (@$input_lines)
        {
            my $dealstart = shift @$input_lines;
            my ($fn) = $dealstart =~ /^\[\= Starting file (\S+) \=\]$/ms
                or die "cannot match";
            if ( not $expected_files_checks->( $deal_idx, $fn ) )
            {
                die "filename check";
            }
            my $dealverdict = shift @$input_lines;
            if ( $is_verdict_line{$dealverdict} )
            {
                push @matches, $dealverdict;
            }
            else
            {
                die "mismatch";
            }
            my $at_most_num_cards__line = 0;
            if (    @$input_lines
                and $input_lines->[0] =~
                /^At most (?:(?:0)|(?:[1-9][0-9]*)) cards could be played\.\z/ms
                )
            {
                $at_most_num_cards__line = 1;
                shift @$input_lines;
            }
            my $traversed_states_count__line = 0;
            if (    @$input_lines
                and $input_lines->[0] =~
/^Total number of states checked is (?:(?:0)|(?:[1-9][0-9]*))\.\z/ms,
                )
            {
                $traversed_states_count__line = 1;
                shift @$input_lines;
            }
            my $generated_states_count__line = 0;
            if (    @$input_lines
                and $input_lines->[0] =~
                /^This scan generated (?:(?:0)|(?:[1-9][0-9]*)) states\.\z/ms )
            {
                $generated_states_count__line = 1;
                shift @$input_lines;
            }
            if (0)
            {
                while ( @$input_lines and $input_lines->[0] !~ /^\[\= /ms )
                {
                    diag( "unrecognised: '" . $input_lines->[0] . "'" );
                    shift @$input_lines;
                }
            }
            my $dealend = shift @$input_lines;
            if ( $dealend ne "[= END of file $fn =]" )
            {
                die "dealend mismatch";
            }
            if ( not $at_most_num_cards__line )
            {
                die "At most cards played line is absent";
            }
            if ( not $traversed_states_count__line )
            {
                die "'checked states' line is absent";
            }
            if ( not $generated_states_count__line )
            {
                die "'This scan generated' line is absent";
            }
        }
        continue
        {
            ++$deal_idx;
        }

        is( scalar(@matches), scalar(@$want), "lines count." );

        eq_or_diff( [@matches], [@$want], "expected results.", );
    };
}

{
    my $sol_fn        = _filename("_test_multiple_verdict_lines.bh.sol.txt");
    my @deals_indexes = ( 11, 12, 13, 25, );

    # TEST
    ok(
        system(
            $^X, "-Mblib", $BHS, "--quiet", "--max-iters", 2000,
            @MAX_NUM_PLAYED_FLAG, "-o", $sol_fn,
            ( map { _filename_maxiters2000($_), } @deals_indexes ),
        )
    );

    # TEST
    _test_multiple_verdict_lines(
        {
            name             => "test multiple verdict lines",
            expected_results => [
                "Exceeded max_iters_limit !", "Solved!",
                "Exceeded max_iters_limit !", "Unsolved!"
            ],
            expected_files_checks => sub {
                my $i       = shift;
                my $dealidx = $deals_indexes[$i];
                my $fn      = path(shift);
                my $bn      = $fn->basename();

                return ( $bn =~ m#bh\Q$dealidx\E\.board#ms );
            },
            input_lines => [ path($sol_fn)->lines_utf8() ],
        }
    );

    unlink($sol_fn);
}
