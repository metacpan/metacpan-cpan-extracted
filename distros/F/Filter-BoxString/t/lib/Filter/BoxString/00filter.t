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

    my $list = eval {

        my $list
          = +---------------+
            | 1. Milk       |
            | 2. Eggs       |
            | 3. Apples     |
            +---------------+;
    };

    my $expected_list
        = " 1. Milk       \n"
        . " 2. Eggs       \n"
        . " 3. Apples     \n";

    is( $list, $expected_list, 'trailing whitespace preserved' );
}

