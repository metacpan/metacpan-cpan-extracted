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

$queue->timeout(1);

enqueue $queue 'test28451289';

my $attempts = 0;
while(++$attempts <= 5) {
	sleep 2;

	my $job = fetch $queue;
	isnt($job, undef, 'Got job from queue');
	is($job->{data}, 'test28451289', 'Got the right job');
	is($job->{attempt}, $attempts, "Attempt is $attempts");

	$job = fetch $queue;
	is($job, undef, 'No job left in queue');
}

sleep 2;
my $job = fetch $queue;
is($job, undef, 'No job left in queue');

done_testing(21);
