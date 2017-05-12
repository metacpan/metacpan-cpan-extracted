# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Log-Dispatch-Spread.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('Log::Dispatch::Spread') };

#########################

ok($logger = Log::Dispatch::Spread->new( name => 'spread', min_level => 'debug', server => '4803@localhost', channels => [ qw(one two) ] ), 'object create');
ok(defined($logger), 'object exists');
