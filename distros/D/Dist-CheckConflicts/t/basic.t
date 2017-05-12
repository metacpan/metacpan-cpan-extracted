#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib/basic';

{
    require Foo::Conflicts;
    is_deeply(
        { Foo::Conflicts->conflicts },
        {
            'Foo::Thing'      => '0.01',
            'Foo::Thing::Sub' => '0.05',
        },
        "basic conflicts work"
    );
}

{
    require Bar::Conflicts;
    is_deeply(
        { Bar::Conflicts->conflicts },
        {
            'Bar::Local'      => '0.02',
            'Bar::Also'       => '0.06',
            'Bar::Also::Also' => '0.12',
        },
        "nested conflicts work"
    );
    is_deeply(
        { Bar::Conflicts2->conflicts },
        {
            'Bar::Also'       => '0.06',
            'Bar::Also::Also' => '0.12',
        },
        "nested conflicts work"
    );
    is_deeply(
        { Bar::Conflicts3->conflicts },
        {
            'Bar::Also::Also' => '0.12',
        },
        "nested conflicts work"
    );
}

done_testing;
