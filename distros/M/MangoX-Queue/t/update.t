#!/usr/bin/env perl

use strict;
use warnings;

use Mango;
use Mojo::IOLoop;
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
is($job->{priority}, 1, 'Priority is right');
is($job->{status}, 'Pending', 'Status is right');
is($job->{data}, 'test', 'Data is right');

$job->{data} = 'update test';

update $queue $job => sub {
    Mojo::IOLoop->stop;
    my $j = get $queue $id;
    is $j->{data}, 'update test', 'job was updated in non-blocking mode';
};
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

done_testing;
