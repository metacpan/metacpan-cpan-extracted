use strict;
use warnings;
use Test::More 0.98;
use Test::Fatal;

BEGIN { use_ok 'List::Gather' };

is_deeply
    [gather { take $_ for 1..10; take 99 }],
    [1..10, 99],
    'basic gather works';

is_deeply
    [gather { take 1..10; take 99 }],
    [1..10, 99],
    'taking multiple items works';

is_deeply
    [gather { take $_ for 1..10; take 99 unless gathered }],
    [1..10],
    'gathered works in boolean context (true)';

is_deeply
    [gather { take 99 unless gathered }],
    [99],
    'gathered works in boolean context (false)';

is_deeply
    [gather { take $_ for 1..10; pop gathered }],
    [1..9],
    'gathered allows modification of underlying data';

is_deeply
    [gather {
        for my $x (qw(a b)) {
            sub { take @_ }->($x);
        }
    }],
    [qw(a b)];

is_deeply
    [gather {
        for my $x (qw(a b)) {
            package Moo;
            sub { ::take @_ }->($x);
        }
    }],
    [qw(a b)];

is exception {
    for my $x (qw(a b c)) {
        () = gather { take $x };
    }
}, undef;

() = gather {
    {
        is take(42), 42;
        my @n = take 42;
        is @n, 1;
    }

    {
        is take(23, 24, 25), 25;
        my @n = take 23, 24, 25;
        is @n, 3;
    }
};

is((scalar gather({
    take $_ for 0 .. 9;
    my $v = 42;
})), 10);

() = gather {
    is scalar(gathered), 0;
    my @g = gathered;
    is @g, 0;

    take 23, 42, 13;
    is scalar(gathered), 3;
    @g = gathered;
    is @g, 3;
};

{
    my $gathered;
    () = gather {
        $gathered = sub { gathered };
        take 3, 2, 1;
    };

    is exception {
        is_deeply [$gathered->()], [3, 2, 1];
    }, undef;
}

done_testing;
