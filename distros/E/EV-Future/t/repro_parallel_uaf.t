use strict;
use warnings;
use Test::More;
use EV::Future;

subtest 'uncaptured cvs in parallel causing UAF' => sub {
    eval {
        parallel([
            sub { 
                # Do not capture $done
            },
            sub {
                # Task 2 throws exception
                die "Oops";
            }
        ], sub {});
    };
    like($@, qr/Oops/, "survived exception with uncaptured previous cv in parallel");
};

done_testing;
