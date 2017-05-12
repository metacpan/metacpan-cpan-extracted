# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Device-Neurio.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
use_ok('Device::Neurio');


# The only test performed here is to verity that the module can be imported.
# Any more detailed tests require a connection to the Neurio server as well
# as the key, secret and sensor ID for a particular sensor

#########################
