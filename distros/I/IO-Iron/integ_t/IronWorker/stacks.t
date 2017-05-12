#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use lib 't';
use lib 'integ_t';

require IO::Iron::IronWorker::Client;

use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
diag("Testing IO::Iron::IronWorker::Client, Perl $], $^X");

## Test case
diag('Testing IO::Iron::IronWorker::Client->list_available_stacks()');

subtest 'List available stacks.' => sub {
	# Create an IronWorker client.
	my $iron_worker_client = IO::Iron::IronWorker::Client->new(
		'config' => 'iron_worker.json',
   );
   my @stacks = $iron_worker_client->list_available_stacks();
   ok(scalar @stacks > 0, 'Return a list with at least one item.');

   done_testing();
};

done_testing();

