package main;

use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::BailOnFail;
use Test2::Tools::LoadModule;

load_module_ok 'Game::Life::Faster';

my $ms = eval { Game::Life::Faster->new() };
isa_ok $ms, 'Game::Life::Faster';

done_testing;

1;
