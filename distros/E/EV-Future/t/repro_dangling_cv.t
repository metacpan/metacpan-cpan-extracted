use strict;
use warnings;
use Test::More;
use EV::Future;

subtest 'uncaptured done_cv' => sub {
    eval {
        series([
            sub { 
                # Ignore shift -> done_cv is immediately mortalized and freed
                die "Oops"; 
            }
        ], sub {});
    };
    like($@, qr/Oops at/, "survived exception with uncaptured cv in series");

    eval {
        parallel([
            sub {
                die "Oops parallel";
            }
        ], sub {});
    };
    like($@, qr/Oops parallel at/, "survived exception with uncaptured cv in parallel");
};

done_testing;
