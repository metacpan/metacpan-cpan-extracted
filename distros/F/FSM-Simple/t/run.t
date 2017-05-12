# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FSM-Simple.t'

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

BEGIN { use_ok('FSM::Simple') };

my $machine = FSM::Simple->new();
lives_ok { $machine->run } 'run empty machine';
ok 0 == scalar (@{ $machine->trans_history }), 'empty transitions history';
ok 0 == scalar ($machine->trans_array),        'empty transitions array';


##########################################################################################
### User defined subroutines.
##########################################################################################


1;