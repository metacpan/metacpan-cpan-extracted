# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Genezzo-Contrib-Clustered.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Genezzo::Contrib::Clustered::GLock::GLock') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
use File::Path;
use File::Spec;

my $TEST_COUNT;

$TEST_COUNT = 2;

# verifies locking disabled for CPAN submission

fail ("Genezzo::Contrib::Clustered::GLock::GLock::IMPL not set to NONE")
  unless ($Genezzo::Contrib::Clustered::GLock::GLock::IMPL ==
    $Genezzo::Contrib::Clustered::GLock::GLock::NONE);

ok(1);

