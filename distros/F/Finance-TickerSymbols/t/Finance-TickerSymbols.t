# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-TickerSymbols.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Finance::TickerSymbols') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

for my $market (qw/ nasdaq
                    amex
                    nyse
                  /) {
    # don't forget to increase last test while adding more markets .. # 

    # make sure we have at list 101 symbols in the array
    ok( ( symbols_list( $market ) )[100] ) ;
}
