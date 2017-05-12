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

my $id = enqueue $queue 'test';
my $job = fetch $queue;

isnt($job, undef, 'Got job from queue');

$job = fetch $queue;
is($job, undef, 'No job left in queue');

$job = get $queue $id;
isnt($job, undef, 'Got job from queue by id');

dequeue $queue $id;
$job = get $queue $id;
is($job, undef, 'Job not found in queue by id');

done_testing;
