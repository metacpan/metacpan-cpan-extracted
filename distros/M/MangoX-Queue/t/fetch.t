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

test_nonblocking_fetch();
test_blocking_fetch();

sub test_nonblocking_fetch {
	enqueue $queue 'test';

	my $happened = 0;
	fetch $queue sub {
		my ($job) = @_;

		$happened = 1;
		ok(1, 'Found job in non-blocking fetch');
		Mojo::IOLoop->stop;
	};

	is($happened, 0, 'Non-blocking fetch successful');

	Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}

sub test_blocking_fetch {
	enqueue $queue 'test';

	my $item = fetch $queue;
	isnt($item, undef, 'Found job in blocking fetch');
}

done_testing;
