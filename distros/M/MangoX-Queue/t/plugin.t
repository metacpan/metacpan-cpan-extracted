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

package MangoX::Queue::Plugin::Test;
use Mojo::Base -base;
use Test::More;
sub register {
	my ($self, $queue) = @_;
	on $queue enqueued => sub { ok(1, 'plugin registered enqueued event') };
	on $queue dequeued => sub { ok(1, 'plugin registered dequeued event') };
	on $queue consumed => sub { ok(1, 'plugin registered consumed event') };
}

package main;

plugin $queue 'MangoX::Queue::Plugin::Test';

my $job = enqueue $queue 'test';
$job = fetch $queue;
dequeue $queue $job;

done_testing(3);
