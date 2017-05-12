# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FSM-Simple.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN { use_ok('FSM::Simple') };

my $machine = FSM::Simple->new();

# Define states
lives_ok { $machine->add_state(name => 'init',      sub => sub {})      } 'add state init';
lives_ok { $machine->add_state(name => 'make_cake', sub => sub {}) } 'add state make_cake';

# Define transitions
lives_ok { $machine->add_trans(from => 'init', to => 'make_cake', exp_val => 'makeCake') } 'ok - add transition';
dies_ok  { $machine->add_trans(                to => 'make_cake', exp_val => 'makeCake') } "die - empty 'from'";
dies_ok  { $machine->add_trans(from => 'init',                    exp_val => 'makeCake') } "die - empty 'to'";
dies_ok  { $machine->add_trans(from => 'init', to => 'make_cake'                       ) } "die - empty 'exp_val'";

dies_ok  { $machine->add_trans(from => 'non_exists', to => 'make_cake',  exp_val => 'makeCake') } "die - non exist 'from' state";
dies_ok  { $machine->add_trans(from => 'init',       to => 'non_exists', exp_val => 'makeCake') } "die - non exist 'to' state";

dies_ok  { $machine->add_trans(from => 'init', to => 'make_cake', exp_val => []         ) } "die - wrong type of 'exp_val'";


1;