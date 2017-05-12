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

my $job;

test_event_enqueued();
test_event_dequeued();
test_event_consumed();
test_event_fetched();

sub test_event_enqueued {
	on $queue enqueued => sub {
		my ($queue, $db_job) = @_;
		is($db_job->{data}, '82365', 'enqueued event raised');
	};
	$job = enqueue $queue '82365';

	$queue->unsubscribe('enqueued');
}

sub test_event_dequeued {
	on $queue dequeued => sub {
		my ($queue, $db_job) = @_;
		is($db_job->{data}, '82365', 'dequeued event raised');
	};
	dequeue $queue $job;

	$queue->unsubscribe('dequeued');
}

sub test_event_consumed {
	$job = enqueue $queue '48262';

	on $queue consumed => sub {
		my ($queue, $db_job) = @_;
		is($db_job->{data}, '48262', 'consumed event raised');
	};

	my $consumer_id;
	$consumer_id = consume $queue sub {
		release $queue $consumer_id;
		Mojo::IOLoop->stop;
		return;
	};

	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

	$queue->unsubscribe('consumed');
}

sub test_event_fetched {
	$job = enqueue $queue '28476';

	on $queue consumed => sub {
		my ($queue, $db_job) = @_;
		is($db_job->{data}, '28476', 'consumed event raised on fetch');
	};

	fetch $queue sub {
		Mojo::IOLoop->stop;
		return;
	};

	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

	$queue->unsubscribe('consumed');
}

done_testing(4);
