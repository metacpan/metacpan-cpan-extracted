use strict;
use warnings;

use Test::More;

use Job::Async::Client::Redis;

my $client = new_ok('Job::Async::Client::Redis');

done_testing;


