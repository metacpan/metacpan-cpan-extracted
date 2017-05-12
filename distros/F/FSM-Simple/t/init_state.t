# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FSM-Simple.t'

use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

BEGIN { use_ok('FSM::Simple') };

my $machine = FSM::Simple->new();

dies_ok { $machine->init_state(undef)                } 'die - not possible to set undef init state';
dies_ok { $machine->init_state('non_existing_state') } 'die - not possible to set non existing init state';


##########################################################################################
### User defined subroutines.
##########################################################################################

1;