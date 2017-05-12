#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib/merge';

{
    require Foo::Conflicts;
    is_deeply(
        { Foo::Conflicts->conflicts },
        {
            'Foo::One'   => '0.03',
            'Foo::Two'   => '0.03',
            'Foo::Three' => '0.02',
            'Foo::Four'  => '0.02',
        },
        "got the right conflicts"
    );
}

done_testing;
