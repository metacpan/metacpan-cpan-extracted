# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math::Permute::Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Math::Permute::Array') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @array = (1..8);
my $err = Math::Permute::Array::Apply_on_perms { } \@array;
exit(-1) unless($err == 0);

