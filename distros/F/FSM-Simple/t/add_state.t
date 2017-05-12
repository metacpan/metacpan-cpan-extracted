# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FSM-Simple.t'

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

BEGIN { use_ok('FSM::Simple') };

my $machine = FSM::Simple->new();

lives_ok { $machine->add_state(name => 'init', sub => sub {}) } 'add initial state';
dies_ok  { $machine->add_state(name => 'init'               ) } 'die - sub ref required';
dies_ok  { $machine->add_state(                sub => sub {}) } 'die - state name required';
dies_ok  { $machine->add_state(                             ) } 'die - state name  and sub ref required';
dies_ok  { $machine->add_state(name => 'init', sub => 'str' ) } 'die - wrong sub ref type';
dies_ok  { $machine->add_state(name => [],     sub => sub {}) } 'die - name must be SCALAR';

lives_ok { $machine->add_state(name => 'make_cake', sub => sub {}) } 'add second state';
ok $machine->init_state eq 'init', 'check if init is still as initial state';


1;