use strict;
use warnings;

use Test::More;
use Test::Fatal;

use IO::Async::Loop;
use Job::Async::Test::Compliance;

plan skip_all => 'Set JOB_ASYNC_REDIS_URI' unless $ENV{JOB_ASYNC_REDIS_URI};

my $loop = IO::Async::Loop->new;
$loop->add(
    my $compliance = Job::Async::Test::Compliance->new
);
is(exception {
    ok(my $elapsed = $compliance->test(
        'redis',
        worker => { uri => $ENV{JOB_ASYNC_REDIS_URI} },
        client => { uri => $ENV{JOB_ASYNC_REDIS_URI} },
    )->get, 'nonzero elapsed time');
}, undef, 'Redis client/worker passed compliance test');

done_testing;

