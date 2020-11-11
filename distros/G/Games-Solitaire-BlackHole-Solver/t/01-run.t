use strict;
use warnings;

use Test::More tests => 12;

use Path::Tiny qw/ path cwd /;
use Dir::Manifest::Slurp qw/ as_lf /;
use Test::Differences qw/ eq_or_diff /;

sub _filename
{
    return cwd()->child( "t", "data", shift() );
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
        as_lf( path($sol_fn)->slurp_utf8 ),
        as_lf($solution1), "Testing for correct solution.",
    );

    unlink($sol_fn);
}

{
    my $sol_fn = _filename("26464608654870335080.bh.sol.txt");

    # TEST
    ok(
        !system( $^X, "-Mblib", $BHS, "-o", $sol_fn,
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
        !system( $^X, "-Mblib", $GOLF_S, "--queens-on-kings",, "-o", $sol_fn,
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

my $MAX_NUM_PLAYED_CARDS_RE =
    qr/\AAt most ([0-9]+) cards could be played\.\n?\z/ms;

my @MAX_NUM_PLAYED_FLAG = ("--show-max-num-played-cards");

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
        !system( $^X, "-Mblib", $BHS, @MAX_NUM_PLAYED_FLAG, "-o", $sol_fn,
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
