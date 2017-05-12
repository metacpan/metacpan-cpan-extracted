use strict;
use warnings;
use Test::More 0.88;

use_ok 'Devel::InterpreterSize';

my $i = Devel::InterpreterSize->new;
ok $i;
my ($total, $shared, $unshared) = $i->check_size;
ok $total;
#Not on OSX!
#ok $shared;
ok $unshared;

is $total, ($shared+$unshared);

done_testing;

