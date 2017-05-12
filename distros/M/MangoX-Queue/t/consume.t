#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;

use Mango;
use MangoX::Queue;

use Test::More;

my $mango = Mango->new($ENV{MANGO_URI} // 'mongodb://localhost:27017');
my $collection = $mango->db('test')->collection('mangox_queue_test');
eval { $collection->drop };
$collection->create;

my $queue = MangoX::Queue->new(collection => $collection);

test_nonblocking_consume();
test_blocking_consume();
test_custom_consume();
test_job_finished_method();
test_concurrent_job_limit_disabled();
test_concurrent_job_limit_reached();

sub test_nonblocking_consume {
	enqueue $queue '82365';

	my $happened = 0;

	my $consumer_id;
	$consumer_id = consume $queue sub {
		my ($job) = @_;

		$happened++;
		if($happened == 1) {
			is($job->{data}, '82365', 'Found job 82365 in non-blocking consume');
			Mojo::IOLoop->timer(1 => sub {
				enqueue $queue '29345';
			});
		} elsif ($happened == 2) {
			is($job->{data}, '29345', 'Found job 29345 in non-blocking consume');
			release $queue $consumer_id;
			Mojo::IOLoop->stop;
		} else {
			use Data::Dumper; print Dumper $job;
			fail('Queue consumed too many items');
		}
	};

	is($happened, 0, 'Non-blocking consume successful');

	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

sub test_blocking_consume {
	enqueue $queue 'test';

	while(my $item = consume $queue) {
		ok(1, 'Found job in blocking consume');
		last;
	}
}

sub test_custom_consume {
	$collection->remove;

	my $id = enqueue $queue 'custom consume test';

	my $happened = 0;

	my $consumer_id;
	$consumer_id = consume $queue status => 'Failed', sub {
		my ($job) = @_;
		isnt($job, undef, 'Found failed job in non-blocking custom consume');

		release $queue $consumer_id;
		Mojo::IOLoop->stop;
		return;
	};

	is($happened, 0, 'Non-blocking consume successful');

	Mojo::IOLoop->timer(1 => sub {
		my $job = get $queue $id;
		$job->{status} = 'Failed';
		update $queue $job;
	});

	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

sub test_concurrent_job_limit_disabled {
	my $queue_concurrent_job_limit_backup = $queue->concurrent_job_limit;
	my $jobs = [];
	my $consumed_job_count = 0;
	my $concurrent_job_limit_reached_flag;
	my $consumer_id;

	$queue->concurrent_job_limit(-1);
	is($queue->concurrent_job_limit, -1, 'concurrent_job_limit changed to -1');

	# Enqueue 10 dummy jobs
	$queue->enqueue($_) for (1..10);

	# Start consuming jobs
	$consumer_id = consume $queue sub {
		my ($job) = @_;

		$consumed_job_count++;

    # print "IN FIRST CONSUMER\n";

		# Push jobs to array so we can finish() them later
		push(@$jobs, $job);
	};

	# Subscribe to the 'concurrent_job_limit_reached' event so we know when consuming has paused
	my $handler = $queue->on(concurrent_job_limit_reached => sub {
    ok(0, 'concurrent_job_limit_reached should not have been emitted');

		# Finish the jobs previously stored in the array
		while (shift(@$jobs)) {};
	});

	# Start waiting for all jobs to finish
	Mojo::IOLoop->timer(0 => sub { _wait_test_concurrent_job_limit_reached($queue, $consumer_id, \$consumed_job_count, $jobs); });
	Mojo::IOLoop->start;

	ok($consumed_job_count == 10, 'consumed_job_count == 10');

  $queue->unsubscribe(concurrent_job_limit_reached => $handler);
	$queue->concurrent_job_limit($queue_concurrent_job_limit_backup);
}

sub test_job_finished_method {
  # TODO without this, somehow the old consumer gets called (from last test)
  $queue = MangoX::Queue->new(collection => $collection);

	my $queue_concurrent_job_limit_backup = $queue->concurrent_job_limit;
	my $jobs = [];
	my $consumed_job_count = 0;
	my $concurrent_job_limit_reached_flag;
	my $consumer_id;

	is($queue->concurrent_job_limit, 10, 'concurrent_job_limit is the default (10)');
	$queue->concurrent_job_limit(5);
	is($queue->concurrent_job_limit, 5, 'concurrent_job_limit changed to 5');

	# Enqueue 10 dummy jobs
	$queue->enqueue($_) for (1..10);

	# Start consuming jobs
	$consumer_id = consume $queue sub {
		my ($job) = @_;

		$consumed_job_count++;
    #print "CONSUMED JOB COUNT: $consumed_job_count\n";

		# Push jobs to array so we can finish() them later
		push(@$jobs, $job);
	};

	# Subscribe to the 'concurrent_job_limit_reached' event so we know when consuming has paused
	$queue->on(concurrent_job_limit_reached => sub {
		$concurrent_job_limit_reached_flag = 1;

    #print "Event fires\n";

		# Finish the jobs previously stored in the array
		# But keep them in the array so we have a reference, and manually call ->finished
		$_->finished for @$jobs;
	});

	# Start waiting for all jobs to finish
	Mojo::IOLoop->timer(0 => sub { _wait_test_concurrent_job_limit_reached($queue, $consumer_id, \$consumed_job_count, $jobs) });
	Mojo::IOLoop->start;

	ok($consumed_job_count == 10, 'consumed_job_count == 10');
	ok($concurrent_job_limit_reached_flag, 'concurrent_job_limit was reached');

	$queue->concurrent_job_limit($queue_concurrent_job_limit_backup);
}

sub test_concurrent_job_limit_reached {
  # TODO without this, somehow the old consumer gets called (from last test)
  $queue = MangoX::Queue->new(collection => $collection);

	my $queue_concurrent_job_limit_backup = $queue->concurrent_job_limit;
	my $jobs = [];
	my $consumed_job_count = 0;
	my $concurrent_job_limit_reached_flag;
	my $consumer_id;

	is($queue->concurrent_job_limit, 10, 'concurrent_job_limit is the default (10)');
	$queue->concurrent_job_limit(5);
	is($queue->concurrent_job_limit, 5, 'concurrent_job_limit changed to 5');

	# Enqueue 10 dummy jobs
	$queue->enqueue($_) for (1..10);

	# Start consuming jobs
	$consumer_id = consume $queue sub {
		my ($job) = @_;

		$consumed_job_count++;
    #print "CONSUMED JOB COUNT: $consumed_job_count\n";

		# Push jobs to array so we can finish() them later
		push(@$jobs, $job);
	};

	# Subscribe to the 'concurrent_job_limit_reached' event so we know when consuming has paused
	$queue->on(concurrent_job_limit_reached => sub {
		$concurrent_job_limit_reached_flag = 1;

    #print "Event fires\n";

		# Finish the jobs previously stored in the array
		while (shift(@$jobs)) {};
	});

	# Start waiting for all jobs to finish
	Mojo::IOLoop->timer(0 => sub { _wait_test_concurrent_job_limit_reached($queue, $consumer_id, \$consumed_job_count, $jobs) });
	Mojo::IOLoop->start;

	ok($consumed_job_count == 10, 'consumed_job_count == 10');
	ok($concurrent_job_limit_reached_flag, 'concurrent_job_limit was reached');

	$queue->concurrent_job_limit($queue_concurrent_job_limit_backup);
}

sub _wait_test_concurrent_job_limit_reached {
	my ($queue, $consumer_id, $consumed_job_count, $jobs) = @_;

	if ($$consumed_job_count == 10) {
		# Make sure there are no un-finished jobs
		while (shift(@$jobs)) {};

    # print "Finished jobs\n";

		release $queue $consumer_id;
		Mojo::IOLoop->stop;
	} else {
    # print "Waiting: $$consumed_job_count\n";
	  $queue->delay->wait(sub{
			_wait_test_concurrent_job_limit_reached($queue, $consumer_id, $consumed_job_count, $jobs);
		});
	}
}

done_testing;
