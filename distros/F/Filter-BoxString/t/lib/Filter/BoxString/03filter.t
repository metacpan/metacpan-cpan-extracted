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
    my $beatles = eval {

        my $beatles = +
                      | Love Me Do
                      | I wanna hold your hand
                      | Lucy In The Sky With Diamonds
                      | Penny Lane
                      +------------------------------+;
    };

    my $expected_beatles
        = " Love Me Do\n"
        . " I wanna hold your hand\n"
        . " Lucy In The Sky With Diamonds\n"
        . " Penny Lane\n";

    is( $beatles, $expected_beatles, 'trailing whitespace dropped' );
}

