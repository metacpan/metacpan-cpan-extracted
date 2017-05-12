# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Lingua::Treebank') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# reading in a file and failing when the file doesn't exist

# reading a file and succeeding

# reading from an open filehandle

# closing filehandle

# reading from __DATA__

# data okay

# close filehandle

# data already read in should still be okay

__DATA__
