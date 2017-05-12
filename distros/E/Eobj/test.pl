# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Eobj;
ok(1); # If we made it this far, we're ok.

#########################

inherit('testclass','testclass.pl','root');

init;

$object = testclass->new(name => 'TestObject');
$object->tryout("\nIt looks like everything is working fine!\n");
