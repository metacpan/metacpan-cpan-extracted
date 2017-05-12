#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use lib 't/lib/also';

{
    require Bar::Conflicts;
    is_deeply(
        { Bar::Conflicts->conflicts },
        {
            'Bar::Local'      => '0.02',
            'Foo::Thing'      => '0.01',
            'Foo::Thing::Sub' => '0.05',
        },
        "can detect the proper conflicts module"
    );
}

{
    require Bar::Conflicts2;
    is_deeply(
        { Bar::Conflicts2->conflicts },
        {
            'Bar::Also' => '0.06',
        },
        "unknown also entries are ignored"
    );
}

done_testing;
