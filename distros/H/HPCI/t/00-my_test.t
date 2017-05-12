### 00-test.t #############################################################################
# This file is a template for testing

### Includes ######################################################################################

# Safe Perl
use warnings;
use strict;
use Carp;

use Test::More tests => 3;
use Test::Exception;

### Tests #################################################################################

# Verify that the module can be included. (BEGIN just makes this happen early)
BEGIN {use_ok('HPCI')};

dies_ok { HPCI->group( cluster => 'NO_SUCH_CLUSTER_TYPE' ) } 'invalid cluster type should fail';
dies_ok { HPCI->group() } 'missing cluster type should fail';

done_testing();

1;
