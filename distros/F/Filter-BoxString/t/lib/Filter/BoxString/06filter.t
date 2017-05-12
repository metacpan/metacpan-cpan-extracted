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
    my $gibberish = eval {

        my $gibberish = +-----------------------------------+
                        | +!@#%^&*()_|"?><{}>~=-\'/.,[]
                        | +=!@#%^&*()_-|\"':;?/>.<,}]{[><~`
                        +-----------------------------------+;
    };

    my $expected_gibberish
        = " +!@#%^&*()_|\"?><{}>~=-\'/.,[]\n"
        . " +=!@#%^&*()_-|\"':;?/>.<,}]{[><~`\n";

    is( $gibberish, $expected_gibberish, 'gibberish content' );
}

