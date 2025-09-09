#!/usr/bin/env perl

use Test2::V0;
use Game::Entities;

is [ sort keys %Game::Entities:: ], [qw(
    BEGIN
    GUID::
    Set::
    VERSION
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
    sort
    valid
    view
)] => 'No unexpected methods in Game::Entities namespace';

is [ sort keys %Game::Entities::View:: ], [qw|
    ((
    (@{}
    (bool
    BEGIN
    __ANON__
    components
    each
    entities
    first
    new
|] => 'No unexpected methods in Game::Entities::View namespace';

done_testing;
