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

# Note - no easy/sensible way to test blocking watch
# But we'll check it at least returns
my $job = enqueue $queue status => 'Complete', 'test';
watch $queue $job, 'Complete';
ok(1, 'Blocking watch returned');

# Single watch watching a single status

$job = enqueue $queue 'test';

watch $queue $job, 'Complete' => sub {
	ok(1, 'Job status is complete');
	Mojo::IOLoop->stop;
};

Mojo::IOLoop->timer(1 => sub {
	$job->{status} = 'Complete';
	update $queue $job;
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# Single watch watching multiple statuses

$job = enqueue $queue 'test';
watch $queue $job, ['Complete','Failed'] => sub {
	ok(1, 'Job status is complete or failed');
	$job->{status} = 'Pending';
	update $queue $job;
	watch $queue $job, ['Complete','Failed'] => sub {
		ok(1, 'Job status is complete or failed');
		Mojo::IOLoop->stop;
	};
	Mojo::IOLoop->timer(1 => sub {
		$job->{status} = 'Failed';
		update $queue $job;
	});
};

Mojo::IOLoop->timer(1 => sub {
	$job->{status} = 'Complete';
	update $queue $job;
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# Separate complete/failed watchs

$job = enqueue $queue 'test';

watch $queue $job, 'Complete' => sub {
	ok(1, 'Job status is complete');
	Mojo::IOLoop->timer(1 => sub {
		$job->{status} = 'Failed';
		update $queue $job;
	});
};
watch $queue $job, 'Failed' => sub {
	ok(1, 'Job status is failed');
	Mojo::IOLoop->stop;
};

Mojo::IOLoop->timer(1 => sub {
	$job->{status} = 'Complete';
	update $queue $job;
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;


done_testing;
