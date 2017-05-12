use strict;
use warnings;
use Test::More 0.89;
use Test::Fatal;
use Try::Tiny;

use List::Gather;

{
    my $taker;
    try {
        () = gather {
            $taker = sub { take 42 };
            die 'abort';
        };
    };

    like exception { $taker->() },
        qr/^attempting to take after gathering already completed/;
}

{
    my $gathered;
    try {
        () = gather {
            $gathered = sub { \gathered };
            take 42;
            die 'abort';
        };
    };

    is_deeply $gathered->(), [42];

    like exception {
        push @{ $gathered->() }, 23;
    }, qr/Modification of a read-only value attempted/;
}

done_testing;
