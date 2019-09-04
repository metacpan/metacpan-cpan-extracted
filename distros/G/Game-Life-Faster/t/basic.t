package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok 'Game::Life::Faster'
    or BAIL_OUT $@;

my $ms = eval { Game::Life::Faster->new() };
isa_ok $ms, 'Game::Life::Faster'
    or BAIL_OUT $@;

done_testing;

1;
