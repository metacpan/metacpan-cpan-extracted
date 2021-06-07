#!/usr/bin/env perl

use Test::More;
use Game::Entities;

is_deeply [ sort keys %Game::Entities:: ], [qw(
    BEGIN
    View::
    __ANON__
    _dump_entities
    a
    add
    alive
    b
    check
    clear
    create
    created
    delete
    get
    import
    new
    valid
    view
)] => 'No unexpected methods in Game::Entities namespace';

is_deeply [ sort keys %Game::Entities::View:: ], [qw|
    ((
    (@{}
    (bool
    BEGIN
    __ANON__
    components
    each
    entities
    new
|] => 'No unexpected methods in Game::Entities::View namespace';

done_testing;
