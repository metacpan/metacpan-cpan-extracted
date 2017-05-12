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
    my $noodles = eval {

        my $noodles =
            +-----------------------+
            | Ramen
            | Shirataki
            | Soba
            | Somen
            | Udon
            +;
    };

    my $expected_noodles
        = " Ramen\n"
        . " Shirataki\n"
        . " Soba\n"
        . " Somen\n"
        . " Udon\n";

    is( $noodles, $expected_noodles, 'trailing whitespace dropped' );
}

