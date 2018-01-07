use strict;
use warnings;

use Test::More;

use Job::Async::Client::Redis;
use Job::Async::Worker::Redis;

my $client = new_ok('Job::Async::Client::Redis');
my $worker = new_ok('Job::Async::Worker::Redis');

done_testing;

