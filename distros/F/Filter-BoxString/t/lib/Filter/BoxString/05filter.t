# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Filter-BoxString.t'

#########################

use Test::More tests => 2;

BEGIN {

    use_ok('Filter::BoxString');
}

TEST:
{
    my $metachars = eval {

            my $metachars = +------------------------------------------------------------+
                            | \\  Quote the next metacharacter
                            | ^  Match the beginning of the line
                            | .  Match any character (except newline)
                            | \$  Match the end of the line (or before newline at the end)
                            | |  Alternation
                            | () Grouping
                            | [] Character class
                            +------------------------------------------------------------+;
    };

    my $expected_metachars
        = " \\  Quote the next metacharacter\n"
        . " ^  Match the beginning of the line\n"
        . " .  Match any character (except newline)\n"
        . " \$  Match the end of the line (or before newline at the end)\n"
        . " |  Alternation\n"
        . " () Grouping\n"
        . " [] Character class\n";

    is( $metacharacters, $expected_metacharacters, 'meta character content' );
}

