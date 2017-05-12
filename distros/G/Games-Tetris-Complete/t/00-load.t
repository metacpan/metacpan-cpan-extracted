#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Games::Tetris::Complete' ) || print "Bail out!
";
    use_ok( 'Games::Tetris::Complete::Shape' ) || print "Bail out!
";
}

diag(
"Testing Games::Tetris::Complete $Games::Tetris::Complete::VERSION, Perl $], $^X"
);
