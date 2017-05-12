#!/usr/bin/env perl

use strict;
use warnings;

use Mango;
use MangoX::Queue;

use Test::More;

my $mango = Mango->new($ENV{MANGO_URI} // 'mongodb://localhost:27017');
my $collection = $mango->db('test')->collection('mangox_queue_test');
eval { $collection->drop };
$collection->create;

my $queue = MangoX::Queue->new(collection => $collection);

enqueue $queue 'test';
my $job = fetch $queue;

isnt($job, undef, 'Got job from queue');
is($job->{priority}, 1, 'Priority is right');
is($job->{status}, 'Pending', 'Status is right');
is($job->{data}, 'test', 'Data is right');

enqueue $queue priority => 2, 'test';
$job = fetch $queue;

isnt($job, undef, 'Got job from queue');
is($job->{priority}, 2, 'Priority is right');
is($job->{status}, 'Pending', 'Status is right');
is($job->{data}, 'test', 'Data is right');

enqueue $queue +{
	name => 'job_name',
};
$job = fetch $queue;

isnt($job, undef, 'Got job from queue');
is($job->{priority}, 1, 'Priority is right');
is($job->{status}, 'Pending', 'Status is right');
is(ref($job->{data}), 'HASH', 'Ref is right');
is($job->{data}->{name}, 'job_name', 'Inner data is right');

enqueue $queue priority => 2, 'test';
enqueue $queue priority => 1, 'test';
$job = fetch $queue;

is($job->{priority}, 1, 'Higher priority retrieved first');

$job = fetch $queue;

is($job->{priority}, 2, 'Lower priority retrieved last');

done_testing;
